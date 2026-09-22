#!/usr/bin/env node
//===========================================================================
// tools/test/run.js
// Прогон аддона Admin Tools RU на заглушке WoW API (Lua 5.3 через Fengari).
//
// Запуск:  cd tools && npm install && npm test
//
// Порядок: wow_stub.lua → файлы из .toc → boot.lua (события) → tests.lua.
// Код возврата: 0 — всё хорошо, 1 — есть падения.
//===========================================================================

"use strict";

const fs = require("fs");
const path = require("path");
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require("fengari");

const TOOLS = path.resolve(__dirname, "..");
const ROOT = path.resolve(TOOLS, "..");
const ADDON_DIR = path.join(ROOT, "AdminToolsRU");
const TOC = path.join(ADDON_DIR, "AdminToolsRU.toc");

const C = { red: "\x1b[31m", green: "\x1b[32m", yellow: "\x1b[33m", dim: "\x1b[2m", bold: "\x1b[1m", off: "\x1b[0m" };

function fatal(msg) {
	console.error(`${C.red}${C.bold}ОШИБКА:${C.off} ${msg}`);
	process.exit(1);
}

//---------------------------------------------------------------------------
// Чтение списка файлов из .toc
//---------------------------------------------------------------------------
function readToc(tocPath) {
	if (!fs.existsSync(tocPath)) fatal(`Не найден ${tocPath}`);
	const lines = fs.readFileSync(tocPath, "utf8").split(/\r?\n/);
	const files = [];
	for (const raw of lines) {
		const line = raw.trim();
		if (line === "" || line.startsWith("#")) continue;
		files.push(line.split(/\s+/)[0]);
	}
	return files;
}

//---------------------------------------------------------------------------
// Lua-окружение
//---------------------------------------------------------------------------
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

function popError() {
	const msg = to_jsstring(lua.lua_tolstring(L, -1, null));
	lua.lua_pop(L, 1);
	return msg;
}

function runChunk(source, name) {
	const buff = Buffer.isBuffer(source) ? source : Buffer.from(source, "utf8");
	let status = lauxlib.luaL_loadbuffer(L, buff, buff.length, to_luastring(name));
	if (status !== lua.LUA_OK) {
		fatal(`${name}\n  ${popError()}`);
	}
	status = lua.lua_pcall(L, 0, 0, 0);
	if (status !== lua.LUA_OK) {
		fatal(`${name}\n  ${popError()}`);
	}
}

function runFile(file) {
	if (!fs.existsSync(file)) fatal(`Не найден файл ${file}`);
	runChunk(fs.readFileSync(file), path.relative(ROOT, file));
}

function tableField(name, key) {
	lua.lua_getglobal(L, to_luastring(name));
	if (!lua.lua_istable(L, -1)) { lua.lua_pop(L, 1); return undefined; }
	lua.lua_getfield(L, -1, to_luastring(key));
	let out;
	if (lua.lua_isnumber(L, -1)) out = lua.lua_tonumber(L, -1);
	else if (lua.lua_isstring(L, -1)) out = to_jsstring(lua.lua_tolstring(L, -1, null));
	lua.lua_pop(L, 2);
	return out;
}

function tableArray(name, key) {
	lua.lua_getglobal(L, to_luastring(name));
	if (!lua.lua_istable(L, -1)) { lua.lua_pop(L, 1); return []; }
	lua.lua_getfield(L, -1, to_luastring(key));
	const out = [];
	if (lua.lua_istable(L, -1)) {
		const len = lua.lua_rawlen(L, -1);
		for (let i = 1; i <= len; i++) {
			lua.lua_rawgeti(L, -1, i);
			if (lua.lua_isstring(L, -1)) out.push(to_jsstring(lua.lua_tolstring(L, -1, null)));
			else out.push(String(lua.lua_toboolean(L, -1)));
			lua.lua_pop(L, 1);
		}
	}
	lua.lua_pop(L, 2);
	return out;
}

function globalArray(name) {
	lua.lua_getglobal(L, to_luastring(name));
	const out = [];
	if (lua.lua_istable(L, -1)) {
		const len = lua.lua_rawlen(L, -1);
		for (let i = 1; i <= len; i++) {
			lua.lua_rawgeti(L, -1, i);
			if (lua.lua_isstring(L, -1)) out.push(to_jsstring(lua.lua_tolstring(L, -1, null)));
			lua.lua_pop(L, 1);
		}
	}
	lua.lua_pop(L, 1);
	return out;
}

//---------------------------------------------------------------------------
// Прогон
//---------------------------------------------------------------------------
console.log(`${C.bold}Admin Tools RU — проверка аддона${C.off}`);
console.log(`${C.dim}Lua: ${lua.LUA_RELEASE} · корень: ${ROOT}${C.off}\n`);

const tocFiles = readToc(TOC);
console.log(`${C.dim}Файлы из .toc (${tocFiles.length}): ${tocFiles.join(", ")}${C.off}`);

runFile(path.join(TOOLS, "test", "wow_stub.lua"));
const missing = [];
for (const f of tocFiles) {
	const full = path.join(ADDON_DIR, f);
	if (!fs.existsSync(full)) { missing.push(f); continue; }
	runFile(full);
}
if (missing.length) fatal(`в .toc указаны отсутствующие файлы: ${missing.join(", ")}`);
console.log(`${C.green}✓${C.off} все файлы аддона загружены и выполнились без ошибок`);

runFile(path.join(TOOLS, "test", "boot.lua"));
console.log(`${C.green}✓${C.off} события ADDON_LOADED и PLAYER_LOGIN обработаны\n`);

runFile(path.join(TOOLS, "test", "tests.lua"));

//---------------------------------------------------------------------------
// Итоги
//---------------------------------------------------------------------------
const pass = tableField("AT_TEST", "pass") | 0;
const fail = tableField("AT_TEST", "fail") | 0;
const fails = tableArray("AT_TEST", "fails");
const notes = tableArray("AT_TEST", "notes");

for (const n of notes) console.log(`${C.dim}· ${n}${C.off}`);

if (fails.length) {
	console.log(`${C.red}${C.bold}Провалено (${fail}):${C.off}`);
	for (const f of fails) console.log(`  ${C.red}✗${C.off} ${f}`);
}

const unknown = globalArray("STUB.unknownNames");
const eventError = tableField("STUB", "eventError");
console.log("");
if (unknown.length) {
	console.log(`${C.yellow}⚠ заглушка не знает методов виджетов (${unknown.length}): ${unknown.join(", ")}${C.off}`);
	console.log(`${C.dim}  это не ошибка аддона, но стоит убедиться, что методы реально есть в API 3.3.5${C.off}`);
}
if (eventError) console.log(`${C.yellow}⚠ ошибка в обработчике события: ${eventError}${C.off}`);

console.log(`${C.bold}Итог:${C.off} ${C.green}${pass} пройдено${C.off}, ` +
	(fail ? `${C.red}${fail} провалено${C.off}` : `${C.green}0 провалено${C.off}`));

process.exit(fail === 0 ? 0 : 1);
