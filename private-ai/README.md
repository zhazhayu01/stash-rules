# 私人 AI 线路补充

在原有机场订阅和主覆写之外，额外接入自建线路。OpenAI / ChatGPT / Codex、Claude、Gemini、Grok 统一走 `RS-AI出口`，默认选择 `RS-AI自用节点`；可手动切换美国或新加坡。DeepSeek 继续默认直连，X 沿用原策略。出口组为手动选择，不会自动换 IP。

此处公开文件仅为模板，不能直接使用。复制到本地后，将 `PRIVATE_SUBSCRIPTION_URL` 换成自己的 Clash YAML 订阅地址。私人文件可放在本仓库已忽略的 `.private/` 目录，真实地址不要提交到公开仓库。

## Stash

1. 保持原有机场订阅与本仓库的远程主覆写启用。
2. 把填写好的私人 `stash.stoverride` 通过文件导入 Stash「覆写」。
3. 将私人覆写排在主覆写下方并启用。Stash 从上到下合并，私人覆写的规则会插到此前规则前面。
4. 在 `RS-AI出口` 选择 `RS-AI自用节点`，在 `RS-AI自用节点` 中选自己的节点。

本补充只追加两个独立策略组及优先规则，不替换机场原有策略组。不要把它当成节点订阅导入。主覆写仍可远程更新，服务补充继续复用主覆写的规则集。Stash 原生规则集和订阅更新间隔相互独立。

## Clash Verge Rev

1. 保持本仓库的全局适配脚本安装并启用。
2. 在当前机场订阅的菜单打开「编辑扩展脚本」，备份原有内容后，填入已填写订阅地址的私人 `clash-verge.js` 并保存。
3. 重新启用当前订阅，在 `RS-AI出口` 选择 `RS-AI自用节点`。

私人脚本属于当前订阅，晚于全局扩展执行；全局同步工具只更新 `Script.js`，不会覆盖此私人脚本。切换到其他订阅时，要在对应订阅里另行配置。已有自定义订阅脚本时应先合并，不直接覆盖。

## 验证

海外 AI 的基础请求应命中对应 `GEOSITE`，最终经过 `RS-AI出口 → RS-AI自用节点 → 自建节点`；服务补充应命中对应 `RULE-SET`。自定义直连例外继续优先，第三方验证码、支付等请求仍按原配置处理。

节点名称不能证明实际出口位置或 IP 质量。实际登录、对话、上传仍需在设备上确认。Stash 的空代理集可能回退直连，使用前先确认自建节点已加载；Verge 私人节点组为空时明确拒绝。

参考：[Stash 远程代理集](https://stash.wiki/proxy-protocols/proxy-providers)、[Stash 覆写顺序](https://stash.wiki/configuration/override)、[Verge 扩展执行顺序](https://www.clashverge.dev/guide/extend.html)。
