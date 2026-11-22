// stash-rules-verge schema: 1
// Clash Verge Rev 全局扩展脚本：美国 / 新加坡出口、GEOSITE 与远程补充规则。
// RS- 策略组与 rs- 规则集名称由本脚本维护；重复应用不会产生重复条目。
function main(config) {
  if (!config || typeof config !== "object" || Array.isArray(config)) {
    throw new Error("输入必须是订阅配置对象");
  }

  const icons = "https://raw.githubusercontent.com/Hawaiine/Oasisic-Icons/main/icons/";
  const raw = "https://raw.githubusercontent.com/zhazhayu01/stash-rules/main/rules/";
  const regions = ["RS-美国", "RS-新加坡"];
  const services = [
    ["OpenAI", "AI/OpenAI/OpenAI.png"],
    ["Claude", "AI/Anthropic/Anthropic.png"],
    ["X", "SpaceXAI/X/X.png"],
    ["Google", "Google/Google/Google.png"],
  ];
  const groups = [
    {
      name: regions[0], type: "select", "include-all": true,
      icon: icons + "Country/US/US.png",
      filter: "(?i)(美国|美國|美西|美东|美東|洛杉矶|洛杉磯|圣何塞|聖何塞|西雅图|西雅圖|纽约|紐約|🇺🇸|United[ _-]*States|(?:^|[^a-z])USA?(?:[^a-z]|$))",
      // 未找到地区节点时明确拒绝，避免误用直连出口。
      "empty-fallback": "REJECT",
    },
    {
      name: regions[1], type: "select", "include-all": true,
      icon: icons + "Country/Singapore/Singapore.png",
      filter: "(?i)(新加坡|狮城|獅城|🇸🇬|Singapore|(?:^|[^a-z])SGP?(?:[^a-z]|$))",
      "empty-fallback": "REJECT",
    },
  ];
  services.forEach(function (service) {
    groups.push({
      name: "RS-" + service[0], type: "select", icon: icons + service[1],
      proxies: regions.slice(),
    });
  });

  const providers = Object.assign({}, config["rule-providers"] || {});
  delete providers["rs-extra-proxy"];
  delete providers["rs-gemini"];
  delete providers["rs-grok"];
  delete providers["rs-deepseek"];
  ["openai", "claude", "x", "google", "extra-direct"].forEach(function (name) {
    providers["rs-" + name] = {
      type: "http", behavior: "classical", format: "yaml",
      url: raw + name + ".yaml", path: "./ruleset/rs-" + name + ".yaml", interval: 86400,
    };
  });

  const rules = [
    "RULE-SET,rs-extra-direct,DIRECT",
    "RULE-SET,rs-openai,RS-OpenAI",
    "RULE-SET,rs-claude,RS-Claude",
    "RULE-SET,rs-x,RS-X",
    "RULE-SET,rs-google,RS-Google",
    "GEOSITE,openai,RS-OpenAI",
    "GEOSITE,anthropic,RS-Claude",
    "GEOSITE,google-deepmind,RS-Google",
    "GEOSITE,google,RS-Google",
    "GEOSITE,xai,RS-X",
    "GEOSITE,twitter,RS-X",
  ];
  const names = new Set(groups.map(function (group) { return group.name; }));
  const ownRules = new Set(rules);
  // 清理旧版已生成的策略组与规则。
  ["RS-额外代理", "RS-Gemini", "RS-Grok", "RS-DeepSeek"].forEach(function (name) { names.add(name); });
  [
    "RULE-SET,rs-extra-proxy,RS-额外代理",
    "RULE-SET,rs-gemini,RS-Gemini",
    "GEOSITE,google-deepmind,RS-Gemini",
    "RULE-SET,rs-grok,RS-Grok",
    "GEOSITE,xai,RS-Grok",
    "RULE-SET,rs-deepseek,RS-DeepSeek",
    "GEOSITE,deepseek,RS-DeepSeek",
  ].forEach(function (rule) { ownRules.add(rule); });
  config["proxy-groups"] = groups.concat((config["proxy-groups"] || []).filter(function (group) {
    return !names.has(group.name);
  }));
  config["rule-providers"] = providers;
  config.rules = rules.concat((config.rules || []).filter(function (rule) {
    return !ownRules.has(rule);
  }));
  return config;
}
