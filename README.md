# Stash 远程规则集

自用、可独立维护的 Stash 分流补充规则，覆盖 OpenAI / ChatGPT / Codex、Claude、Gemini、Grok、DeepSeek 和 X（Twitter）。基础分类使用社区维护的 `GEOSITE`，本仓库只维护补充和例外。配合已有的机场订阅使用，不包含节点、订阅地址或密钥。

## 导入 Stash

1. 保留并启用已有的节点订阅配置，使用规则模式。
2. 在 Stash 的「覆写」中添加下方远程地址，并启用。也可点击[一键安装覆写](https://link.stash.ws/install-override/raw.githubusercontent.com/zhazhayu01/stash-rules/main/stash.stoverride)。
3. 在策略组中分别为 `RS-OpenAI`、`RS-Claude`、`RS-Gemini`、`RS-Grok`、`RS-X`、`RS-额外代理` 选择节点。`RS-DeepSeek` 默认选择 `DIRECT`，也可切换为代理。各组会引用原配置中的全部节点和远程代理集，不依赖机场的策略组名称。
4. 打开相应服务，在 Stash「最近请求」中检查命中的规则和实际出口。

```text
https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/stash.stoverride
```

覆写依赖原配置提供节点；原配置没有节点时，请先添加订阅。本文件不是独立的完整代理配置。

`GEOSITE` 数据不随 Stash 分发，首次使用会从 GitHub 按需加载，请确保原配置能正常访问 GitHub。`GEOSITE` 数据的加载由 Stash 管理，与下面自定义规则集的 24 小时更新间隔无关。

## 社区基础分类

| 服务 | 分类 | 出口策略组 | 社区域名列表 |
| --- | --- | --- | --- |
| OpenAI / ChatGPT / Codex | `GEOSITE,openai` | `RS-OpenAI` | [openai](https://github.com/v2fly/domain-list-community/blob/master/data/openai) |
| Claude / Claude Code | `GEOSITE,anthropic` | `RS-Claude` | [anthropic](https://github.com/v2fly/domain-list-community/blob/master/data/anthropic) |
| Gemini / Google AI | `GEOSITE,google-deepmind` | `RS-Gemini` | [google-deepmind](https://github.com/v2fly/domain-list-community/blob/master/data/google-deepmind) |
| Grok | `GEOSITE,xai` | `RS-Grok` | [xai](https://github.com/v2fly/domain-list-community/blob/master/data/xai) |
| DeepSeek | `GEOSITE,deepseek` | `RS-DeepSeek`，默认直连 | [deepseek](https://github.com/v2fly/domain-list-community/blob/master/data/deepseek) |
| X / Twitter | `GEOSITE,twitter` | `RS-X` | [twitter](https://github.com/v2fly/domain-list-community/blob/master/data/twitter) |

分类由 v2fly 社区维护，不需要在本仓库重复列出全部域名。分类名称按上表填写，例如 Claude 对应的是 `anthropic`。

Gemini 使用当前的 `google-deepmind` 分类；旧的 `google-gemini` 分类已作为兼容入口引用它。该分类也覆盖 AI Studio、NotebookLM、Jules 等 Google AI 服务。Grok 的 `xai` 分类先于 `twitter` 匹配，确保 `grok.x.com` 走 Grok 的独立出口。

## 自定义补充文件

| 文件 | 用途 | 远程地址 |
| --- | --- | --- |
| [openai.yaml](rules/openai.yaml) | OpenAI 服务补充，目前为 `cdn.openaimerge.com` | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/openai.yaml) |
| [claude.yaml](rules/claude.yaml) | Claude 服务补充，当前为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/claude.yaml) |
| [x.yaml](rules/x.yaml) | X 服务补充，当前为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/x.yaml) |
| [gemini.yaml](rules/gemini.yaml) | Gemini 服务补充，当前为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/gemini.yaml) |
| [grok.yaml](rules/grok.yaml) | Grok 服务补充，当前为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/grok.yaml) |
| [deepseek.yaml](rules/deepseek.yaml) | DeepSeek 服务补充，当前为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/deepseek.yaml) |
| [extra-proxy.yaml](rules/extra-proxy.yaml) | 自定义代理规则，初始为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/extra-proxy.yaml) |
| [extra-direct.yaml](rules/extra-direct.yaml) | 自定义直连规则，初始为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/extra-direct.yaml) |

补充文件使用 `classical` + YAML 格式。它们只包含补充规则，需配合 `stash.stoverride` 中的 `GEOSITE` 使用，单独引用不包含该服务的完整分类。

## 日常维护

直接在 GitHub 打开对应文件，点击编辑并提交到 `main`；本地修改也可正常提交推送。已导入的规则集每 24 小时检查更新，急用时在 Stash 手动更新规则集。修改 `stash.stoverride` 后需要更新远程覆写并重新加载配置。

服务漏分流时，将确认过的域名加到对应服务补充文件，继续使用该服务的出口。其他需要代理的目标加到 `extra-proxy.yaml`；需要强制直连的目标加到 `extra-direct.yaml`。如果社区后来已覆盖该域名，可以删掉重复补充。

自定义规则示例（将空文件中的 `payload: []` 改为以下形式，替换示例域名）：

```yaml
payload:
  - DOMAIN,api.example.com
  - DOMAIN-SUFFIX,example.org
  - IP-CIDR,192.0.2.0/24,no-resolve
```

- `DOMAIN` 只匹配该域名；`DOMAIN-SUFFIX` 匹配域名本身及其子域名。规则内不要写 `https://`、路径或策略组名称。
- 匹配顺序：额外直连 → 额外代理 → 各服务补充 → GEOSITE 基础分类 → 原配置规则。自定义规则可以覆盖社区分类；同一域名同时加入两个额外规则集时，直连优先。
- 覆写将规则插入原配置前面。若存在其他覆写，请检查合并后的顺序，确保这些规则在兜底 `MATCH` 之前。
- 社区分类和本仓库都未覆盖的验证码、支付、登录组件及第三方工具请求由原配置继续处理。遇到遗漏，请从「最近请求」确认域名后按需补充，避免把整个公共 CDN 分给某个服务。
- 规则决定流量出口，节点本身仍需满足相应服务的地区与网络要求。建议为同一服务保持稳定出口。
- 仓库公开，请勿提交订阅链接、节点密码、Token 或含有凭据的日志。

## 验证与资料

从旧版迁移时，在 Stash 更新远程覆写、重新加载配置，再更新自定义规则集，确保新增的 `GEOSITE` 规则已经生效。

修改后检查 YAML 语法、规则集名称与策略组引用，再更新 Stash，实测网页登录、对话、附件及 X 媒体加载，并查看实际命中结果。基础域名应命中对应 `GEOSITE`，补充域名应命中对应 `RULE-SET`。仓库静态检查不能替代设备上的网络验证。

- [Stash：规则集合](https://stash.wiki/rules/rule-set)
- [Stash：GEOSITE 规则](https://stash.wiki/rules/rule-types#geosite)
- [Stash：覆写配置](https://stash.wiki/configuration/override)
- [Stash：策略组](https://stash.wiki/proxy-protocols/proxy-groups)
- [OpenAI：官方网络域名说明](https://help.openai.com/en/articles/9247338-network-recommendations-for-chatgpt-errors-on-web-and-apps)
- [Claude：官方网络访问要求](https://code.claude.com/docs/en/network-config)

初始整理日期：2026-11-01。域名会随服务更新，按实际请求持续维护。
