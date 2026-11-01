#requires -Version 5.1
<#
同步 GitHub 中的适配脚本到 Verge 全局扩展。默认只接管空模板或本工具管理的脚本。
SourceDirectory 用于离线安装与测试；CheckOnly 只检查；Restore 恢复上一次备份。
#>
[CmdletBinding()]
param(
    [string]$VergeHome = (Join-Path $env:APPDATA 'io.github.clash-verge-rev.clash-verge-rev'),
    [string]$SourceDirectory,
    [switch]$CheckOnly,
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'
$marker = '// stash-rules-verge schema: 1'
$target = Join-Path ([IO.Path]::GetFullPath($VergeHome)) 'profiles\Script.js'
$backup = $target + '.stash-rules.bak'
$temporary = $null
$syncMutex = [Threading.Mutex]::new($false, 'Local\StashRulesVergeSync')
$ownsMutex = $false
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

function Get-ScriptHash([byte[]]$Bytes) {
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($hasher.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $hasher.Dispose() }
}

try {
    try { $ownsMutex = $syncMutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (!$ownsMutex) { throw '另一个同步任务正在运行，请稍后重试。' }
    $indexPath = Join-Path $VergeHome 'profiles.yaml'
    if (!(Test-Path -LiteralPath $indexPath) -or !(Test-Path -LiteralPath $target)) {
        throw '未找到 Verge 全局扩展。请先启动 Verge 并导入订阅，或使用 -VergeHome 指定配置目录。'
    }
    if ([IO.File]::ReadAllText($indexPath) -notmatch '(?m)^\s*file:\s*[''"]?Script\.js[''"]?\s*$') {
        throw '此版本的全局扩展位置与预期不同，已停止；请在 Verge 中打开配置目录核对。'
    }

    $currentBytes = [IO.File]::ReadAllBytes($target)
    $currentText = $utf8.GetString($currentBytes).TrimStart([char]0xFEFF)
    if ($Restore) {
        if ($CheckOnly -or $SourceDirectory) { throw 'Restore 不能与 CheckOnly 或 SourceDirectory 同时使用。' }
        if (!(Test-Path -LiteralPath $backup)) { throw '没有可恢复的备份。' }
        if (!$currentText.StartsWith($marker)) { throw '当前文件不是本工具管理的脚本，已停止恢复。' }
        $newBytes = [IO.File]::ReadAllBytes($backup)
        $backupPath = $target + '.before-restore.bak'
    }
    else {
        $bareScript = [regex]::Replace($currentText, '(?m)^\s*//.*$', '').Trim()
        $isDefault = $bareScript -match '^function\s+main\s*\(\s*config\s*(?:,\s*profileName\s*)?\)\s*\{\s*return\s+config\s*;?\s*\}$'
        if (!$isDefault -and !$currentText.StartsWith($marker)) {
            throw '全局扩展已有自定义代码，工具不会覆盖。请先在 Verge 中备份并合并，或改用单订阅扩展手动安装。'
        }
        if ($SourceDirectory) {
            $manifest = [IO.File]::ReadAllText((Join-Path $SourceDirectory 'manifest.json')) | ConvertFrom-Json
            $newBytes = [IO.File]::ReadAllBytes((Join-Path $SourceDirectory 'clash-verge.js'))
        }
        else {
            # 固定到同一个提交下载清单与脚本，避免分支缓存导致两者版本不一致。
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            $headers = @{ 'User-Agent' = 'stash-rules-verge-sync'; 'Accept' = 'application/vnd.github+json' }
            $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/zhazhayu01/stash-rules/commits/main' -Headers $headers -TimeoutSec 30
            $commit = [string]$release.sha
            if ($commit -notmatch '^[0-9a-f]{40}$') { throw 'GitHub 返回了无效的提交编号。' }
            $baseUrl = 'https://raw.githubusercontent.com/zhazhayu01/stash-rules/' + $commit + '/verge/'
            $manifest = Invoke-RestMethod -Uri ($baseUrl + 'manifest.json') -TimeoutSec 30
            $response = Invoke-WebRequest -Uri ($baseUrl + 'clash-verge.js') -UseBasicParsing -TimeoutSec 30
            $newBytes = $response.RawContentStream.ToArray()
        }
        if ($manifest.schemaVersion -ne 1 -or $manifest.script -ne 'clash-verge.js' -or [string]$manifest.sha256 -notmatch '^[0-9a-f]{64}$') {
            throw '更新清单格式不正确，保留原脚本。'
        }
        if ($newBytes.Length -eq 0 -or $newBytes.Length -gt 262144 -or (Get-ScriptHash $newBytes) -cne $manifest.sha256) {
            throw '下载内容为空、过大或 SHA256 不匹配，保留原脚本。'
        }
        $newText = $utf8.GetString($newBytes)
        if (!$newText.StartsWith($marker) -or $newText -notmatch 'function\s+main\s*\(') {
            throw '下载内容不是预期的适配脚本，保留原脚本。'
        }
        if ($CheckOnly) {
            Write-Host '检查通过，未修改文件。'
            [pscustomobject]@{ Status = 'Checked'; Target = $target; Version = $manifest.version }
            return
        }
        if ((Get-ScriptHash $currentBytes) -ceq (Get-ScriptHash $newBytes)) {
            Write-Host '本地已是最新版本。需要生效时，请在 Verge 中重新启用当前订阅。'
            [pscustomobject]@{ Status = 'Unchanged'; Target = $target; Version = $manifest.version }
            return
        }
        $backupPath = $backup
    }

    # 同目录临时文件加原子替换；下载、校验或替换失败时，原文件仍保留。
    $temporary = Join-Path ([IO.Path]::GetDirectoryName($target)) ('.stash-rules-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllBytes($temporary, $newBytes)
    [IO.File]::Replace($temporary, $target, $backupPath, $true)
    $temporary = $null
    Write-Host '文件已更新。请在 Verge 的订阅页重新启用当前订阅，再选择美国、新加坡节点。'
    Write-Host ('备份位置：' + $backupPath)
    [pscustomobject]@{ Status = $(if ($Restore) { 'Restored' } else { 'Updated' }); Target = $target; Backup = $backupPath }
}
finally {
    if ($temporary -and (Test-Path -LiteralPath $temporary)) { Remove-Item -LiteralPath $temporary -Force }
    if ($ownsMutex) { $syncMutex.ReleaseMutex() }
    $syncMutex.Dispose()
}
