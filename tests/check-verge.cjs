// 使用 Node 内置模块验证脚本，不安装依赖；不接触真实订阅与凭据。
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const crypto = require("node:crypto");
const root = path.resolve(__dirname, "..");
const code = fs.readFileSync(path.join(root, "verge/clash-verge.js"), "utf8");
const context = vm.createContext({});
vm.runInContext(code, context, { timeout: 1000 });
const input = {
  proxies: [{ name: "美国 01", type: "socks5", server: "127.0.0.1", port: 1080 }],
  "proxy-groups": [{ name: "机场原分组", type: "select", proxies: ["DIRECT"] }],
  "rule-providers": { original: { type: "inline", behavior: "classical", payload: [] } },
  rules: ["DOMAIN,example.org,DIRECT", "MATCH,机场原分组"],
  dns: { enable: true }, tun: { enable: false }, "mixed-port": 7890,
};
const run = (value) => JSON.parse(JSON.stringify(context.main(JSON.parse(JSON.stringify(value)))));
const result = run(input);
assert.deepEqual(result.proxies, input.proxies);
assert.deepEqual(result.dns, input.dns);
assert.deepEqual(result.tun, input.tun);
assert.equal(result["mixed-port"], 7890);
assert.deepEqual(result["proxy-groups"].at(-1), input["proxy-groups"][0]);
assert.deepEqual(result["rule-providers"].original, input["rule-providers"].original);
assert.deepEqual(result.rules.slice(-2), input.rules);
assert.deepEqual(run(result), result, "重复应用必须保持一致");
const groups = result["proxy-groups"].slice(0, -1);
assert.equal(groups.length, 9);
assert.deepEqual(groups.filter(g => g["include-all"]).map(g => g.name), ["RS-美国", "RS-新加坡"]);
for (const group of groups) {
  assert.match(group.icon, /^https:\/\/raw\.githubusercontent\.com\/Hawaiine\/Oasisic-Icons\//);
  if (group["include-all"]) assert.equal(group["empty-fallback"], "REJECT");
  else assert.deepEqual(group.proxies, group.name === "RS-DeepSeek" ? ["DIRECT", "RS-美国", "RS-新加坡"] : ["RS-美国", "RS-新加坡"]);
}
const stash = fs.readFileSync(path.join(root, "stash.stoverride"), "utf8");
const stashRules = [...stash.matchAll(/^  - ((?:RULE-SET|GEOSITE),.+)$/gm)].map(m => m[1].trim());
assert.deepEqual(result.rules.slice(0, 14), stashRules, "与 Stash 的规则顺序保持一致");
for (const group of groups) {
  assert.ok(stash.includes("name: " + group.name));
  assert.ok(stash.includes(group.icon));
  if (group.filter) assert.ok(stash.includes("filter: '" + group.filter + "'"));
}
for (const [name, provider] of Object.entries(result["rule-providers"])) {
  if (name === "original") continue;
  assert.equal(provider.type, "http");
  assert.ok(stash.includes(provider.url));
}
const manifest = JSON.parse(fs.readFileSync(path.join(root, "verge/manifest.json"), "utf8"));
assert.equal(manifest.sha256, crypto.createHash("sha256").update(code).digest("hex"));
assert.throws(() => context.main(null));
assert.equal(run({})["proxy-groups"].length, 9);
console.log("PASS：原配置保留、重复应用、地区限制、图标、14 条规则、8 份远程补充与发布校验和");
