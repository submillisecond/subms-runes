#!/usr/bin/env node
// deltalab MCP loader. The deltalab client (the room protocol, the agent and
// the MCP server) is not in this pack: it is fetched from deltalab's host each
// start, checked against the signature below, and run from memory. The client
// still runs on this machine, so the share link's key never leaves it.
//
// What is checked before anything runs:
//   - manifest.sig is a valid Ed25519 signature over manifest.json, made by the
//     key whose public half is PUBLIC_KEY (only a deltalab deploy holds the
//     private half);
//   - the client's size and SHA-256 match the signed manifest;
//   - the manifest's API version matches API, and it was built no earlier than
//     MIN_BUILT_AT, so an older signed client cannot be replayed.
// Anything else and it exits without running a byte of it.
//
// Environment:
//   DELTALAB_CLIENT_BASE   where the manifest lives (default below; file:// works for local builds)
//   DELTALAB_CLIENT_CACHE  a folder to keep the last verified client in, for starting offline;
//                          "1" uses the OS cache folder. Unset: nothing is written to disk.

import { createHash, createPublicKey, verify } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEA1dfK00SpCTHaC+XGc/vWX1B+4bB5ytIqPBSW+pCj9uI=
-----END PUBLIC KEY-----`;
// This pack's version: equal to .claude-plugin/plugin.json (the contract test
// checks). Compared with the newest pack the signed manifest names.
const PACK_VERSION = "0.4.0";
const API = "0.4";
const UPDATE = "claude plugin marketplace update subms-runes && claude plugin update deltalab@subms-runes";
const MIN_BUILT_AT = "2026-11-03T00:00:00Z";
const DEFAULT_BASE = "https://deltalab.submillisecond.com/runes/deltalab/";
const FETCH_TIMEOUT_MS = 15_000;

const say = (s) => process.stderr.write(`deltalab: ${s}\n`);
const fail = (s) => { say(s); process.exit(1); };

if (Number(process.versions.node.split(".")[0]) < 22) {
  fail(`needs Node 22 or newer (built-in WebSocket and WebCrypto). Found ${process.version}`);
}

const base = (process.env.DELTALAB_CLIENT_BASE || DEFAULT_BASE).replace(/\/?$/, "/");
if (!/^(https:\/\/|file:\/\/|http:\/\/(localhost|127\.0\.0\.1)(:\d+)?\/)/.test(base)) {
  fail(`DELTALAB_CLIENT_BASE must be https://, file:// or a localhost http:// address; got ${base}`);
}

function cacheDir() {
  const v = process.env.DELTALAB_CLIENT_CACHE;
  if (!v) return null;
  if (v !== "1") return v;
  if (process.platform === "win32") return join(process.env.LOCALAPPDATA || join(homedir(), "AppData", "Local"), "subms", "deltalab-client");
  if (process.platform === "darwin") return join(homedir(), "Library", "Caches", "subms", "deltalab-client");
  return join(process.env.XDG_CACHE_HOME || join(homedir(), ".cache"), "subms", "deltalab-client");
}

/** True when x.y.z `a` is newer than `b`. */
function newer(a, b) {
  const p = (v) => v.split(".").map(Number);
  const [x, y] = [p(a), p(b)];
  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] > y[i];
  return false;
}

async function get(name) {
  const url = new URL(name, base);
  if (url.protocol === "file:") return readFileSync(fileURLToPath(url));
  const res = await fetch(url, { signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) });
  if (!res.ok) throw new Error(`${url} answered ${res.status}`);
  return Buffer.from(await res.arrayBuffer());
}

/** The client bytes if every check passes, else a reason. */
function check(manifestBytes, sig, client) {
  let ok = false;
  try { ok = verify(null, manifestBytes, createPublicKey(PUBLIC_KEY), Buffer.from(String(sig).trim(), "base64")); } catch { ok = false; }
  if (!ok) return { reason: "the signature does not match deltalab's key" };
  let m;
  try { m = JSON.parse(manifestBytes.toString("utf8")); } catch { return { reason: "the manifest is not JSON" }; }
  if (m.name !== "deltalab-client") return { reason: `the manifest is for ${m.name}` };
  if (typeof m.version !== "string" || m.version.split(".").slice(0, 2).join(".") !== API) {
    return { reason: `the client speaks ${m.version}, this pack needs ${API}.x; update the deltalab pack` };
  }
  if (!(Date.parse(m.builtAt) >= Date.parse(MIN_BUILT_AT))) return { reason: `the client was built ${m.builtAt}, before this pack accepts` };
  if (!client) return { manifest: m };
  if (client.length !== m.size || createHash("sha256").update(client).digest("hex") !== m.sha256) {
    return { reason: "the client's bytes do not match the signed manifest" };
  }
  return { manifest: m, client };
}

async function fromNetwork() {
  const manifestBytes = await get("manifest.json");
  const sig = (await get("manifest.sig")).toString("utf8");
  const head = check(manifestBytes, sig, null);
  if (!head.manifest) return head;
  if (!/^client-[0-9A-Za-z.+-]+\.mjs$/.test(head.manifest.file)) return { reason: "the manifest names an unexpected file" };
  const r = check(manifestBytes, sig, await get(head.manifest.file));
  return r.client ? { ...r, manifestBytes, sig } : r;
}

function fromCache(dir) {
  try {
    const manifestBytes = readFileSync(join(dir, "manifest.json"));
    const sig = readFileSync(join(dir, "manifest.sig"), "utf8");
    const m = JSON.parse(manifestBytes.toString("utf8"));
    return check(manifestBytes, sig, readFileSync(join(dir, String(m.file).replace(/[\\/]/g, ""))));
  } catch {
    return { reason: "no cached client" };
  }
}

function keep(dir, r) {
  try {
    const cached = fromCache(dir);
    // Never replace a newer verified client with an older one.
    if (cached.manifest && Date.parse(cached.manifest.builtAt) > Date.parse(r.manifest.builtAt)) return;
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, r.manifest.file), r.client);
    writeFileSync(join(dir, "manifest.json"), r.manifestBytes);
    writeFileSync(join(dir, "manifest.sig"), r.sig);
  } catch (e) {
    say(`could not keep the client in ${dir} (${e.code || e.message}); it still runs`);
  }
}

const dir = cacheDir();
let r;
try {
  r = await fromNetwork();
} catch (e) {
  r = { reason: `could not fetch the client from ${base} (${e.message})`, offline: true };
}
if (!r.client) {
  if (r.offline && dir) {
    const cached = fromCache(dir);
    if (cached.client) {
      say(`${r.reason}; using the verified copy in ${dir}`);
      r = cached;
    }
  }
  if (!r.client) fail(`not starting: ${r.reason}`);
} else if (dir) {
  keep(dir, r);
}

const latest = typeof r.manifest.pack === "string" ? r.manifest.pack : null;
if (latest && newer(latest, PACK_VERSION)) {
  say(`this pack is ${PACK_VERSION} and ${latest} is out. Update it, then restart Claude Code: ${UPDATE}`);
}
// The client tells the model, which tells the person (agent/mcp/packUpdate.ts).
globalThis.__deltalabLoader = { pack: PACK_VERSION, latest };
say(`client ${r.manifest.build}${r.manifest.deploy ? ` (deltalab ${r.manifest.deploy})` : ""}, built ${r.manifest.builtAt}, signature verified`);
await import(`data:text/javascript;base64,${r.client.toString("base64")}`);
