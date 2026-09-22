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
// Аудит команд: каждое ".xxx" в исходниках должно быть известно серверу
// (ядро AzerothCore / модуль NPCBots / Extras репака RageZone)
//---------------------------------------------------------------------------
const KNOWN_COMMANDS = new Set([
	// --- AzerothCore 3.3.5 ---
	"account", "additem", "additemset", "announce", "appear", "aura", "ban",
	"character", "cheat", "combatstop", "cooldown", "die", "distance",
	"explorecheat", "freeze", "gm", "gmchat", "go", "gobject", "gps",
	"groupsummon", "instance", "kick", "learn", "levelup", "lookup", "maxskill",
	"modify", "mute", "npc", "pinfo", "recall", "reload", "repairitems", "reset",
	"revive", "save", "saveall", "send", "server", "setskill", "summon", "tele",
	"unaura", "unban", "unmute", "unlearn", "unfreeze", "who",
	// --- модуль NPCBots (trickerer / netweaver) ---
	"npcbot",
	// --- Extras твоего репака (RageZone: NPCBots + Eluna + Extras) ---
	"bank", "buff", "ga", "repairall", "resetid", "chat", "hirebot",
	"npcarena", "npcemblem", "npcreset", "npcbeast", "npcfreepro",
	"npcvweapon", "npcallmount", "npcbuff", "npcenchant", "npclottery",
	"npcguild", "npctalent", "npcracial", "npcbank",
]);

function auditCommands() {
	const files = fs.readdirSync(ADDON_DIR).filter((f) => f.endsWith(".lua"));
	const found = new Map(); // команда -> [файлы]

	for (const file of files) {
		let src = fs.readFileSync(path.join(ADDON_DIR, file), "utf8");
		src = src.replace(/--[^\n]*/g, ""); // без комментариев
		const re = /"([.#])([a-zA-Z_]+)/g;
		let m;
		while ((m = re.exec(src)) !== null) {
			const cmd = m[1] + m[2];
			if (!found.has(cmd)) found.set(cmd, new Set());
			found.get(cmd).add(file);
		}
	}

	const unknown = [];
	for (const [cmd, where] of found) {
		if (cmd.startsWith("#")) continue; // #id телепорта / сниппеты
		if (!KNOWN_COMMANDS.has(cmd.slice(1))) {
			unknown.push(`${cmd} (${[...where].join(", ")})`);
		}
	}
	return { total: found.size, unknown };
}

//---------------------------------------------------------------------------
// Статический анализ: FontString/Texture — не фреймы.
// У них нет SetScript, RegisterEvent, CreateFontString и т.п. Такие вызовы
// ломали загрузку аддона в игре (Main.lua:129), поэтому проверяем и статикой,
// а не только прогоном: это ловит пути, до которых тесты не доходят.
//---------------------------------------------------------------------------
const FRAME_ONLY = new Set([
	"SetScript", "GetScript", "HookScript", "RegisterEvent", "UnregisterEvent",
	"UnregisterAllEvents", "IsEventRegistered", "CreateFontString", "CreateTexture",
	"CreateFont", "GetChildren", "GetRegions", "GetNumChildren", "SetBackdrop",
	"SetBackdropColor", "SetBackdropBorderColor", "EnableMouse", "EnableMouseWheel",
	"RegisterForClicks", "RegisterForDrag", "SetMovable", "SetClampedToScreen",
	"SetToplevel", "SetFrameStrata", "GetFrameStrata", "SetFrameLevel", "GetFrameLevel",
	"Raise", "Lower", "StartMoving", "StopMovingOrSizing", "SetScrollChild",
	"GetScrollChild", "SetVerticalScroll", "GetVerticalScroll", "SetMinMaxValues",
	"SetValue", "GetValue", "SetOwner", "AddLine",
]);

