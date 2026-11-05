// 使用假订阅验证私人补充，不读取或输出真实订阅地址。
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "..");
const baseContext = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(root, "verge/clash-verge.js"), "utf8"), baseContext);
const template = fs.readFileSync(path.join(root, "private-ai/clash-verge.js"), "utf8");
const privateContext = vm.createContext({});
vm.runInContext(template.replace("PRIVATE_SUBSCRIPTION_URL", "https://example.invalid/sub/private-ai"), privateContext);
const run = value => JSON.parse(JSON.stringify(privateContext.main(JSON.parse(JSON.stringify(value)))));
const base = JSON.parse(JSON.stringify(baseContext.main({
  proxies: [{ name: "美国测试", type: "socks5", server: "127.0.0.1", port: 1080 }],
  "proxy-providers": { original: { type: "inline", payload: [] } },
  rules: ["MATCH,DIRECT"],
})));
const result = run(base);
assert.deepEqual(run(result), result, "重复应用应保持一致");
assert.deepEqual(result.proxies, base.proxies);
assert.deepEqual(result["proxy-providers"].original, base["proxy-providers"].original);
assert.deepEqual(result["rule-providers"], base["rule-providers"]);
assert.deepEqual(result["proxy-groups"].slice(2), base["proxy-groups"]);
assert.deepEqual(result["proxy-groups"][1].proxies, ["RS-AI自用节点", "RS-美国", "RS-新加坡"]);
assert.equal(result["proxy-groups"][0]["empty-fallback"], "REJECT");
const stash = fs.readFileSync(path.join(root, "private-ai/stash.stoverride"), "utf8");
const rules = [...stash.matchAll(/^  - ((?:RULE-SET|GEOSITE),.+)$/gm)].map(m => m[1].trim());
assert.equal(rules.length, 9);
assert.deepEqual(result.rules.slice(0, rules.length), rules, "两种客户端应使用同一优先规则顺序");
assert.equal(result.rules[0], "RULE-SET,rs-extra-direct,DIRECT");
assert.ok(result.rules.indexOf("GEOSITE,xai,RS-AI出口") < result.rules.indexOf("GEOSITE,twitter,RS-X"));
assert.ok(result.rules.includes("GEOSITE,deepseek,RS-DeepSeek"));
assert.equal(result.rules.at(-1), "MATCH,DIRECT");
assert.throws(() => run({}), /全局适配/);
const unconfigured = vm.createContext({});
vm.runInContext(template, unconfigured);
assert.throws(() => unconfigured.main(base), /私人订阅/);
console.log("PASS：两端规则一致、私有订阅合并、直连例外优先、Grok 优先于 X、重复应用、缺少主覆写时拒绝");
