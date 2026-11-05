// stash-rules-private-ai schema: 1
// 用于当前订阅的扩展脚本，在全局适配脚本之后执行；订阅地址只保存在本地。
function main(config) {
  const subscription = "PRIVATE_SUBSCRIPTION_URL";
  if (!/^https?:\/\/\S+$/.test(subscription)) {
    throw new Error("请先在本地填写私人订阅地址");
  }
  const existingGroups = config["proxy-groups"] || [];
  const existingProviders = config["rule-providers"] || {};
  if (!["RS-美国", "RS-新加坡"].every(function (name) {
    return existingGroups.some(function (group) { return group.name === name; });
  }) || !["extra-direct", "openai", "claude", "gemini", "grok"].every(function (name) {
    return !!existingProviders["rs-" + name];
  })) {
    throw new Error("请先安装并启用本项目的全局适配脚本");
  }
  const icon = "https://raw.githubusercontent.com/Hawaiine/Oasisic-Icons/main/icons/System/GeneralAI/GeneralAI.png";
  const groups = [
    { name: "RS-AI自用节点", type: "select", icon: icon, use: ["rs-private-ai"], "empty-fallback": "REJECT" },
    { name: "RS-AI出口", type: "select", icon: icon, proxies: ["RS-AI自用节点", "RS-美国", "RS-新加坡"] },
  ];
  config["proxy-providers"] = Object.assign({}, config["proxy-providers"] || {}, {
    "rs-private-ai": {
      type: "http", url: subscription, path: "./proxy_providers/rs-private-ai.yaml", interval: 3600,
    },
  });
  const names = new Set(groups.map(function (group) { return group.name; }));
  config["proxy-groups"] = groups.concat(existingGroups.filter(function (group) { return !names.has(group.name); }));
  const rules = [
    "RULE-SET,rs-extra-direct,DIRECT",
    "RULE-SET,rs-openai,RS-AI出口",
    "RULE-SET,rs-claude,RS-AI出口",
    "RULE-SET,rs-gemini,RS-AI出口",
    "RULE-SET,rs-grok,RS-AI出口",
    "GEOSITE,openai,RS-AI出口",
    "GEOSITE,anthropic,RS-AI出口",
    "GEOSITE,google-deepmind,RS-AI出口",
    "GEOSITE,xai,RS-AI出口",
  ];
  const ownRules = new Set(rules);
  config.rules = rules.concat((config.rules || []).filter(function (rule) { return !ownRules.has(rule); }));
  return config;
}
