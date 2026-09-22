# Справочник команд Admin Tools RU v5.1

Все команды, которые отправляет панель (71 уникальная), с указанием вкладки.
Проверяется автотестом: неизвестные ядру/модулям команды в сборку не попадут.

Источники: **AzerothCore 3.3.5** (ядро), модуль **NPCBots** (trickerer/netweaver),
**Extras** твоего репака (RageZone: NPCBots + Eluna + Extras + Custom Races).

---

## Вкладка «Мир»

| Команда | Что делает |
|---|---|
| `.gps` | координаты и карта |
| `.distance` | дистанция до цели |
| `.recall` | вернуться в предыдущую точку |
| `.go creature <id\|имя>` | переместиться к существу |
| `.go object <guid>` | переместиться к объекту |
| `.go xyz <x> <y> <z> [map]` | переместиться в точку |
| `.go zonexy <x> <y>` | переместиться по зональным координатам |
| `.lookup area \| creature \| item \| spell \| quest \| gameobject <текст>` | поиск по базе |
| `.gobject info \| move \| turn \| near \| target` | работа с объектами |
| `.gobject add <entry> [spawntime <сек>]` | создать объект |
| `.gobject delete` | удалить выбранный объект (с подтверждением) |
| `.npc add <entry>` | заспавнить NPC |
| `.npc info \| move \| turn \| reset` | работа с NPC |
| `.npc delete` | удалить выбранного NPC (с подтверждением) |

## Вкладка «Телепорт»

| Команда | Что делает |
|---|---|
| `.tele <имя>` / `.tele #<id>` | телепорт по имени или id из `game_tele` |
| `.tele add <имя>` | сохранить текущую точку |
| `.lookup tele <текст>` | найти телепорт |
| `.recall` | вернуться |
| `.instance unbind all` | снять привязки к подземельям |

Столицы: Альянс (Штормград, Стальгорн, Дарнас, Экзодар), Орда (Оргриммар, Подгород,
Громовой Утёс, Луносвет), нейтральные (Шаттрат, Даларан, Пиратская Бухта, Прибамбасск).
Телепорт в столицу вражеской фракции спрашивает подтверждение.

## Вкладка «Путешествие»

Подземелья, рейды и места кача — выпадающими списками по дополнениям (Классика / BC / WotLK).
Для точек без нормального имени телепорта используются координаты `.go xyz`.

## Вкладка «Боты» — модуль NPCBots

### Отряд: движение

| Команда | Что делает |
|---|---|
| `.npcbot command follow` | боты идут за тобой |
| `.npcbot command follow only` | идут, но не атакуют и не кастуют |
| `.npcbot command standstill` | держат позицию, реагируют на бой |
| `.npcbot command stopfully` | полный стоп: не двигаются и не реагируют |
| `.npcbot command walk` | переключить шаг/бег |
| `.npcbot command nogossip` | запретить окно общения бота |
| `.npcbot revive` | воскресить бота (или всех своих) |
| `.npcbot hide` | временно убрать ботов из мира |
| `.npcbot vehicle eject` | выкинуть ботов из транспорта |
| `.npcbot info` | сведения о твоих ботах |
| `.npcbot distance <1-100>` | дистанция следования |
| `.npcbot distance attack <N>` | дистанция атаки |

### Найм, поиск, спавн

| Команда | Что делает |
|---|---|
| `.npcbot lookup <класс>` | найти ботов класса (1..11, героические 12..20) |
| `.npcbot spawn <id>` | заспавнить бота |
| `.npcbot move <id>` | переместить бота к себе |
| `.npcbot go <entry>` | телепортироваться к боту |

### Настройка (GM)

| Команда | Что делает |
|---|---|
| `.npcbot add` | присвоить выделенного бота себе |
| `.npcbot remove` | уволить бота |
| `.npcbot free` | освободить бота от владельца |
| `.npcbot set faction <a\|h\|m\|f>` | фракция бота |
| `.npcbot set spec <1-30>` | принудительно сменить спеку |
| `.npcbot set owner <ник>` | сменить владельца |
| `.npcbot order cast <бот> <спелл> [цель>` | приказ на каст |
| `.npcbot delete` / `delete id <id>` / `delete free` | удаление бота (с подтверждением) |
| `.npcbot reloadconfig` | перечитать конфиг модуля |
| `.npcbot wp spawnall` | разработка: точки блуждания |

**Классы ботов:** 1 Воин · 2 Паладин · 3 Охотник · 4 Разбойник · 5 Жрец ·
6 Рыцарь смерти · 7 Шаман · 8 Маг · 9 Чернокнижник · 11 Друид.
**Героические (если собраны):** 12 Blademaster · 13 Sphynx · 14 Archmage · 15 Dreadlord ·
16 Spellbreaker · 17 Dark Ranger · 18 Necromancer · 19 Sea Witch · 20 Crypt Lord.

## Вкладка «NPC»

Кастомные NPC из модулей сервера (`190010` Трансмог, `601014`/`55005` Маунты,
`601026` Beastmaster, `601015` Энчантер, `601016` Буфер, `601017` Профессии,
`601018` Таланты, `34567` Guildhouse, `999991` Арена 1х1, `25462` Скип ДК, `98888` Расовые)
и стандартные торговцы/банкиры/аукционисты Альянса и Орды. Плюс ручной спавн по entry,
поиск и удаление.

