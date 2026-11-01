#requires -Version 5.1
# 使用临时的假 Verge 目录，验证更新、备份、恢复和失败保留；不会读取真实订阅。
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$tool = Join-Path $repo 'verge\Sync-Verge.ps1'
$source = Join-Path $repo 'verge'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testRoot = Join-Path $tempBase ('stash-rules-test-' + [Guid]::NewGuid().ToString('N'))
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Assert-True([bool]$Condition, [string]$Message) {
    if (!$Condition) { throw $Message }
}
function Assert-Fails([scriptblock]$Action, [string]$Message) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true }
    Assert-True $failed $Message
}

try {
    $fixtureHome = Join-Path $testRoot 'verge'
    $profiles = Join-Path $fixtureHome 'profiles'
    [IO.Directory]::CreateDirectory($profiles) | Out-Null
    [IO.File]::WriteAllText((Join-Path $fixtureHome 'profiles.yaml'), "items:`n- uid: Script`n  type: script`n  file: Script.js`n", $utf8)
    $target = Join-Path $profiles 'Script.js'
    $original = "// 默认空模板`nfunction main(config, profileName) { return config; }`n"
    [IO.File]::WriteAllText($target, $original, $utf8)
    $checked = & $tool -VergeHome $fixtureHome -SourceDirectory $source -CheckOnly
    Assert-True ($checked.Status -eq 'Checked') '只检查模式失败'
    Assert-True ([IO.File]::ReadAllText($target) -ceq $original) '只检查模式意外写入'
    $updated = & $tool -VergeHome $fixtureHome -SourceDirectory $source
    Assert-True ($updated.Status -eq 'Updated') '首次安装失败'
    Assert-True ([IO.File]::ReadAllText($updated.Backup) -ceq $original) '旧文件备份不正确'
    $expected = [IO.File]::ReadAllText($target)
    $again = & $tool -VergeHome $fixtureHome -SourceDirectory $source
    Assert-True ($again.Status -eq 'Unchanged') '重复同步不应再次替换'
    Assert-True ([IO.File]::ReadAllText($updated.Backup) -ceq $original) '重复同步破坏备份'

    $bad = Join-Path $testRoot 'bad-source'
    [IO.Directory]::CreateDirectory($bad) | Out-Null
    [IO.File]::Copy((Join-Path $source 'manifest.json'), (Join-Path $bad 'manifest.json'))
    [IO.File]::WriteAllText((Join-Path $bad 'clash-verge.js'), '<html>下载错误页</html>', $utf8)
    Assert-Fails { & $tool -VergeHome $fixtureHome -SourceDirectory $bad } '损坏下载应被拒绝'
    Assert-True ([IO.File]::ReadAllText($target) -ceq $expected) '校验失败时修改了文件'
    Assert-Fails { & $tool -VergeHome $fixtureHome -SourceDirectory (Join-Path $testRoot 'missing') } '缺失来源应失败'
    Assert-True ([IO.File]::ReadAllText($target) -ceq $expected) '读取失败时修改了文件'

    $custom = 'function main(config) { config.custom = true; return config; }'
    [IO.File]::WriteAllText($target, $custom, $utf8)
    Assert-Fails { & $tool -VergeHome $fixtureHome -SourceDirectory $source } '应保护用户自定义脚本'
    Assert-True ([IO.File]::ReadAllText($target) -ceq $custom) '覆盖了用户自定义脚本'
    [IO.File]::WriteAllText($target, $expected, $utf8)
    $restored = & $tool -VergeHome $fixtureHome -Restore
    Assert-True ($restored.Status -eq 'Restored') '恢复操作失败'
    Assert-True ([IO.File]::ReadAllText($target) -ceq $original) '恢复内容不正确'

    # 已有备份时仍应可以更新，并可再次恢复。
    $reinstalled = & $tool -VergeHome $fixtureHome -SourceDirectory $source
    Assert-True ($reinstalled.Status -eq 'Updated') '已有备份时更新失败'
    & $tool -VergeHome $fixtureHome -Restore | Out-Null
    Assert-True ([IO.File]::ReadAllText($target) -ceq $original) '已有备份时恢复失败'

    # 锁定目标，确认原子替换失败时不会破坏旧文件，临时文件也会清理。
    $lock = [IO.File]::Open($target, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try { Assert-Fails { & $tool -VergeHome $fixtureHome -SourceDirectory $source } '目标被占用时应安全失败' }
    finally { $lock.Dispose() }
    Assert-True ([IO.File]::ReadAllText($target) -ceq $original) '替换失败破坏旧文件'
    Assert-True (@(Get-ChildItem -LiteralPath $profiles -Filter '*.tmp').Count -eq 0) '临时文件未清理'
    Write-Host 'PASS：只检查、首次同步、重复同步、SHA256 拒绝、读取失败、自定义保护、备份恢复、替换失败保留'
}
finally {
    $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
    if (!$resolvedTestRoot.StartsWith($tempBase.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw '临时目录越界，停止清理。'
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) { Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force }
}
