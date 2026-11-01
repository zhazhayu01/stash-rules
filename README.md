# Stash 远程规则集

自用、可独立维护的 Stash 分流补充规则，覆盖 OpenAI / ChatGPT / Codex、Claude 和 X（Twitter）。配合已有的机场订阅使用，不包含节点、订阅地址或密钥。

## 导入 Stash

1. 保留并启用已有的节点订阅配置，使用规则模式。
2. 在 Stash 的「覆写」中添加下方远程地址，并启用。也可点击[一键安装覆写](https://link.stash.ws/install-override/raw.githubusercontent.com/zhazhayu01/stash-rules/main/stash.stoverride)。
3. 在策略组中分别为 `RS-OpenAI`、`RS-Claude`、`RS-X`、`RS-额外代理` 选择节点。各组会引用原配置中的全部节点和远程代理集，不依赖机场的策略组名称。
4. 打开相应服务，在 Stash「最近请求」中检查命中的规则和实际出口。

```text
https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/stash.stoverride
```

覆写依赖原配置提供节点；原配置没有节点时，请先添加订阅。本文件不是独立的完整代理配置。

## 规则文件

| 文件 | 用途 | 远程地址 |
| --- | --- | --- |
| [openai.yaml](rules/openai.yaml) | OpenAI、ChatGPT、Codex 的核心域名 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/openai.yaml) |
| [claude.yaml](rules/claude.yaml) | Claude 网页、API、Claude Code 的核心域名 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/claude.yaml) |
| [x.yaml](rules/x.yaml) | X / Twitter、图片与视频、短链接 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/x.yaml) |
| [extra-proxy.yaml](rules/extra-proxy.yaml) | 自定义代理规则，初始为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/extra-proxy.yaml) |
| [extra-direct.yaml](rules/extra-direct.yaml) | 自定义直连规则，初始为空 | [Raw](https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/extra-direct.yaml) |

全部使用 `classical` + YAML 格式，可以单独通过 `rule-providers` 引用。只导入规则文件时，还需自行在配置的 `rules` 中添加 `RULE-SET,规则集名称,你的策略组`。

## 日常维护

直接在 GitHub 打开对应文件，点击编辑并提交到 `main`；本地修改也可正常提交推送。已导入的规则集每 24 小时检查更新，急用时在 Stash 手动更新规则集。修改 `stash.stoverride` 后需要更新远程覆写并重新加载配置。

自定义规则示例（将空文件中的 `payload: []` 改为以下形式，替换示例域名）：

```yaml
payload:
  - DOMAIN,api.example.com
  - DOMAIN-SUFFIX,example.org
  - IP-CIDR,192.0.2.0/24,no-resolve
```

- `DOMAIN` 只匹配该域名；`DOMAIN-SUFFIX` 匹配域名本身及其子域名。规则内不要写 `https://`、路径或策略组名称。
- 匹配顺序：额外直连 → 额外代理 → OpenAI → Claude → X → 原配置规则。因此自定义规则可以覆盖服务规则；同一域名同时加入两个额外规则集时，直连优先。
- 覆写将规则插入原配置前面。若存在其他覆写，请检查合并后的顺序，确保这些规则在兜底 `MATCH` 之前。
- 本规则集只维护服务域名；共用的验证码、支付、登录组件及第三方工具请求由原配置继续处理。遇到遗漏，请从「最近请求」确认域名后按需补充，避免把整个公共 CDN 分给某个服务。
- 规则决定流量出口，节点本身仍需满足相应服务的地区与网络要求。建议为同一服务保持稳定出口。
- 仓库公开，请勿提交订阅链接、节点密码、Token 或含有凭据的日志。

## 验证与资料

修改后检查 YAML 语法、规则集名称与策略组引用，再更新 Stash，实测网页登录、对话、附件及 X 媒体加载，并查看实际命中结果。仓库静态检查不能替代设备上的网络验证。

- [Stash：规则集合](https://stash.wiki/rules/rule-set)
- [Stash：覆写配置](https://stash.wiki/configuration/override)
- [Stash：策略组](https://stash.wiki/proxy-protocols/proxy-groups)
- [OpenAI：官方网络域名说明](https://help.openai.com/en/articles/9247338-network-recommendations-for-chatgpt-errors-on-web-and-apps)
- [Claude：官方网络访问要求](https://code.claude.com/docs/en/network-config)

初始整理日期：2026-11-01。域名会随服务更新，按实际请求持续维护。
