# Clash Verge Rev 适配与同步工具

Windows 下使用系统 PowerShell 即可，不安装额外运行时或依赖。适配基于 Clash Verge Rev 2.5.8 自带的 Mihomo 1.19.32；此前已通过隔离内核验证地区筛选与规则加载，本次移除空的额外代理组后保留 6 个 GEOSITE 与 7 个 RULE-SET。仍需在 Verge 中保存扩展后确认实际业务请求命中。

## 安装与更新

1. 在 Verge 中导入并选中机场订阅，关闭正在编辑扩展脚本的窗口。
2. [下载整个仓库 ZIP](https://github.com/zhazhayu01/stash-rules/archive/refs/heads/main.zip)，解压后打开 `verge` 文件夹。
3. 双击 `更新覆写.cmd`。首次接管默认空白的全局扩展，以后运行同一个工具即可从 GitHub 更新。
4. 在 Verge 打开「全局扩展脚本」，确认开头有 `stash-rules-verge` 标记，保存一次以重新应用配置。
5. 在 `RS-美国`、`RS-新加坡` 分别选节点，再为各服务选择地区。DeepSeek 默认直连。

脚本新增 8 个策略组、7 份远程补充列表和 6 个 GEOSITE 分类，与 Stash 使用同一套规则顺序和 Oasisic 图标。地区组按节点名筛选美国、新加坡；筛选为空时使用 `REJECT`，请检查节点命名。

同步工具更新的是**全局扩展脚本文件**，作用于所有订阅。Verge 没有提供本工具可调用的公开重新执行扩展接口，因此“同步成功”表示文件已就位，仍需完成第 4 步；工具不重启应用或更改系统代理。

## 命令行用法

在解压后的 `verge` 文件夹打开 PowerShell：

```powershell
# 只下载并检查，不修改文件
.\Sync-Verge.ps1 -CheckOnly

# 同步最新版本
.\Sync-Verge.ps1

# 恢复上一次同步前的脚本；随后在 Verge 保存全局扩展脚本以重新应用
.\Sync-Verge.ps1 -Restore

# 自定义 Verge 配置目录，例如开发版或另一个用户目录
.\Sync-Verge.ps1 -VergeHome 'D:\VergeData'

# 无网络时，使用本文件夹内的适配脚本与清单
.\Sync-Verge.ps1 -SourceDirectory .
```

默认写入 `%APPDATA%\io.github.clash-verge-rev.clash-verge-rev\profiles\Script.js`，更新前的文件保存在同目录的 `Script.js.stash-rules.bak`。恢复操作也会保存恢复前的文件到 `Script.js.before-restore.bak`。

如果全局扩展已有自己的代码，工具会停止，保留原文件。可先备份，再手动合并；也可在空白的单订阅扩展脚本里粘贴 `clash-verge.js`，只对一个订阅生效。请勿将 JS 地址作为机场订阅导入。

## 更新与维护范围

- 同步器先查询 GitHub 的 `main` 提交，再固定到该提交下载 `manifest.json` 和脚本，避免两个文件因缓存出现版本差异。
- 写入前检查清单结构、UTF-8、脚本标记和 SHA256；下载失败、校验不通过或替换失败时保留原文件。
- `rules/*.yaml` 继续由 Mihomo 每 24 小时检查更新。只补充域名时不需要重新同步脚本。
- 修改策略组、图标或 GEOSITE 分类时，更新 `clash-verge.js`，同时更新清单中的版本和 SHA256，再运行同步器。
- GEOSITE 使用当前 Mihomo 的数据文件与数据源；首次应用时需要已有数据或能正常下载。不同客户端的数据源与更新时间可能不同。
- `RS-` 策略组名称和本脚本列出的 `rs-` 规则集名称供本项目使用。原订阅中的其他节点、策略组、规则与配置项保留；重复应用不会重复添加本项目条目。
- 同步器负责文件同步和回滚，不在 PowerShell 中执行下载的 JS。脚本由 Verge 在应用订阅时执行。
- 工具不会修改系统执行策略；如果设备策略阻止 PowerShell 脚本运行，请使用设备允许的运行方式。

## 开发验证

Node 仅用于作者运行测试，使用者无需安装：

```powershell
node tests/check-verge.cjs
powershell.exe -NoProfile -File tests/check-sync.ps1
```

同步测试仅使用临时假目录，不读取真实订阅。适配测试验证保留原配置、重复应用、地区与图标、远程规则声明及与 Stash 的规则一致性；同步测试验证只检查、更新、备份恢复、损坏下载和自定义脚本保护。

官方参考：[Verge 扩展脚本](https://www.clashverge.dev/guide/script.html)、[Mihomo 规则集](https://wiki.metacubex.one/config/rule-providers/)、[Mihomo 策略组](https://wiki.metacubex.one/config/proxy-groups/)。
