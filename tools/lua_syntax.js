#!/usr/bin/env node
//===========================================================================
// tools/lua_syntax.js — проверка синтаксиса Lua во всех файлах аддонов.
//
// Fengari (Lua 5.3 в JS). Файлы только компилируются, не выполняются —
// поэтому не нужны ни API клиента, ни данные аддона.
//
// Файлы читаются как байты: это важно, потому что старые русские аддоны
// бывают в CP1251, и декодирование в UTF-8 их бы испортило.
//
// Запуск:
//   node tools/lua_syntax.js <папка-с-аддонами> [имя-аддона ...]
// Вывод: JSON { "ИмяАддона": ["файл:строка: сообщение", ...] }
//
// Клиент 3.3.5 (Lua 5.1) мягче, чем Fengari (Lua 5.3), поэтому часть
// сообщений компилятора — не ошибки аддона, а стро́гости новой версии:
//   * "invalid escape sequence" — Lua 5.1 спокойно пропускает "\g", "\." и т.п.;
//   * первая строка "#!..." — luaL_loadfile в 5.1 её пропускает.
// Такие находки помечаются префиксом "(5.1-ok)" и считаются замечаниями,
// а не ошибками (см. tools/audit_addons.py).
//===========================================================================

const fs = require("fs");
const path = require("path");
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require("fengari");

// Насколько терпима Lua 5.1 там, где Lua 5.3 ругается.
const LUA51_OK = [/invalid escape sequence/];

function isLua51Ok(msg) {
	return LUA51_OK.some((re) => re.test(msg));
}

const root = process.argv[2];
if (!root) {
	console.error("укажи папку с аддонами");
	process.exit(2);
}

const only = process.argv.slice(3);
const addons = (only.length ? only : fs.readdirSync(root))
	.filter((d) => {
		try {
			return fs.statSync(path.join(root, d)).isDirectory();
		} catch (e) {
			return false;
		}
	});

function luaFiles(dir, out) {
	out = out || [];
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) luaFiles(full, out);
		else if (entry.name.toLowerCase().endsWith(".lua")) out.push(full);
	}
	return out;
}

const report = {};

for (const addon of addons) {
	const dir = path.join(root, addon);
	const findings = [];

	for (const file of luaFiles(dir)) {
		const rel = path.relative(dir, file).split(path.sep).join("/");

		let buff;
		try {
			buff = fs.readFileSync(file);        // байты, без декодирования
		} catch (err) {
			findings.push(`${rel}: файл не читается (${err.message})`);
			continue;
		}

		// BOM (EF BB BF) в начале файла: клиент 3.3.5 его пропускает,
		// а luaL_loadbuffer — нет, поэтому срезаем, чтобы не ловить
		// ложную ошибку "unexpected symbol near '<\239>'".
		if (buff.length >= 3 && buff[0] === 0xEF && buff[1] === 0xBB && buff[2] === 0xBF) {
			buff = buff.subarray(3);
		}

		// Lua 5.1 в luaL_loadfile пропускает первую строку, если она
		// начинается с "#" (шебанг вида "#!/usr/local/bin/lua").
		// Повторяем это поведение, чтобы не ловить ложную ошибку.
		if (buff[0] === 0x23) {
			const nl = buff.indexOf(0x0A);
			buff = nl === -1 ? Buffer.alloc(0) : buff.subarray(nl + 1);
		}

		const L = lauxlib.luaL_newstate();
		lualib.luaL_openlibs(L);

		const status = lauxlib.luaL_loadbuffer(L, buff, buff.length, to_luastring("@" + rel));

		if (status !== lua.LUA_OK) {
			let msg;
			try {
				msg = to_jsstring(lua.lua_tostring(L, -1));
			} catch (e) {
				msg = String(lua.lua_tostring(L, -1));
			}
			// сообщение вида "rel:12: 'end' expected near '<eof>'" — убираем префикс
			let clean = msg.replace(/^@?[^\n]*?:\s*/, "");
			clean = clean.replace(new RegExp(escapeRe(rel) + ":", "g"), "");
			clean = clean.replace(/\s+/g, " ").trim();
			// Мягкие расхождения Lua 5.1 <-> 5.3 — это замечание, не ошибка.
			const prefix = isLua51Ok(clean) ? "(5.1-ok) " : "";
			findings.push(`${rel}: ${prefix}${clean}`);
		}

		lua.lua_close(L);
	}

	report[addon] = findings;
}

function escapeRe(s) {
	return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

process.stdout.write(JSON.stringify(report, null, 1));