function auditRegions() {
	const problems = [];
	const files = fs.readdirSync(ADDON_DIR).filter((f) => f.endsWith(".lua"));

	for (const file of files) {
		const lines = fs.readFileSync(path.join(ADDON_DIR, file), "utf8").split(/\r?\n/);
		const regionVars = new Map(); // имя -> строка определения

		lines.forEach((line, idx) => {
			const code = line.replace(/--.*$/, ""); // без комментариев

			// «local x = AT.MakeLabel(...)» / «a.b = AT.MakeLine(...)» / «= ...:CreateFontString(»
			const assignRe = /(?:local\s+)?([A-Za-z_][\w.]*)\s*=\s*(?:AT\.Make(?:Label|Line)|[\w.:]+:Create(?:FontString|Texture))\s*\(/g;
			let m;
			while ((m = assignRe.exec(code)) !== null) {
				regionVars.set(m[1].split(".").pop(), idx + 1);
			}

			// вызов фреймового метода у региона
			for (const [name, defLine] of regionVars) {
				const callRe = new RegExp("\\b" + name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") +
					"\\s*:\\s*([A-Za-z_][\\w]*)\\s*\\(");
				const c = callRe.exec(code);
				if (c && FRAME_ONLY.has(c[1])) {
					problems.push(`${file}:${idx + 1} — ${name}:${c[1]}() ` +
						`(у ${name} — региона, определён в строке ${defLine}): ` +
						`такого метода в API 3.3.5 нет`);
				}
			}
		});
	}
	return problems;
}

//---------------------------------------------------------------------------
// Прогон
//---------------------------------------------------------------------------
console.log(`${C.bold}Admin Tools RU — проверка аддона${C.off}`);
console.log(`${C.dim}Lua: ${lua.LUA_RELEASE} · корень: ${ROOT}${C.off}\n`);

const tocFiles = readToc(TOC);
console.log(`${C.dim}Файлы из .toc (${tocFiles.length}): ${tocFiles.join(", ")}${C.off}`);

// Каждая текстура, на которую ссылается ядро, должна лежать в AdminToolsRU/skin/
function auditSkin() {
	const core = fs.readFileSync(path.join(ADDON_DIR, "Core.lua"), "utf8");
	const skinDir = path.join(ADDON_DIR, "skin");
	// в Core.lua: btnNormal = AT.SKIN_PATH .. "btn-normal"
	const refs = [...core.matchAll(/AT\.SKIN_PATH\s*\.\.\s*"([a-zA-Z0-9_-]+)"/g)].map((m) => m[1]);
	const uniq = [...new Set(refs)];
	const missing = uniq.filter((name) => !fs.existsSync(path.join(skinDir, name + ".tga")));
	return { total: uniq.length, missing, files: uniq };
}

const skin = auditSkin();
console.log(`${C.dim}Текстур скина: ${skin.total} (${skin.files.join(", ")})${C.off}`);
if (skin.total === 0) {
	console.log(`${C.red}${C.bold}Текстуры не найдены в коде — сломан разбор Core.lua${C.off}`);
	skin.missing.push("<не найдено ни одной ссылки на текстуры>");
}
if (skin.missing.length) {
	console.log(`${C.red}${C.bold}Нет файлов текстур:${C.off} ${skin.missing.join(", ")}`);
	console.log(`${C.dim}  запусти: python3 tools/gen_textures.py${C.off}`);
} else {
	console.log(`${C.green}✓${C.off} все текстуры скина на месте`);
}

const regionProblems = auditRegions();
if (regionProblems.length) {
	console.log(`${C.red}${C.bold}Методы фреймов вызваны у регионов (FontString/Texture):${C.off}`);
	for (const p of regionProblems) console.log(`  ${C.red}✗${C.off} ${p}`);
	console.log(`${C.dim}  такие вызовы обрывают загрузку файла в игре${C.off}`);
} else {
	console.log(`${C.green}✓${C.off} регионы (FontString/Texture) используют только свои методы`);
}

// Шрифты 3.3.5 содержат ASCII, кириллицу и часть типографских знаков.
// Символы вне этого набора рискуют превратиться в «?» или пустоту.
function auditGlyphs() {
	const allowed = new Set([
		0x00ab, 0x00bb,   // « »
		0x2013, 0x2014,   // – —
		0x2026,           // …
	]);
	const problems = [];
	const files = fs.readdirSync(ADDON_DIR).filter((f) => f.endsWith(".lua"));

	for (const file of files) {
		const text = fs.readFileSync(path.join(ADDON_DIR, file), "utf8");
		text.split(/\r?\n/).forEach((line, idx) => {
			const code = line.replace(/--.*$/, "");
			const literals = code.match(/"(?:[^"\\]|\\.)*"/g) || [];
			for (const lit of literals) {
				for (const ch of lit) {
					const cp = ch.codePointAt(0);
					const safe = (cp >= 0x20 && cp <= 0x7e)      // ASCII
						|| (cp >= 0x410 && cp <= 0x44f)          // А-я
						|| cp === 0x401 || cp === 0x451          // Ё ё
						|| allowed.has(cp);
					if (!safe) {
						problems.push(`${file}:${idx + 1} — U+${cp.toString(16).toUpperCase()} ` +
							`"${ch}" в «${lit.slice(0, 40)}»`);
					}
				}
			}
		});
	}
	return problems;
}

const glyphs = auditGlyphs();
if (glyphs.length) {
	console.log(`${C.red}${C.bold}Символы, которых может не быть в шрифте 3.3.5:${C.off}`);
	for (const g of glyphs) console.log(`  ${C.red}✗${C.off} ${g}`);
	console.log(`${C.dim}  замени на безопасные: стрелки/треугольники текстом${C.off}`);
} else {
	console.log(`${C.green}✓${C.off} в текстах только символы, которые есть в шрифтах 3.3.5`);
}

const audit = auditCommands();
console.log(`${C.dim}Команд в аддоне: ${audit.total}${C.off}`);
if (audit.unknown.length) {
	console.log(`${C.red}${C.bold}Неизвестные серверу команды:${C.off}`);
	for (const u of audit.unknown) console.log(`  ${C.red}✗${C.off} ${u}`);
} else {
	console.log(`${C.green}✓${C.off} все команды известны ядру/модулям (опечаток нет)`);
}
console.log("");

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

const failed = fail + audit.unknown.length + skin.missing.length
	+ regionProblems.length + glyphs.length;
process.exit(failed === 0 ? 0 : 1);