## Вкладка «Модули» — Extras твоего репака

| Команда | Что делает |
|---|---|
| `.hirebot` | NPC найма ботов |
| `.npcarena` | NPC арены 1х1 |
| `.npcemblem` | NPC обмена эмблем |
| `.npcreset` | NPC сброса инстансов |
| `.npcbeast` | NPC управления питомцами |
| `.npcfreepro` | NPC бесплатных профессий |
| `.npcvweapon` | NPC визуала оружия |
| `.npcallmount` | NPC всех маунтов |
| `.npcbuff` | NPC баффов |
| `.npcenchant` | NPC зачарования |
| `.npclottery` | NPC-лотерея |
| `.npcguild` | NPC гильдейского дома |
| `.npctalent` | NPC шаблонов талантов |
| `.npcracial` | NPC смены расовых способностей |
| `.npcbank` | NPC банка реагентов |
| `.bank` | открыть банк в любом месте |
| `.buff` | наложить баффы |
| `.repairall` | починить всю экипировку |
| `.resetid` | сбросить привязки к инстансам |
| `.ga` | ставки добычи (gather rates) |
| `.chat <текст>` | объявление в мировой чат |

Плюс NPC-спавны из сборки: `190000` Portal Master, `60011` Enchanter, `90000` Hardcore NPC.

## Вкладка «Себя»

**GM-режим:** `.gm on|off`, `.gmchat`, `.gm ingame`, `.gm visible on|off`, `.gm fly on|off`
**Читы:** `.cheat god|power|casttime|cooldown|waterwalk|taxi|status|talent on|off`
**Состояния:** `.revive`, `.die`, `.aura 546` / `.unaura 546` / `.unaura all`,
`.cooldown clear`, `.combatstop`, `.explorecheat 1`, `.maxskill`,
`.modify hp|mana|drunk <значение>`
**Скорость:** `.modify speed all|walk|flight|swim <rate>`
**Размер:** `.modify scale <значение>`, `.modify reputation <id> <значение>`

## Вкладка «Персонаж»

**Уровни и таланты:** `.levelup <±N>`, `.reset talents|spells|pet talents`, `.cheat talent on`
**Раса/фракция/имя (Custom Races):** `.character changerace|changefaction|rename|customize|level|titles`
**Изучение:** `.learn all_myclass|all_myspells|all_mytalents|all_recipes|all_lang|all_gm`,
`.learn <id>`, `.unlearn <id>`, `.setskill <skill level max>`, `.maxskill`, `.repairitems`
**Деньги:** `.modify money <медь>`, `.modify honor <N>`, `.modify arena <N>`
**Предметы:** `.additem <id> [кол-во]`, `.additemset <id>`, `.lookup item <текст>`,
`.send items <ник> "<тема>" "<текст>" <id>:<кол>`, `.send money <ник> <медь>`

## Вкладка «Группа»

`.die`, `.revive`, `.freeze`, `.unfreeze`, `.recall`, `.groupsummon`, `.combatstop`,
`.unaura all`, `.appear <ник>`, `.summon <ник>`, `.pinfo <ник>`, `.kick <ник>`,
`.send message <ник> <текст>`

## Вкладка «Сервер»

**Инфо:** `.server info`, `.gps`, `.account`, `.who`, `.gm ingame`, `.gm list`
**Игроки и доступ:** `.kick`, `.mute`, `.unmute`, `.ban character|account <кто> <дни> <причина>`,
`.unban character|account`, `.ban list`, `.ban info character <ник>`, `.send items`
**Обслуживание:** `.save`, `.saveall`, `.reload config`,
`.server shutdown cancel`, `.server restart cancel`
**Опасное (с подтверждением):** `.server restart|shutdown <сек>`
**Сообщения:** `.announce <текст>`, `.server set motd <текст>`
**Аккаунты:** `.account create <логин:пароль>`, `.account password <логин:старый:новый>`

## Вкладка «Свои»

Любые свои команды: ЛКМ — выполнить, ПКМ — изменить / переместить / удалить.
Хранятся в `AdminToolsDB.custom`.

---

## Чего в панели пока нет (но есть на сервере)

Эти команды есть в ядре/модулях, но кнопок для них нет — можно добавить в «Свои» или
попросить меня вынести на вкладку:

| Команда | Зачем |
|---|---|
| `.npcbot unbind <спелл>` | временно снять у бота конкретный спелл |
| `.npcbot dump write <файл>` | резервная копия ботов в SQL |
| `.npcbot createnew <имя> <класс> <раса> ...` | создать нового бота (нужны визуальные параметры) |
| `.npcbot wp add/move` | точки блуждания |
| `.character deleted list/restore` | восстановление удалённых персонажей |
| `.modify phase`, `.modify gender`, `.modify mount` | тонкая правка персонажа |
| `.mail`, `.pinfo` подробнее | почта и детали игрока |
| `.server set loglevel`, `.server debug` | отладка сервера |
| `.quest add/complete`, `.quest reward` | работа с квестами |
| `.event start/stop`, `.event list` | мировые события |
| `.wp add/load` | путевые точки для NPC |

Скажи, какие из них нужны — вынесу на вкладки с проверкой формата аргументов.
