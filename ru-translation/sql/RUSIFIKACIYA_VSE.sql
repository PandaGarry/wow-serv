-- =====================================================================
-- RUSIFIKACIYA_VSE.sql — вся русификация одним файлом (01..05).
-- База: acore_world. Перед применением остановите worldserver и сделайте бэкап.
-- =====================================================================
SET NAMES utf8mb4;


-- ---------------- 01_npcbots_npc_text_locale_ruRU.sql ----------------
DELETE FROM `npc_text_locale` WHERE `Locale`='ruRU' AND `ID` BETWEEN '70000' AND '71000';
INSERT INTO `npc_text_locale` (`ID`, `Locale`, `Text0_0`, `Text0_1`, `Text1_0`, `Text1_1`, `Text2_0`, `Text2_1`, `Text3_0`, `Text3_1`, `Text4_0`, `Text4_1`, `Text5_0`, `Text5_1`, `Text6_0`, `Text6_1`, `Text7_0`, `Text7_1`)
VALUES
('70001', 'ruRU', 'Я живу только для того, чтобы служить хозяину!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70002', 'ruRU', 'Тебе что-то нужно?', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70003', 'ruRU', 'Смертные... обычно я убиваю тварей вроде тебя как только увижу!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70004', 'ruRU', '<Перед вами, похоже, обсидиановый разрушитель. Этот, впрочем, выглядит иначе, поврежденный и поблекший, он не реагирует на ваше присутствие. Вам помнится Плеть когда-то давно использовала таких. Как, черт возьми, он оказался здесь? При дальнейшем осмотре вы замечаете щель на его спине.>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70005', 'ruRU', '<Обсидиановый Разрушитель смотрит на вас и издает глубокий рычащий звук.>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70006', 'ruRU', 'Ты удивлен, смертный? Как низший натрезим, я вынужден прибегать к поиску союзников. Ты выглядишь так, будто сможешь меня хотя бы развлечь.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70007', 'ruRU', 'Ну что ещё, смертный?', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70008', 'ruRU', 'Ты можешь просто оставить меня в покое? <вздох>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70009', 'ruRU', 'Что теперь?', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70010', 'ruRU', '<Вы видите истощенную предводительницу наг. Она выглядит усталой и слабой, и пытается не смотреть на вас.>$B$BНе нуж-жно с-с-слов, с-с-смертный...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70011', 'ruRU', 'У меня опять что-то не так с-с причёс-ской? <Она расчесывает свои "волосы">$B... Нет, вс-сё в порядке. Так в чём же дело?', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70101', 'ruRU', '|cffff3300Мастер Клинка|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B"Элитный мечник, бывший член клана Пылающего Клинка, ныне элитный воин ​​Орды".$B$BОсновная характеристика: Ловкость.$B$BПуть Пустоты (Прогулка с ветром). Позволяет Мастеру клинка становиться невидимым и двигаться быстрее в течение определенного времени. Если Мастер клинка атакует врага, выходя из невидимости, он наносит дополнительный урон.$B$BЗеркальное изображение. Сбивает противника с толку, создавая иллюзию Мастера клинка и рассеивая всю магию Мастера клинка.$B$BКритический удар (пассивный). Дает 15% шанс нанести критический урон в 2(3,4) раза больше обычного при атаках.$B$BВихрь клинков (NIY). Дает иммунитет к магии и наносит урон всем окружающим врагам.$B$B', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70102', 'ruRU', '|cff9900ccОбсидиановый Разрушитель|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B"Крылатое чудовище из обсидиана, обладающее ненасытной жаждой магии".$B$BКрепкая броня, очень высокое сопротивление, частичный иммунитет к магии, постоянно теряет ману, пассивные эффекты регенерации маны для него бесполезны, кольчужная/латная броня, использует жезлы в обоих руках, наносит урон темной магией, нет физической атаки, не может атаковать во время перемещения, бонус к силе заклинаний: 50% силы атаки + 200% интеллекта + урон жезлов.$B$BПожирание магии. Снимает до 2 магических эффектов с врагов, до 2 магических эффектов и до 2 проклятий с союзников и наносит урон призванным юнитам в радиусе 20 м. Каждый развеянный эффект восстанавливает 20% маны и 5% здоровья, время восстановления 7 секунд.$B$BТеневой взрыв. Усиленная атака, наносящая повышенный урон по площади.$B$BВытягивание маны. Вытягивает всю ману (ограниченную запасом маны заклинателя) из случайного дружественного юнита.$B$BПополнить запасы маны. Восполняет манну окружающим участникав группы и рейда в радиусе 25 ярдов на 3% от их максимального запаса, сводя на нет ману заклинателя, время восстановления 3 секунды.$B$BАура восстановления. Исцеляет окружающих членов группы и рейда в радиусе 25 м на 3% от их максимального запаса здоровья, сводя на нет ману заклинателя, время восстановления 3 секунды.$B$BТемная броня (пассивная). Восстанавливает ману в размере процента от полученного урона.$B$B', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70103', 'ruRU', '|cff0000ddАрхимаг|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B Получаемый урон от заклинаний уменьшен на 35%, частично невосприимчив к эффектам контроля, тканевая броня, наносит урон от магии огня/льда, нет физической атаки, бонус к силе заклинаний: 100% интеллекта. Основная характеристика: Интеллект.$B$BСнежная буря. Обычная снежная буря, только немного мощнее, время восстановления 6 секунд.$B$BПризыв элементаля воды. Призывает элементаля воды, который атакует врагов архимага. Время восстановления: 1 мин., 20 сек.$B$BАура великолепия. Увеличивает максимальный запас маны на 10% и значительно увеличивает регенерацию маны участников группы и рейда в радиусе 40 м.$B$BM Массовая телепортация. NIY.$B$B', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70104', 'ruRU', '|cff9900ccПовелитель Ужаса|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B"Невероятно могущественный демон, владеющий силами тьмы и управления разумом".$B$BКрепкая броня, высокое сопротивление, частичная невосприимчивость к эффектам контроля, получаемый урон ускоряет перезарядку заклинаний, латная броня, наносит урон в ближнем бою а также урон от темной магии, дополнительный урон по целям выведенным из равновесия, бонус к силе заклинаний: 200% силы. Основная характеристика: Сила.$B$BТемная Стая. Посылает стаю летучих мышей наносящих урон от магии в конусе перед собой, не может нанести критический урон, время восстановления 10 секунд.$B$BСон. Погружает вражескую цель в сон на 60 секунд и позволяет при наненсения урона следующей физической атаке этой цели игнорировать ее броню, нанесенный прямой урон пробудит цель, время восстановления 6 секунд.$B$BАура вампиризма. Увеличивает физический критический урон на 5% и исцеляет членов группы и рейда в радиусе 40 м в процентном соотношении (100% для Повелителя ужаса и 25% для всех остальных) от урона, нанесенного физическими атаками в ближнем бою и Темной Стаей, без угрозы.$B$BПризыв Инфернала. Призывает инфернала с неба на 180 секунд, нанося урон и оглушая врагов, инфернал очень устойчив к магии, время восстановления 180 секунд.$B$B', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70105', 'ruRU', '|cff0000ddРазрушитель Заклинаний|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B"Эльфийский воин, специально обученный разрушать и искажать магию".$B$BУрон, получаемый от заклинаний, уменьшен на 75%, частично невосприимчив к эффектам контроля, штраф за броню -30%, кольчужная/латная броня, наносит урон в ближнем бою и урон от тайной магии, бонус к силе заклинаний: 200% силы. Основная характеристика: Сила.$B$BПохищение Магии. Похищает полезное заклинание у врага и передаёт его ближайшему союзнику или снимает отрицательное заклинание с союзника на ближайшего врага, влияет на эффекты магии и проклятия, время восстановления 2 секунды.$B$BСожжение Маны (пассивная). Успешные атаки ближнего боя сжигают ману цели, равную нанесенному урону (увеличенному силой заклинаний), нанося урон от тайной магии. Если мана цели исчерпана, атаки ближнего боя Разрушителя Заклинаний будут наносить тройной урон с повышенным шансом критического удара. Если у цели нет маны, Разрушитель Заклинаний восполнит ману в количестве 25% от нанесенного урона.$B$B', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70106', 'ruRU', '|cff9900ccТемная Охотница|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B"Бывшая охотница Кель\'Таласа, насильно возвращённая из мира мёртвых".$B$B Получаемый урон от заклинаний уменьшен на 35%, нежить, частично невосприимчива к эффектам контроля, кожаная/тканевая броня, наносит физический урон/урон от темной магии, придерживается теней и не генерирует угрозы, бонус к силе заклинаний: 50% интеллекта. Основное характеристика: Ловкость.$B$BБезмолвие. Заставляет врага и до 4 его ближайших друзей замолчать на 8 секунд, теряя возможность применять заклинания, время восстановления 15 секунд.$B$BЧерная стрела. Выпускает проклятую стрелу, наносящую 150% урона от оружия и дополнительный урон от темной магии каждые несколько секунд. Если цель умирает от урона Темной Охотницы, она превратится в Тёмного Приспешника (максимум 5 приспешников, продолжительность 80 секунд, срабатывает только на гуманоидах, зверях и драконах). Наносит пятикратный урон, если у цели меньше 20% здоровья.$B$Bпохищение Жизни. Высасывает здоровье врага каждую секунду в течение 5 секунд, исцеляя Темную Охотницу на 200% от похищенного количества.$B$B', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70107', 'ruRU', '|cff9900ccНекромант|r$b|cffdd6600-=отсылка к Warcraft III / Diablo II=-|r$B$BПолучаемый урон от заклинаний уменьшен на 20%, частично невосприимчив к эффектам контроля, тканевая броня, наносит урон от темной магии, нет физической атаки, бонус к силе заклинаний: интеллект 100%. Основная характеристика: Интеллект.$B$BВоскрешение Мертвых. Поднимает 2 скелета из трупа (максимум 6 скелетов, продолжительность 65 секунд, работает только с гуманоидами, зверями и драконами).$B$BНечестивое Бешенство. Увеличивает скорость атаки цели в ближнем бою на 75%, но постоянно истощает здоровье. Длится 45 секунд. Не может быть отменено. Разблокируется на 30 уровне.$B$BВзрыв Трупа. Заставляет труп взорваться, нанося урон в размере от 35% до 75% от максимального здоровья мертвого существа (зависит от уровня Некроманта) всем окружающим врагам. Этот урон не генерирует угрозы. Разблокируется на 40 уровне.$B$BУвечье. Снижает скорость передвижения цели, скорость атаки в ближнем бою и общую силу на 50% на 60 секунд. Разблокируется на уровне 50.$B$B', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70108', 'ruRU', '|cff0000ddМорская Ведьма|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B"Грозная колдунья наг, часто ассоциирующаяся с приходом ужасных штормов".$B$BПолучаемый урон от заклинаний уменьшен на 30%, частично невосприимчив к эффектам контроля, тканевая броня, наносит физический урон/урон от магии льда, бонус к силе атаки: ловкость x2, бонус к силе заклинаний: 200% к интеллекту. Основная характеристика: Интеллект.$B$BРаздвоенная молния. Вызывает разветвлённую молнию, наносящую урон врагам. Поражает от 2 до всех целей (в зависимости от уровня Морской Ведьмы), оглушая их на 2 секунды. Этот урон не создает угрозы.$B$BЛедяные Стрелы. Наполняет стрелу магическим морозом для дополнительного урона, снижая скорость движения цели, скорость атаки и произнесения заклинаний на 30-70% (в зависимости от уровня Морской ведьмы).$B$BЩит Маны. Создает щит, который поглощает 100% входящего (не смягченного) урона, используя ману Морской Ведьмы. Эффект варьируется от 1 единицы урона за 10 единиц маны до 10 единиц урона за 1 единицу ману (в зависимости от уровня Морской Ведьмы).$B$BТорнадо. Вызывает яростный торнадо, который наносит урон и замедляет ближайших врагов, иногда полностью выводя их из строя. На открытом пространстве Торнадо со временем разрастается, увеличивая наносимый урон и область действия, но в закрытом помещении уменьшается и быстро рассеивается. Разблокируется на уровне 60.$B$BНага (пассивный эффект). Скорость плавания, урон и шанс уклонения значительно увеличиваются в воде.$B$B', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70201', 'ruRU', 'Всегда найдутся чуваки, готовые убить за деньги.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70202', 'ruRU', 'Наёмники востребованы всегда. Вот кто доступен прямо сейчас.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70203', 'ruRU', 'Наёмники востребованы всегда. Вот кто доступен прямо сейчас.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70204', 'ruRU', 'Похоже сейчас никого нет, проверь позже.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70300', 'ruRU', 'Умри!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70301', 'ruRU', 'Воскрешаю тебя', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70302', 'ruRU', 'Воскрешаю ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70303', 'ruRU', 'твой бот', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70304', 'ruRU', ' бот', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70305', 'ruRU', 'Я пока не могу применить заклинание создания воды', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70306', 'ruRU', 'Я пока не могу применить заклинание создания еды', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70307', 'ruRU', 'Я не могу сделать это сейчас', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70308', 'ruRU', 'Во-о-от...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70309', 'ruRU', 'Отключено', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70310', 'ruRU', 'Ещё не готово', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70311', 'ruRU', 'Неверный тип объекта', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70312', 'ruRU', 'Не удалось', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70313', 'ruRU', 'Готово', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70314', 'ruRU', 'Я не изменил форму', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70315', 'ruRU', 'У меня нет камня здоровья', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70316', 'ruRU', 'Я пока не могу создавать камни здоровья!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70317', 'ruRU', 'WTF у меня нет отмычек!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70318', 'ruRU', 'Мой уровень навыка недостаточно высок', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70319', 'ruRU', 'Меняю специализацию на ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70320', 'ruRU', 'Оружие', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70321', 'ruRU', 'Неистовство', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70322', 'ruRU', 'Защита', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70323', 'ruRU', 'Воздаяние', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70324', 'ruRU', 'Повелитель зверей', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70325', 'ruRU', 'Стрельба', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70326', 'ruRU', 'Выживание', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70327', 'ruRU', 'Ликвидация', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70328', 'ruRU', 'Бой', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70329', 'ruRU', 'Скрытность', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70330', 'ruRU', 'Послушание', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70331', 'ruRU', 'Свет', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70332', 'ruRU', 'Тьма', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70333', 'ruRU', 'Кровь', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70334', 'ruRU', 'Лёд', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70335', 'ruRU', 'Нечестивость', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70336', 'ruRU', 'Стихии', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70337', 'ruRU', 'Совершенствование', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70338', 'ruRU', 'Исцеление', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70339', 'ruRU', 'Тайная магия', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70340', 'ruRU', 'Огонь', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70341', 'ruRU', 'Колдовство', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70342', 'ruRU', 'Демонология', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70343', 'ruRU', 'Разрушение', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70344', 'ruRU', 'Баланс', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70345', 'ruRU', 'Сила зверя', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70346', 'ruRU', 'Неизвестно', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70347', 'ruRU', 'Проваливай, слабак', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70348', 'ruRU', ' не убеждён', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70349', 'ruRU', 'Я не собираюсь тратить свое время на всякую ерунду', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70353', 'ruRU', 'Я готов', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70354', 'ruRU', 'Уходи. Я служу своему хозяину ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70355', 'ruRU', 'неизвестный', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70356', 'ruRU', ' на тебя!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70357', 'ruRU', ' на себя!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70358', 'ruRU', ' на ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70359', 'ruRU', ' использовано!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70360', 'ruRU', 'бот-танк', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70361', 'ruRU', 'класс', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70362', 'ruRU', 'игрок', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70363', 'ruRU', 'владелец', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70364', 'ruRU', 'никто', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70365', 'ruRU', 'Уровень', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70366', 'ruRU', 'талант', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70367', 'ruRU', 'пассивный', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70368', 'ruRU', 'скрытый', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70369', 'ruRU', 'изучен', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70370', 'ruRU', 'способность', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70371', 'ruRU', 'сила', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70372', 'ruRU', 'ловкость', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70373', 'ruRU', 'выносливость', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70374', 'ruRU', 'интеллект', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70375', 'ruRU', 'дух', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70376', 'ruRU', 'неизвестный стат', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70377', 'ruRU', 'всего', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70378', 'ruRU', 'Сила атаки ближний бой', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70379', 'ruRU', 'Сила атаки дальний бой', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70380', 'ruRU', 'броня', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70381', 'ruRU', 'крит', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70382', 'ruRU', 'защита', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70383', 'ruRU', 'промах', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70384', 'ruRU', 'уклонение', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70385', 'ruRU', 'парирование', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70386', 'ruRU', 'блок', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70387', 'ruRU', 'показатель блокирования', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70388', 'ruRU', 'Получаемый урон в ближнем бою', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70389', 'ruRU', 'Получаемый урон от заклинаний', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70390', 'ruRU', 'Разброс урона оружия в правой руке', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70391', 'ruRU', 'Множитель урона оружия в правой руке', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70392', 'ruRU', 'Скорость атаки оружием в правой руке', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70393', 'ruRU', 'Разброс урон оружия в левой руке', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70394', 'ruRU', 'Множитель урона оружия в левой руке', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70395', 'ruRU', 'Скорость атаки оружием в левой руке', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70396', 'ruRU', 'Разброс урона оружия дальнего боя', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70397', 'ruRU', 'Множитель урона оружия дальнего боя', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70398', 'ruRU', 'Скорость атаки оружием дальнего боя', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70399', 'ruRU', 'минимум', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70400', 'ruRU', 'максимум', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70402', 'ruRU', 'базовый уровень здоровья', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70403', 'ruRU', 'всего здоровья', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70404', 'ruRU', 'базовый уровень маны', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70405', 'ruRU', 'всего маны', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70406', 'ruRU', 'текущий запас маны', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70407', 'ruRU', 'сила заклинаний', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70408', 'ruRU', 'бонус регенерации здоровья_5', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70409', 'ruRU', 'регенерация маны_5 без использования заклинания', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70410', 'ruRU', 'регенерация маны_5 при использовании заклинания', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70411', 'ruRU', 'скорость', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70412', 'ruRU', 'меткость', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70413', 'ruRU', 'мастерство', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70414', 'ruRU', 'пробивание брони', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70415', 'ruRU', 'проникновение заклинаний', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70416', 'ruRU', 'проц.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70417', 'ruRU', 'святлая магия', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70418', 'ruRU', 'магия огня', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70419', 'ruRU', 'силы природы', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70420', 'ruRU', 'магия льда', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70421', 'ruRU', 'темная магия', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70422', 'ruRU', 'тайная магия', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70423', 'ruRU', 'Сопротивление', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70424', 'ruRU', 'Состояния команд', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70425', 'ruRU', 'Следовать', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70426', 'ruRU', 'Атаковать', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70427', 'ruRU', 'Стоять', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70428', 'ruRU', 'Сброс', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70429', 'ruRU', 'Полная остановка', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70430', 'ruRU', 'Дистанция следования', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70431', 'ruRU', 'Специализация', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70432', 'ruRU', 'Маска ролей ботов (главная)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70433', 'ruRU', 'Маска ролей ботов (сбор)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70434', 'ruRU', 'PvP-убийства', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70435', 'ruRU', 'игроки', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70436', 'ruRU', 'Умер ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70437', 'ruRU', ' раз', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70438', 'ruRU', '%s (бот) успокаивается', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70439', 'ruRU', '<Отладка>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70440', 'ruRU', 'Вы уверены, что хотите рискнуть, привлекая внимание ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70441', 'ruRU', '?', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70442', 'ruRU', '<Вставить монету>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70443', 'ruRU', 'Вы хотите приманить ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70444', 'ruRU', '<Попробовать сделать подношение>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70445', 'ruRU', 'Вы хотите нанять ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70446', 'ruRU', '<Нанять бота>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70447', 'ruRU', 'Снаряжение...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70448', 'ruRU', 'Роли...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70449', 'ruRU', 'Построение...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70450', 'ruRU', 'Способности...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70451', 'ruRU', 'Специализация...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70452', 'ruRU', 'Дать использовать...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70453', 'ruRU', '<Создать группу>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70454', 'ruRU', '<Создать группу (все боты)>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70455', 'ruRU', '<Добавить в группу>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70456', 'ruRU', '<Добавить всех ботов в группу>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70457', 'ruRU', '<Удалить из группы>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70458', 'ruRU', 'Следуй за мной', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70459', 'ruRU', 'Удерживай позицию', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70460', 'ruRU', 'Стой здесь и ничего не делай', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70461', 'ruRU', 'Мне нужна еда', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70462', 'ruRU', 'Мне нужна вода', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70463', 'ruRU', 'Мне нужен стол с едой', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70464', 'ruRU', 'Помоги мне взломать замок', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70465', 'ruRU', 'Мне нужен камень здоровья', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70466', 'ruRU', 'Мне нужен источник душ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70467', 'ruRU', 'Мне нужно, чтобы ты обновил яды', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70468', 'ruRU', '<Выберите яд (правая рука)>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70469', 'ruRU', '<Выберите яд (левая рука)>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70470', 'ruRU', 'Мне нужно, чтобы ты обновил чары', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70471', 'ruRU', '<Выберите чары (правая рука)>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70472', 'ruRU', '<Выберите чары (левая рука)>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70473', 'ruRU', 'Мне нужно, чтобы ты вышел из формы', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70474', 'ruRU', '<Выбрать тип питомца>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70475', 'ruRU', 'Свободен отсюда', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70476', 'ruRU', 'Вы действительно хотите уволить ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70477', 'ruRU', 'Вы можете пожалеть об этом...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70478', 'ruRU', 'Соберись, тряпка', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70479', 'ruRU', '<Рассмотреть существо>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70480', 'ruRU', 'Ладно, не важно', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70481', 'ruRU', 'дист.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70482', 'ruRU', 'НАЗАД', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70483', 'ruRU', '<Авто>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70484', 'ruRU', '<Нет>', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70485', 'ruRU', 'Случайный (Хитрость)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70486', 'ruRU', 'Случайный (Свирепость)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70487', 'ruRU', 'Случайный (Упорство)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70488', 'ruRU', 'Покажи мне свой инвентарь', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70489', 'ruRU', 'Автовыбор', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70490', 'ruRU', 'Правая рука', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70491', 'ruRU', 'Левая рука', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70492', 'ruRU', 'Дальний бой', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70493', 'ruRU', 'Реликвия', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70494', 'ruRU', 'Голова', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70495', 'ruRU', 'Плечи', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70496', 'ruRU', 'Грудь', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70497', 'ruRU', 'Пояс', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70498', 'ruRU', 'Ноги', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70499', 'ruRU', 'Ступни', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70500', 'ruRU', 'Запястья', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70501', 'ruRU', 'Кисти рук', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70502', 'ruRU', 'Спина', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70503', 'ruRU', 'Рубашка', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70504', 'ruRU', 'Палец1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70505', 'ruRU', 'Палец2', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70506', 'ruRU', 'Аксессуар1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70507', 'ruRU', 'Аксессуар2', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70508', 'ruRU', 'Шея', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70509', 'ruRU', 'Снять все', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70510', 'ruRU', 'Обновить внешний вид', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70511', 'ruRU', 'только внешний вид', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70512', 'ruRU', 'Надето', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70513', 'ruRU', 'ничего', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70514', 'ruRU', 'Используй свое старое cнаряжение', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70515', 'ruRU', 'Снять', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70516', 'ruRU', 'Хм... мне нечего тебе дать', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70517', 'ruRU', 'Сбор ингредиентов', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70518', 'ruRU', 'Статус способностей', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70519', 'ruRU', 'Разрешённые способности', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70520', 'ruRU', 'Используй ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70521', 'ruRU', 'Обновить', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70522', 'ruRU', 'Урон', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70523', 'ruRU', 'Контроль', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70524', 'ruRU', 'Лечение', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70525', 'ruRU', 'Другое', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70526', 'ruRU', ' издает скрежет и начинает следовать за ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70527', 'ruRU', '%s не присоединится к вам, пока владелец не уволит', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70528', 'ruRU', '%s не присоединится к вам, пока вы не достигнете 60-го уровня', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70529', 'ruRU', '%s не присоединится к вам, пока вы не достигнете 55-го уровня', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70530', 'ruRU', '%s не присоединится к вам, пока вы не достигнете 40-го уровня', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70531', 'ruRU', '%s не присоединится к вам, пока вы не достигнете 20-го уровня', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70532', 'ruRU', 'Вы превысили максимальное количество ботов (%u)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70533', 'ruRU', 'У вас недостаточно денег', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70534', 'ruRU', 'У вас не может быть больше ботов этого класса! %u из %u', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70535', 'ruRU', 'Не удается сбросить снаряжение в слоте %u (%s)! Не могу уволить бота!', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70536', 'ruRU', 'сейчас', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70537', 'ruRU', 'Дистанция атаки', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70538', 'ruRU', 'Короткая дистанция', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70539', 'ruRU', 'Длинная дистанция', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70540', 'ruRU', 'Заданная', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70541', 'ruRU', 'Снять бафф', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70542', 'ruRU', 'Исправь тип энергии', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70543', 'ruRU', 'Не могу снять %s по какой-то идиотской причине! Отправляю по почте', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70544', 'ruRU', 'Танк', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70545', 'ruRU', 'Дальний бой', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70546', 'ruRU', 'Горное дело', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70547', 'ruRU', 'Травничество', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70548', 'ruRU', 'Снятие шкур', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70549', 'ruRU', 'Инженерное дело', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70550', 'ruRU', 'Срок владения ботом истек из-за бездействия', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70551', 'ruRU', 'Система NpcBot в данный момент отключена. Пожалуйста, обратитесь к администратору', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70552', 'ruRU', '%s не присоединится к вам, уже есть владелец: %s', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70553', 'ruRU', '%s не может присоединиться к вам: телепортируется', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70554', 'ruRU', 'Дух', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70555', 'ruRU', 'Обезьяна', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70556', 'ruRU', 'Ястреб', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70557', 'ruRU', 'Гепард', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70558', 'ruRU', 'Гадюка', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70559', 'ruRU', 'Зверь', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70560', 'ruRU', 'Стая', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70561', 'ruRU', 'Дикий', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70562', 'ruRU', 'Дракондор', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70563', 'ruRU', 'Нет духа', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70564', 'ruRU', 'Аура', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70565', 'ruRU', 'Благочестие', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70566', 'ruRU', 'Сосредоточенность', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70567', 'ruRU', 'Защита от огня', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70568', 'ruRU', 'Защита от магии льда', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70569', 'ruRU', 'Защита от темной магии', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70570', 'ruRU', 'Воздаяние', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70571', 'ruRU', 'Воин света', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70572', 'ruRU', 'Нет ауры', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70573', 'ruRU', 'Калечащий', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70574', 'ruRU', 'Быстродействующий', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70575', 'ruRU', 'Смертельный', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70576', 'ruRU', 'Нейтрализующий', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70577', 'ruRU', 'Дурманящий', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70578', 'ruRU', 'Анестезирующий', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70579', 'ruRU', 'Ничего', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70580', 'ruRU', 'Языки пламени', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70581', 'ruRU', 'Ледяное клеймо', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70582', 'ruRU', 'Неистовство ветра', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70583', 'ruRU', 'Жизнь земли', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70584', 'ruRU', 'Мне нужны твои услуги', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70585', 'ruRU', 'У тебя слишком много ботов', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70586', 'ruRU', 'Вы хотите нанять ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70587', 'ruRU', ' сейчас немного занят, повторите попытку позже.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70588', 'ruRU', 'Приятно иметь с тобой дело', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70589', 'ruRU', 'Воины', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70590', 'ruRU', 'Паладины', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70591', 'ruRU', 'Маги', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70592', 'ruRU', 'Жрецы', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70593', 'ruRU', 'Чернокнижники', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70594', 'ruRU', 'Друиды', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70595', 'ruRU', 'Рыцари Смерти', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70596', 'ruRU', 'Разбойники', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70597', 'ruRU', 'Шаманы', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70598', 'ruRU', 'Охотники', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70599', 'ruRU', 'Мастера Клинка', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70600', 'ruRU', 'Разрушители', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70601', 'ruRU', 'Архимаги', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70602', 'ruRU', 'Повелители Ужаса', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70603', 'ruRU', 'Разрушители Заклинаний', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70604', 'ruRU', 'Тёмные Охотницы', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70605', 'ruRU', 'Воин', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70606', 'ruRU', 'Паладин', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70607', 'ruRU', 'Маг', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70608', 'ruRU', 'Жрец', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70609', 'ruRU', 'Чернокнижник', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70610', 'ruRU', 'Друид', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70611', 'ruRU', 'Рыцарь смерти', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70612', 'ruRU', 'Разбойник', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70613', 'ruRU', 'Шаман', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70614', 'ruRU', 'Охотник', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70615', 'ruRU', 'Мастер Клинка', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70616', 'ruRU', 'Разрушитель', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70617', 'ruRU', 'Архимаг', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70618', 'ruRU', 'Повелитель Ужаса', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70619', 'ruRU', 'Разрушитель Заклинаний', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70620', 'ruRU', 'Темная Охотница', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70621', 'ruRU', 'Мужчина', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70622', 'ruRU', 'Женщина', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70623', 'ruRU', 'Человек', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70624', 'ruRU', 'Орк', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70625', 'ruRU', 'Гном', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70626', 'ruRU', 'Ночной эльф', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70627', 'ruRU', 'Нежить', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70628', 'ruRU', 'Таурен', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70629', 'ruRU', 'Гном', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70630', 'ruRU', 'Тролль', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70631', 'ruRU', 'Эльф крови', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70632', 'ruRU', 'Дреней', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70633', 'ruRU', 'Неизвестно', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70634', 'ruRU', 'Сбор добычи', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70635', 'ruRU', '|cff9d9d9dПлохой|r', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70636', 'ruRU', '|cffffffffОбычный|r', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70637', 'ruRU', '|cff1eff00Необычный|r', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70638', 'ruRU', '|cff0070ddРедкий|r', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70639', 'ruRU', '|cffa335eeЭпический|r', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70640', 'ruRU', '|cffff8000Легендарный|r', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70641', 'ruRU', 'Активное действие', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70642', 'ruRU', 'Задержка атаки на', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70643', 'ruRU', 'Задержка лечения на', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70644', 'ruRU', 'с', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70645', 'ruRU', 'Off-танк (второй танк)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70646', 'ruRU', 'Некроманты', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70647', 'ruRU', 'Некромант', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70648', 'ruRU', 'Позиционирование в дальнем бою', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70649', 'ruRU', 'Обычное', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70650', 'ruRU', 'Избегать фронтального АОЕ', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70652', 'ruRU', 'Вы уверены, что это сработает? Это должна быть самая лучшая вода в мире...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70653', 'ruRU', 'Похоже, тебе не помешает хороший глоток свежей воды.', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70654', 'ruRU', 'Морские Ведьмы', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70655', 'ruRU', 'Морская Ведьма', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70656', 'ruRU', 'Маны на единицу урона', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70657', 'ruRU', 'Урона на еденицу маны', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('70658', 'ruRU', 'Трансмогрификация...', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


-- ---------------- 02_npcbots_npc_text_dop.sql ----------------
-- =====================================================================
-- Боты NPCBots: недостающие фразы и пункты меню
-- База: acore_world. Таблица: npc_text_locale. Сгенерировано tools/gen.py
-- Перед применением остановите worldserver. Файл можно применять повторно.
-- =====================================================================
SET NAMES utf8mb4;

DELETE FROM `npc_text_locale` WHERE `Locale`='ruRU' AND `ID` IN (70012,70013,70109,70350,70351,70352,70401,70651,70659,70660,70661,70662,70663,70664,70665,70666,70667,70668,70669,70670,70671,70672,70673,70674,70675,70676,70677,70678,70679,70680,70681,70682,70683,70684,70685,70686,70687,70688,70689,70690,70691,70692,70693,70694,70695,70696,70697,70698,70699,70700);
INSERT INTO `npc_text_locale` (`ID`, `Locale`, `Text0_0`, `Text0_1`) VALUES
(70012, 'ruRU', '<Перед вами стоит израненный в боях Повелитель Склепов, явно никем не контролируемый. Лишившись хозяина, этот могучий неруб-нежить утратил большую часть своей силы.>$B$BНу и что же ты такое, крошечное создание? Твоя плоть сгодится, как и любая другая...', '<Перед вами стоит израненный в боях Повелитель Склепов, явно никем не контролируемый. Лишившись хозяина, этот могучий неруб-нежить утратил большую часть своей силы.>$B$BНу и что же ты такое, крошечное создание? Твоя плоть сгодится, как и любая другая...'),
(70013, 'ruRU', 'Я пожираю и живых, и мёртвых.', 'Я пожираю и живых, и мёртвых.'),
(70109, 'ruRU', '|cff9900ccПовелитель Склепов|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B"Древний исполин, некогда один из королей Азжол-Неруба, а ныне чудовище-нежить в рядах сильнейших воинов Короля-лича".$B$BОчень высокая броня, повышенное сопротивление, частичная невосприимчивость к эффектам контроля, невосприимчивость к ядам, кольчужная/латная броня, наносит урон в ближнем бою и урон от темной магии, бонус к силе заклинаний: 200% силы. Основная характеристика: Сила.$B$BПронзание. Повелитель Склепов бьёт массивными когтями о землю, выпуская шипы конусом перед собой; они наносят урон, подбрасывают врагов в воздух и оглушают их. Разблокируется на 20 уровне.$B$BШипастый панцирь. Хитиновая броня Повелителя Склепов повышает сопротивление урону и возвращает от 15% до 50% урона врагам, атакующим в ближнем бою.$B$BТрупные жуки. Повелитель Склепов порождает трупного жука из свежего трупа врага, и тот атакует его противников. Жуки существуют постоянно, но не восстанавливают здоровье; одновременно можно управлять только 6 жуками. На более высоких уровнях жуки сильнее. Разблокируется на 10 уровне.$B$BРой саранчи. Повелитель Склепов выпускает рой из 20–40 (зависит от уровня) разъярённых насекомых, которые кусают и рвут ближайших врагов, мешая им двигаться и атаковать. Пожирая плоть врагов, саранча превращает её в вещество, которое по возвращении восстанавливает здоровье Повелителю Склепов. Разблокируется на 40 уровне.$B$B', '|cff9900ccПовелитель Склепов|r$b|cffdd6600-=отсылка к Warcraft III=-|r$B$B"Древний исполин, некогда один из королей Азжол-Неруба, а ныне чудовище-нежить в рядах сильнейших воинов Короля-лича".$B$BОчень высокая броня, повышенное сопротивление, частичная невосприимчивость к эффектам контроля, невосприимчивость к ядам, кольчужная/латная броня, наносит урон в ближнем бою и урон от темной магии, бонус к силе заклинаний: 200% силы. Основная характеристика: Сила.$B$BПронзание. Повелитель Склепов бьёт массивными когтями о землю, выпуская шипы конусом перед собой; они наносят урон, подбрасывают врагов в воздух и оглушают их. Разблокируется на 20 уровне.$B$BШипастый панцирь. Хитиновая броня Повелителя Склепов повышает сопротивление урону и возвращает от 15% до 50% урона врагам, атакующим в ближнем бою.$B$BТрупные жуки. Повелитель Склепов порождает трупного жука из свежего трупа врага, и тот атакует его противников. Жуки существуют постоянно, но не восстанавливают здоровье; одновременно можно управлять только 6 жуками. На более высоких уровнях жуки сильнее. Разблокируется на 10 уровне.$B$BРой саранчи. Повелитель Склепов выпускает рой из 20–40 (зависит от уровня) разъярённых насекомых, которые кусают и рвут ближайших врагов, мешая им двигаться и атаковать. Пожирая плоть врагов, саранча превращает её в вещество, которое по возвращении восстанавливает здоровье Повелителю Склепов. Разблокируется на 40 уровне.$B$B'),
(70350, 'ruRU', 'Не реализовано', 'Не реализовано'),
(70351, 'ruRU', 'Не реализовано', 'Не реализовано'),
(70352, 'ruRU', 'Не реализовано', 'Не реализовано'),
(70401, 'ruRU', 'Урон (DPS)', 'Урон (DPS)'),
(70651, 'ruRU', 'Не реализовано', 'Не реализовано'),
(70659, 'ruRU', 'ОТКЛЮЧИТЬ боевое позиционирование', 'ОТКЛЮЧИТЬ боевое позиционирование'),
(70660, 'ruRU', 'Приоритетная цель', 'Приоритетная цель'),
(70661, 'ruRU', 'Банк снаряжения ботов...', 'Банк снаряжения ботов...'),
(70662, 'ruRU', 'Положить предметы...', 'Положить предметы...'),
(70663, 'ruRU', 'Забрать предметы...', 'Забрать предметы...'),
(70664, 'ruRU', 'Банк пуст', 'Банк пуст'),
(70665, 'ruRU', 'Предыдущая страница', 'Предыдущая страница'),
(70666, 'ruRU', 'Следующая страница', 'Следующая страница'),
(70667, 'ruRU', 'Вы действительно хотите потратить все эти деньги, чтобы Повелитель Склепов снова начал двигаться?', 'Вы действительно хотите потратить все эти деньги, чтобы Повелитель Склепов снова начал двигаться?'),
(70668, 'ruRU', 'Сомневаюсь, что в нынешнем состоянии ты способен причинить много вреда, но я готов вести тебя и помочь вернуть твою силу.', 'Сомневаюсь, что в нынешнем состоянии ты способен причинить много вреда, но я готов вести тебя и помочь вернуть твою силу.'),
(70669, 'ruRU', 'Повелители Склепов', 'Повелители Склепов'),
(70670, 'ruRU', 'Повелитель Склепов', 'Повелитель Склепов'),
(70671, 'ruRU', 'Отражение', 'Отражение'),
(70672, 'ruRU', 'Саранча', 'Саранча'),
(70673, 'ruRU', 'Порог здоровья цели для лечения', 'Порог здоровья цели для лечения'),
(70674, 'ruRU', 'Мне нужен портал', 'Мне нужен портал'),
(70675, 'ruRU', 'Штормград', 'Штормград'),
(70676, 'ruRU', 'Стальгорн', 'Стальгорн'),
(70677, 'ruRU', 'Дарнас', 'Дарнас'),
(70678, 'ruRU', 'Экзодар', 'Экзодар'),
(70679, 'ruRU', 'Оргриммар', 'Оргриммар'),
(70680, 'ruRU', 'Подгород', 'Подгород'),
(70681, 'ruRU', 'Громовой Утёс', 'Громовой Утёс'),
(70682, 'ruRU', 'Луносвет', 'Луносвет'),
(70683, 'ruRU', 'Шаттрат', 'Шаттрат'),
(70684, 'ruRU', 'Даларан', 'Даларан'),
(70685, 'ruRU', 'Превышен лимит ботов на аккаунт ({} >= {})', 'Превышен лимит ботов на аккаунт ({} >= {})'),
(70686, 'ruRU', '<Применить ко всем ботам>', '<Применить ко всем ботам>'),
(70687, 'ruRU', ' (банк снаряжения)', ' (банк снаряжения)'),
(70688, 'ruRU', 'Недостаточно места в банке снаряжения для %u предмет(ов) (%u / %u)!', 'Недостаточно места в банке снаряжения для %u предмет(ов) (%u / %u)!'),
(70689, 'ruRU', 'Комплекты экипировки', 'Комплекты экипировки'),
(70690, 'ruRU', 'Создать', 'Создать'),
(70691, 'ruRU', 'Удалить', 'Удалить'),
(70692, 'ruRU', 'Надеть', 'Надеть'),
(70693, 'ruRU', 'отсутствует', 'отсутствует'),
(70694, 'ruRU', 'Управление владельцами...', 'Управление владельцами...'),
(70695, 'ruRU', '<Добавить владельца>', '<Добавить владельца>'),
(70696, 'ruRU', 'ВНИМАНИЕ: делясь ботом, вы даёте другому игроку ПОЛНЫЙ контроль над его инвентарём, ролями и всеми остальными настройками (включая право делиться ботом с другими)', 'ВНИМАНИЕ: делясь ботом, вы даёте другому игроку ПОЛНЫЙ контроль над его инвентарём, ролями и всеми остальными настройками (включая право делиться ботом с другими)'),
(70697, 'ruRU', '<Удалить владельца>', '<Удалить владельца>'),
(70698, 'ruRU', 'Превышен лимит владельцев', 'Превышен лимит владельцев'),
(70699, 'ruRU', 'Доступ есть у', 'Доступ есть у'),
(70700, 'ruRU', 'Владелец', 'Владелец');


-- ---------------- 03_suschestva_imena.sql ----------------
-- =====================================================================
-- Имена и подписи ботов, питомцев и кастомных NPC
-- База: acore_world. Таблица: creature_template_locale. Сгенерировано tools/gen.py
-- Перед применением остановите worldserver. Файл можно применять повторно.
-- =====================================================================
SET NAMES utf8mb4;

DELETE FROM `creature_template_locale` WHERE `locale`='ruRU' AND `entry` IN (70000,70001,70002,70003,70004,70005,70006,70007,70008,70009,70010,70011,70012,70013,70014,70015,70016,70017,70018,70019,70020,70021,70022,70023,70024,70025,70026,70027,70028,70029,70030,70031,70032,70033,70034,70035,70036,70037,70038,70051,70052,70053,70054,70055,70056,70057,70058,70059,70060,70061,70062,70063,70064,70065,70066,70067,70068,70069,70070,70071,70072,70073,70074,70101,70102,70103,70104,70105,70106,70107,70108,70109,70110,70111,70112,70113,70114,70115,70116,70117,70118,70119,70120,70121,70122,70123,70124,70125,70126,70127,70128,70129,70130,70131,70132,70133,70134,70135,70136,70137,70138,70139,70151,70152,70153,70154,70155,70156,70157,70158,70159,70160,70161,70162,70163,70164,70165,70166,70167,70168,70169,70170,70171,70172,70173,70174,70175,70176,70177,70178,70179,70180,70181,70201,70202,70203,70204,70205,70206,70207,70208,70209,70210,70211,70212,70213,70214,70215,70216,70217,70218,70219,70220,70221,70222,70223,70224,70225,70226,70227,70228,70229,70230,70231,70232,70233,70234,70235,70236,70237,70238,70239,70240,70251,70252,70253,70254,70255,70256,70257,70258,70259,70260,70261,70265,70267,70268,70301,70302,70303,70304,70305,70306,70307,70308,70309,70310,70311,70312,70313);
INSERT INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`) VALUES
(70000, 'ruRU', 'Lagretta', 'Наёмные боты'),
(70001, 'ruRU', 'Llane', 'Воин (бот)'),
(70002, 'ruRU', 'Thran', 'Воин (бот)'),
(70003, 'ruRU', 'Lyria', 'Воин (бот)'),
(70004, 'ruRU', 'Ander', 'Воин (бот)'),
(70005, 'ruRU', 'Malosh', 'Воин (бот)'),
(70006, 'ruRU', 'Granis', 'Воин (бот)'),
(70007, 'ruRU', 'Kelstrum', 'Воин (бот)'),
(70008, 'ruRU', 'Dannal', 'Воин (бот)'),
(70009, 'ruRU', 'Austil', 'Воин (бот)'),
(70010, 'ruRU', 'Torm', 'Воин (бот)'),
(70011, 'ruRU', 'Sark', 'Воин (бот)'),
(70012, 'ruRU', 'Ker', 'Воин (бот)'),
(70013, 'ruRU', 'Harutt', 'Воин (бот)'),
(70014, 'ruRU', 'Krang', 'Воин (бот)'),
(70015, 'ruRU', 'Frang', 'Воин (бот)'),
(70016, 'ruRU', 'Tarshaw', 'Воин (бот)'),
(70017, 'ruRU', 'Grezz', 'Воин (бот)'),
(70018, 'ruRU', 'Sorek', 'Воин (бот)'),
(70019, 'ruRU', 'Zel\'mak', 'Воин (бот)'),
(70020, 'ruRU', 'Alyissia', 'Воин (бот)'),
(70021, 'ruRU', 'Kyra', 'Воин (бот)'),
(70022, 'ruRU', 'Arias\'ta', 'Воин (бот)'),
(70023, 'ruRU', 'Sildanair', 'Воин (бот)'),
(70024, 'ruRU', 'Chris', 'Воин (бот)'),
(70025, 'ruRU', 'Angela', 'Воин (бот)'),
(70026, 'ruRU', 'Baltus', 'Воин (бот)'),
(70027, 'ruRU', 'Kelv', 'Воин (бот)'),
(70028, 'ruRU', 'Bilban', 'Воин (бот)'),
(70029, 'ruRU', 'Wu', 'Воин (бот)'),
(70030, 'ruRU', 'Ilsa', 'Воин (бот)'),
(70031, 'ruRU', 'Darnath', 'Воин (бот)'),
(70032, 'ruRU', 'Evencane', 'Воин (бот)'),
(70033, 'ruRU', 'Kore', 'Воин (бот)'),
(70034, 'ruRU', 'Ahonan', 'Воин (бот)'),
(70035, 'ruRU', 'Behomat', 'Воин (бот)'),
(70036, 'ruRU', 'Ruada', 'Воин (бот)'),
(70037, 'ruRU', 'Kazi', 'Воин (бот)'),
(70038, 'ruRU', 'Kerra', 'Воин (бот)'),
(70051, 'ruRU', 'Sammuel', 'Паладин (бот)'),
(70052, 'ruRU', 'Bromos', 'Паладин (бот)'),
(70053, 'ruRU', 'Wilhelm', 'Паладин (бот)'),
(70054, 'ruRU', 'Grayson', 'Паладин (бот)'),
(70055, 'ruRU', 'Azar', 'Паладин (бот)'),
(70056, 'ruRU', 'Valgar', 'Паладин (бот)'),
(70057, 'ruRU', 'Beldruk', 'Паладин (бот)'),
(70058, 'ruRU', 'Brandur', 'Паладин (бот)'),
(70059, 'ruRU', 'Arthur', 'Паладин (бот)'),
(70060, 'ruRU', 'Katherine', 'Паладин (бот)'),
(70061, 'ruRU', 'Karman', 'Паладин (бот)'),
(70062, 'ruRU', 'Jesthenis', 'Паладин (бот)'),
(70063, 'ruRU', 'Noellene', 'Паладин (бот)'),
(70064, 'ruRU', 'Aurelon', 'Паладин (бот)'),
(70065, 'ruRU', 'Osselan', 'Паладин (бот)'),
(70066, 'ruRU', 'Ithelis', 'Паладин (бот)'),
(70067, 'ruRU', 'Bachi', 'Паладин (бот)'),
(70068, 'ruRU', 'Baatun', 'Паладин (бот)'),
(70069, 'ruRU', 'Kavaan', 'Паладин (бот)'),
(70070, 'ruRU', 'Tullas', 'Паладин (бот)'),
(70071, 'ruRU', 'Jol', 'Паладин (бот)'),
(70072, 'ruRU', 'Cyssa', 'Паладин (бот)'),
(70073, 'ruRU', 'Pyreanor', 'Паладин (бот)'),
(70074, 'ruRU', 'Rukua', 'Паладин (бот)'),
(70101, 'ruRU', 'Thorgas', 'Охотник (бот)'),
(70102, 'ruRU', 'Ogromm', 'Охотник (бот)'),
(70103, 'ruRU', 'Grif', 'Охотник (бот)'),
(70104, 'ruRU', 'Kragg', 'Охотник (бот)'),
(70105, 'ruRU', 'Kary', 'Охотник (бот)'),
(70106, 'ruRU', 'Holt', 'Охотник (бот)'),
(70107, 'ruRU', 'Urek', 'Охотник (бот)'),
(70108, 'ruRU', 'Lanka', 'Охотник (бот)'),
(70109, 'ruRU', 'Yaw', 'Охотник (бот)'),
(70110, 'ruRU', 'Jen\'shan', 'Охотник (бот)'),
(70111, 'ruRU', 'Thotar', 'Охотник (бот)'),
(70112, 'ruRU', 'Ormak', 'Охотник (бот)'),
(70113, 'ruRU', 'Xor\'juul', 'Охотник (бот)'),
(70114, 'ruRU', 'Sian\'dur', 'Охотник (бот)'),
(70115, 'ruRU', 'Ayanna', 'Охотник (бот)'),
(70116, 'ruRU', 'Dazalar', 'Охотник (бот)'),
(70117, 'ruRU', 'Danlaar', 'Охотник (бот)'),
(70118, 'ruRU', 'Jeen\'ra', 'Охотник (бот)'),
(70119, 'ruRU', 'Jocaste', 'Охотник (бот)'),
(70120, 'ruRU', 'Dorion', 'Охотник (бот)'),
(70121, 'ruRU', 'Daera', 'Охотник (бот)'),
(70122, 'ruRU', 'Olmin', 'Охотник (бот)'),
(70123, 'ruRU', 'Regnus', 'Охотник (бот)'),
(70124, 'ruRU', 'Kaerbrus', 'Охотник (бот)'),
(70125, 'ruRU', 'Einris', 'Охотник (бот)'),
(70126, 'ruRU', 'Ulfir', 'Охотник (бот)'),
(70127, 'ruRU', 'Thorfin', 'Охотник (бот)'),
(70128, 'ruRU', 'Alenndaar', 'Охотник (бот)'),
(70129, 'ruRU', 'Dargh', 'Охотник (бот)'),
(70130, 'ruRU', 'Sallina', 'Охотник (бот)'),
(70131, 'ruRU', 'Hannovia', 'Охотник (бот)'),
(70132, 'ruRU', 'Keilnei', 'Охотник (бот)'),
(70133, 'ruRU', 'Tana', 'Охотник (бот)'),
(70134, 'ruRU', 'Oninath', 'Охотник (бот)'),
(70135, 'ruRU', 'Zandine', 'Охотник (бот)'),
(70136, 'ruRU', 'Deremiis', 'Охотник (бот)'),
(70137, 'ruRU', 'Acteon', 'Охотник (бот)'),
(70138, 'ruRU', 'Vord', 'Охотник (бот)'),
(70139, 'ruRU', 'Killac', 'Охотник (бот)'),
(70151, 'ruRU', 'Jorik', 'Разбойник (бот)'),
(70152, 'ruRU', 'Solm', 'Разбойник (бот)'),
(70153, 'ruRU', 'Keryn', 'Разбойник (бот)'),
(70154, 'ruRU', 'Osborne', 'Разбойник (бот)'),
(70155, 'ruRU', 'Hogral', 'Разбойник (бот)'),
(70156, 'ruRU', 'Ian', 'Разбойник (бот)'),
(70157, 'ruRU', 'David', 'Разбойник (бот)'),
(70158, 'ruRU', 'Marion', 'Разбойник (бот)'),
(70159, 'ruRU', 'Rwag', 'Разбойник (бот)'),
(70160, 'ruRU', 'Kaplak', 'Разбойник (бот)'),
(70161, 'ruRU', 'Gest', 'Разбойник (бот)'),
(70162, 'ruRU', 'Ormok', 'Разбойник (бот)'),
(70163, 'ruRU', 'Shenthul', 'Разбойник (бот)'),
(70164, 'ruRU', 'Frahun', 'Разбойник (бот)'),
(70165, 'ruRU', 'Jannok', 'Разбойник (бот)'),
(70166, 'ruRU', 'Syurna', 'Разбойник (бот)'),
(70167, 'ruRU', 'Erion', 'Разбойник (бот)'),
(70168, 'ruRU', 'Anishar', 'Разбойник (бот)'),
(70169, 'ruRU', 'Carolyn', 'Разбойник (бот)'),
(70170, 'ruRU', 'Miles', 'Разбойник (бот)'),
(70171, 'ruRU', 'Gregory', 'Разбойник (бот)'),
(70172, 'ruRU', 'Hulfdan', 'Разбойник (бот)'),
(70173, 'ruRU', 'Ormyr', 'Разбойник (бот)'),
(70174, 'ruRU', 'Fenthwick', 'Разбойник (бот)'),
(70175, 'ruRU', 'Fahrad', 'Разбойник (бот)'),
(70176, 'ruRU', 'Tony', 'Разбойник (бот)'),
(70177, 'ruRU', 'Kariel', 'Разбойник (бот)'),
(70178, 'ruRU', 'Tannaria', 'Разбойник (бот)'),
(70179, 'ruRU', 'Zelanis', 'Разбойник (бот)'),
(70180, 'ruRU', 'Elara', 'Разбойник (бот)'),
(70181, 'ruRU', 'Nerisen', 'Разбойник (бот)'),
(70201, 'ruRU', 'Anetta', 'Жрец (бот)'),
(70202, 'ruRU', 'Laurena', 'Жрец (бот)'),
(70203, 'ruRU', 'Josetta', 'Жрец (бот)'),
(70204, 'ruRU', 'Branstock', 'Жрец (бот)'),
(70205, 'ruRU', 'Maxan', 'Жрец (бот)'),
(70206, 'ruRU', 'Duesten', 'Жрец (бот)'),
(70207, 'ruRU', 'Beryl', 'Жрец (бот)'),
(70208, 'ruRU', 'Miles', 'Жрец (бот)'),
(70209, 'ruRU', 'Malakai', 'Жрец (бот)'),
(70210, 'ruRU', 'Cobb', 'Жрец (бот)'),
(70211, 'ruRU', 'Shanda', 'Жрец (бот)'),
(70212, 'ruRU', 'Laurna', 'Жрец (бот)'),
(70213, 'ruRU', 'Tai\'jin', 'Жрец (бот)'),
(70214, 'ruRU', 'Ken\'jai', 'Жрец (бот)'),
(70215, 'ruRU', 'Astarii', 'Жрец (бот)'),
(70216, 'ruRU', 'Jandria', 'Жрец (бот)'),
(70217, 'ruRU', 'Lariia', 'Жрец (бот)'),
(70218, 'ruRU', 'Lankester', 'Жрец (бот)'),
(70219, 'ruRU', 'Lazarus', 'Жрец (бот)'),
(70220, 'ruRU', 'Theodrus', 'Жрец (бот)'),
(70221, 'ruRU', 'Braenna', 'Жрец (бот)'),
(70222, 'ruRU', 'Toldren', 'Жрец (бот)'),
(70223, 'ruRU', 'Benjamin', 'Жрец (бот)'),
(70224, 'ruRU', 'Joshua', 'Жрец (бот)'),
(70225, 'ruRU', 'Zayus', 'Жрец (бот)'),
(70226, 'ruRU', 'X\'yera', 'Жрец (бот)'),
(70227, 'ruRU', 'Ur\'kyo', 'Жрец (бот)'),
(70228, 'ruRU', 'Nara', 'Жрец (бот)'),
(70229, 'ruRU', 'Alathea', 'Жрец (бот)'),
(70230, 'ruRU', 'Rohan', 'Жрец (бот)'),
(70231, 'ruRU', 'Arena', 'Жрец (бот)'),
(70232, 'ruRU', 'Ponaris', 'Жрец (бот)'),
(70233, 'ruRU', 'Zalduun', 'Жрец (бот)'),
(70234, 'ruRU', 'Aldrae', 'Жрец (бот)'),
(70235, 'ruRU', 'Lotheolan', 'Жрец (бот)'),
(70236, 'ruRU', 'Belestra', 'Жрец (бот)'),
(70237, 'ruRU', 'Caedmos', 'Жрец (бот)'),
(70238, 'ruRU', 'Guvan', 'Жрец (бот)'),
(70239, 'ruRU', 'Izmir', 'Жрец (бот)'),
(70240, 'ruRU', 'Fallat', 'Жрец (бот)'),
(70251, 'ruRU', 'Haromm', 'Шаман (бот)'),
(70252, 'ruRU', 'Siln', 'Шаман (бот)'),
(70253, 'ruRU', 'Tigor', 'Шаман (бот)'),
(70254, 'ruRU', 'Beram', 'Шаман (бот)'),
(70255, 'ruRU', 'Meela', 'Шаман (бот)'),
(70256, 'ruRU', 'Narm', 'Шаман (бот)'),
(70257, 'ruRU', 'Shikrik', 'Шаман (бот)'),
(70258, 'ruRU', 'Swart', 'Шаман (бот)'),
(70259, 'ruRU', 'Kardris', 'Шаман (бот)'),
(70260, 'ruRU', 'Sian\'tsu', 'Шаман (бот)'),
(70261, 'ruRU', 'Sagorne', 'Шаман (бот)'),
(70265, 'ruRU', 'Sulaa', 'Шаман (бот)'),
(70267, 'ruRU', 'Umbrua', 'Шаман (бот)'),
(70268, 'ruRU', 'Javad', 'Шаман (бот)'),
(70301, 'ruRU', 'Khelden', 'Маг (бот)'),
(70302, 'ruRU', 'Zaldimar', 'Маг (бот)'),
(70303, 'ruRU', 'Maginor', 'Маг (бот)'),
(70304, 'ruRU', 'Marryk', 'Маг (бот)'),
(70305, 'ruRU', 'Magis', 'Маг (бот)'),
(70306, 'ruRU', 'Isabella', 'Маг (бот)'),
(70307, 'ruRU', 'Cain', 'Маг (бот)'),
(70308, 'ruRU', 'Shymm', 'Маг (бот)'),
(70309, 'ruRU', 'Ursyn', 'Маг (бот)'),
(70310, 'ruRU', 'Thurston', 'Маг (бот)'),
(70311, 'ruRU', 'Pierce', 'Маг (бот)'),
(70312, 'ruRU', 'Anastasia', 'Маг (бот)'),
(70313, 'ruRU', 'Bink', 'Маг (бот)');

DELETE FROM `creature_template_locale` WHERE `locale`='ruRU' AND `entry` IN (70314,70315,70316,70317,70318,70319,70320,70321,70322,70323,70324,70325,70326,70327,70328,70329,70330,70331,70332,70333,70334,70335,70336,70351,70352,70353,70354,70355,70356,70357,70358,70359,70360,70361,70362,70363,70364,70365,70366,70367,70368,70369,70370,70371,70372,70373,70374,70375,70376,70377,70401,70402,70403,70404,70405,70406,70407,70408,70409,70410,70411,70412,70413,70414,70415,70416,70417,70418,70451,70452,70453,70454,70455,70456,70457,70458,70459,70460,70461,70462,70463,70464,70465,70501,70502,70503,70504,70505,70506,70507,70508,70509,70510,70511,70512,70513,70514,70515,70516,70517,70518,70519,70520,70521,70522,70523,70524,70525,70526,70527,70528,70529,70530,70531,70532,70533,70534,70535,70536,70537,70538,70542,70543,70544,70545,70551,70552,70553,70554,70555,70556,70557,70558,70559,70560,70561,70562,70563,70564,70565,70566,70567,70568,70569,70570,70571,70572,70573,70574,70575,70576,70577,70578,70579,70580,70581,70582,70583,70584,70585,70586,70587,70588,70589,70590,70591,70592,70593,70594,70595,90000,90100,100000,182757,182762,182767,190000,199999,290011,500030,500031,500032,601014,601015,601016,601020,601026,900000,999991,3460602,3460603);
INSERT INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`) VALUES
(70314, 'ruRU', 'Juli', 'Маг (бот)'),
(70315, 'ruRU', 'Nittlebur', 'Маг (бот)'),
(70316, 'ruRU', 'Jennea', 'Маг (бот)'),
(70317, 'ruRU', 'Un\'Thuwa', 'Маг (бот)'),
(70318, 'ruRU', 'Pephredo', 'Маг (бот)'),
(70319, 'ruRU', 'Enyo', 'Маг (бот)'),
(70320, 'ruRU', 'Mai\'ah', 'Маг (бот)'),
(70321, 'ruRU', 'Deino', 'Маг (бот)'),
(70322, 'ruRU', 'Uthel\'nay', 'Маг (бот)'),
(70323, 'ruRU', 'Dink', 'Маг (бот)'),
(70324, 'ruRU', 'Julia', 'Маг (бот)'),
(70325, 'ruRU', 'Garridel', 'Маг (бот)'),
(70326, 'ruRU', 'Valaatu', 'Маг (бот)'),
(70327, 'ruRU', 'Zaedana', 'Маг (бот)'),
(70328, 'ruRU', 'Quithas', 'Маг (бот)'),
(70329, 'ruRU', 'Inethven', 'Маг (бот)'),
(70330, 'ruRU', 'Narinth', 'Маг (бот)'),
(70331, 'ruRU', 'Edirah', 'Маг (бот)'),
(70332, 'ruRU', 'Valustraa', 'Маг (бот)'),
(70333, 'ruRU', 'Semid', 'Маг (бот)'),
(70334, 'ruRU', 'Harnan', 'Маг (бот)'),
(70335, 'ruRU', 'Bati', 'Маг (бот)'),
(70336, 'ruRU', 'Derek', 'Маг (бот)'),
(70351, 'ruRU', 'Drusilla', 'Чернокнижник (бот)'),
(70352, 'ruRU', 'Alamar', 'Чернокнижник (бот)'),
(70353, 'ruRU', 'Demisette', 'Чернокнижник (бот)'),
(70354, 'ruRU', 'Maximillian', 'Чернокнижник (бот)'),
(70355, 'ruRU', 'Kartosh', 'Чернокнижник (бот)'),
(70356, 'ruRU', 'Maximillion', 'Чернокнижник (бот)'),
(70357, 'ruRU', 'Rupert', 'Чернокнижник (бот)'),
(70358, 'ruRU', 'Nartok', 'Чернокнижник (бот)'),
(70359, 'ruRU', 'Dhugru', 'Чернокнижник (бот)'),
(70360, 'ruRU', 'Grol\'dar', 'Чернокнижник (бот)'),
(70361, 'ruRU', 'Mirket', 'Чернокнижник (бот)'),
(70362, 'ruRU', 'Zevrost', 'Чернокнижник (бот)'),
(70363, 'ruRU', 'Kaal', 'Чернокнижник (бот)'),
(70364, 'ruRU', 'Luther', 'Чернокнижник (бот)'),
(70365, 'ruRU', 'Richard', 'Чернокнижник (бот)'),
(70366, 'ruRU', 'Thistleheart', 'Чернокнижник (бот)'),
(70367, 'ruRU', 'Briarthorn', 'Чернокнижник (бот)'),
(70368, 'ruRU', 'Alexander', 'Чернокнижник (бот)'),
(70369, 'ruRU', 'Ursula', 'Чернокнижник (бот)'),
(70370, 'ruRU', 'Sandahl', 'Чернокнижник (бот)'),
(70371, 'ruRU', 'Gimrizz', 'Чернокнижник (бот)'),
(70372, 'ruRU', 'Teli\'Larien', 'Чернокнижник (бот)'),
(70373, 'ruRU', 'Celoenus', 'Чернокнижник (бот)'),
(70374, 'ruRU', 'Alamma', 'Чернокнижник (бот)'),
(70375, 'ruRU', 'Talionia', 'Чернокнижник (бот)'),
(70376, 'ruRU', 'Zanien', 'Чернокнижник (бот)'),
(70377, 'ruRU', 'Babagaya', 'Чернокнижник (бот)'),
(70401, 'ruRU', 'Turak', 'Друид (бот)'),
(70402, 'ruRU', 'Sheal', 'Друид (бот)'),
(70403, 'ruRU', 'Kym', 'Друид (бот)'),
(70404, 'ruRU', 'Gart', 'Друид (бот)'),
(70405, 'ruRU', 'Gennia', 'Друид (бот)'),
(70406, 'ruRU', 'Mardant', 'Друид (бот)'),
(70407, 'ruRU', 'Kal', 'Друид (бот)'),
(70408, 'ruRU', 'Mathrengyl', 'Друид (бот)'),
(70409, 'ruRU', 'Denatharion', 'Друид (бот)'),
(70410, 'ruRU', 'Fylerian', 'Друид (бот)'),
(70411, 'ruRU', 'Sheldras', 'Друид (бот)'),
(70412, 'ruRU', 'Theridran', 'Друид (бот)'),
(70413, 'ruRU', 'Maldryn', 'Друид (бот)'),
(70414, 'ruRU', 'Jannos', 'Друид (бот)'),
(70415, 'ruRU', 'Golhine', 'Друид (бот)'),
(70416, 'ruRU', 'Loganaar', 'Друид (бот)'),
(70417, 'ruRU', 'Harene', 'Друид (бот)'),
(70418, 'ruRU', 'Shalannius', 'Друид (бот)'),
(70451, 'ruRU', 'Siouxsie', 'Рыцарь смерти (бот)'),
(70452, 'ruRU', 'Imhadria', 'Рыцарь смерти (бот)'),
(70453, 'ruRU', 'Vaelen', 'Рыцарь смерти (бот)'),
(70454, 'ruRU', 'Mynx', 'Рыцарь смерти (бот)'),
(70455, 'ruRU', 'Lankral', 'Рыцарь смерти (бот)'),
(70456, 'ruRU', 'Sliver', 'Рыцарь смерти (бот)'),
(70457, 'ruRU', 'Vereth', 'Рыцарь смерти (бот)'),
(70458, 'ruRU', 'Arly', 'Рыцарь смерти (бот)'),
(70459, 'ruRU', 'Setaal', 'Рыцарь смерти (бот)'),
(70460, 'ruRU', 'Uzo', 'Рыцарь смерти (бот)'),
(70461, 'ruRU', 'Illyrie', 'Рыцарь смерти (бот)'),
(70462, 'ruRU', 'Crok', 'Рыцарь смерти (бот)'),
(70463, 'ruRU', 'Zor\'be', 'Рыцарь смерти (бот)'),
(70464, 'ruRU', 'Datura', 'Рыцарь смерти (бот)'),
(70465, 'ruRU', 'Stefan', 'Рыцарь смерти (бот)'),
(70501, 'ruRU', 'Бес', NULL),
(70502, 'ruRU', 'Демон Бездны', NULL),
(70503, 'ruRU', 'Суккуб', NULL),
(70504, 'ruRU', 'Охотник Скверны', NULL),
(70505, 'ruRU', 'Страж Скверны', NULL),
(70506, 'ruRU', 'Паук', NULL),
(70507, 'ruRU', 'Змей', NULL),
(70508, 'ruRU', 'Хищная птица', NULL),
(70509, 'ruRU', 'Летучая мышь', NULL),
(70510, 'ruRU', 'Крылатый змей', NULL),
(70511, 'ruRU', 'Опустошитель', NULL),
(70512, 'ruRU', 'Дракондор', NULL),
(70513, 'ruRU', 'Скат Пустоты', NULL),
(70514, 'ruRU', 'Спороскат', NULL),
(70515, 'ruRU', 'Падальщик', NULL),
(70516, 'ruRU', 'Ящер', NULL),
(70517, 'ruRU', 'Волк', NULL),
(70518, 'ruRU', 'Долгоног', NULL),
(70519, 'ruRU', 'Кошка', NULL),
(70520, 'ruRU', 'Гиена', NULL),
(70521, 'ruRU', 'Оса', NULL),
(70522, 'ruRU', 'Теромоль', NULL),
(70523, 'ruRU', 'Скорпид', NULL),
(70524, 'ruRU', 'Черепаха', NULL),
(70525, 'ruRU', 'Горилла', NULL),
(70526, 'ruRU', 'Медведь', NULL),
(70527, 'ruRU', 'Вепрь', NULL),
(70528, 'ruRU', 'Краб', NULL),
(70529, 'ruRU', 'Кроколиск', NULL),
(70530, 'ruRU', 'Прыгуана', NULL),
(70531, 'ruRU', 'Силитид', NULL),
(70532, 'ruRU', 'Химера', NULL),
(70533, 'ruRU', 'Дух зверя', NULL),
(70534, 'ruRU', 'Гончая Недр', NULL),
(70535, 'ruRU', 'Дьявозавр', NULL),
(70536, 'ruRU', 'Носорог', NULL),
(70537, 'ruRU', 'Червь', NULL),
(70538, 'ruRU', 'Восставший вурдалак', NULL),
(70542, 'ruRU', 'Исчадие Тьмы', NULL),
(70543, 'ruRU', 'Волк духа', NULL),
(70544, 'ruRU', 'Элементаль воды', NULL),
(70545, 'ruRU', 'Древень', NULL),
(70551, 'ruRU', 'Gorkramato', 'Мастер Клинка (бот)'),
(70552, 'ruRU', 'Зеркальное изображение (Мастер Клинка)', 'Мастер Клинка (бот)'),
(70553, 'ruRU', 'Osis', 'Обсидиановый Разрушитель (бот)'),
(70554, 'ruRU', 'Amot', 'Обсидиановый Разрушитель (бот)'),
(70555, 'ruRU', 'Detrae', 'Архимаг (бот)'),
(70556, 'ruRU', 'Элементаль воды', NULL),
(70557, 'ruRU', 'Neroth', 'Повелитель Ужаса (бот)'),
(70558, 'ruRU', 'Fearoth', 'Повелитель Ужаса (бот)'),
(70559, 'ruRU', 'Zalamon', 'Повелитель Ужаса (бот)'),
(70560, 'ruRU', 'Lotthicus', 'Повелитель Ужаса (бот)'),
(70561, 'ruRU', 'Ramarot', 'Повелитель Ужаса (бот)'),
(70562, 'ruRU', 'Инфернал', NULL),
(70563, 'ruRU', 'Eanor', 'Разрушитель Заклинаний (бот)'),
(70564, 'ruRU', 'Narsen', 'Разрушитель Заклинаний (бот)'),
(70565, 'ruRU', 'Caelnor', 'Разрушитель Заклинаний (бот)'),
(70566, 'ruRU', 'Daenste', 'Разрушитель Заклинаний (бот)'),
(70567, 'ruRU', 'Neshdar', 'Разрушитель Заклинаний (бот)'),
(70568, 'ruRU', 'Mara', 'Тёмная Охотница (бот)'),
(70569, 'ruRU', 'Tani', 'Тёмная Охотница (бот)'),
(70570, 'ruRU', 'Eva', 'Тёмная Охотница (бот)'),
(70571, 'ruRU', 'Darise', 'Тёмная Охотница (бот)'),
(70572, 'ruRU', 'Lyra', 'Тёмная Охотница (бот)'),
(70573, 'ruRU', 'Тёмный приспешник', NULL),
(70574, 'ruRU', 'Тёмный приспешник', NULL),
(70575, 'ruRU', 'Prakar', 'Некромант (бот)'),
(70576, 'ruRU', 'Rothik', 'Некромант (бот)'),
(70577, 'ruRU', 'Hexir', 'Некромант (бот)'),
(70578, 'ruRU', 'Fikhar', 'Некромант (бот)'),
(70579, 'ruRU', 'Drothum', 'Некромант (бот)'),
(70580, 'ruRU', 'Скелет', NULL),
(70581, 'ruRU', 'Kondra', 'Морская Ведьма (бот)'),
(70582, 'ruRU', 'Serpentra', 'Морская Ведьма (бот)'),
(70583, 'ruRU', 'Serena', 'Морская Ведьма (бот)'),
(70584, 'ruRU', 'Asprah', 'Морская Ведьма (бот)'),
(70585, 'ruRU', 'Charib\'dishal', 'Морская Ведьма (бот)'),
(70586, 'ruRU', 'Торнадо', NULL),
(70587, 'ruRU', 'Tuten\'arak', 'Повелитель Склепов (бот)'),
(70588, 'ruRU', 'Anubiros', 'Повелитель Склепов (бот)'),
(70589, 'ruRU', 'Nephri\'thos', 'Повелитель Склепов (бот)'),
(70590, 'ruRU', 'Arak-arahm', 'Повелитель Склепов (бот)'),
(70591, 'ruRU', 'Horus\'aman', 'Повелитель Склепов (бот)'),
(70592, 'ruRU', 'Трупный жук', NULL),
(70593, 'ruRU', 'Трупный жук', NULL),
(70594, 'ruRU', 'Трупный жук', NULL),
(70595, 'ruRU', 'Саранча', NULL),
(90000, 'ruRU', 'Хардкорный режим', 'AzerothCore'),
(90100, 'ruRU', 'Боевой пропуск', 'AzerothCore'),
(100000, 'ruRU', 'Turco', 'Перенос эмблем'),
(182757, 'ruRU', 'Воин Кор\'крона', NULL),
(182762, 'ruRU', 'Воин Кор\'крона', NULL),
(182767, 'ruRU', 'Воин Кор\'крона', NULL),
(190000, 'ruRU', 'Мастер порталов', 'Телепортация'),
(199999, 'ruRU', 'Kaylub', '|cff00ccffПрофессии|r'),
(290011, 'ruRU', 'Ling', 'Банкир реагентов'),
(500030, 'ruRU', 'Talamortis', 'Продавец гильдейских домов'),
(500031, 'ruRU', 'Xrispins', 'Дворецкий гильдейского дома'),
(500032, 'ruRU', 'Хозяйка таверны Моника', NULL),
(601014, 'ruRU', 'The Mountain', 'Верховая езда и маунты'),
(601015, 'ruRU', 'Beauregard Boneglitter', 'Зачарования'),
(601016, 'ruRU', 'Мастер баффов Хассельхуф', 'Баффы'),
(601020, 'ruRU', 'Loita', 'Dobbo Girl'),
(601026, 'ruRU', 'White Fang', 'Повелитель зверей'),
(900000, 'ruRU', 'Eron Glowpride', 'Мастер свечения оружия'),
(999991, 'ruRU', 'Распорядитель арены 1х1', 'Арена 1х1'),
(3460602, 'ruRU', 'Ледяная сфера (2)', NULL),
(3460603, 'ruRU', 'Ледяная сфера (3)', NULL);



-- ---------------- 04_menyu_npc.sql ----------------
-- =====================================================================
-- Пункты меню NPC (стандартные диалоги и телепортёр)
-- База: acore_world. Таблица: gossip_menu_option_locale. Сгенерировано tools/gen.py
-- Перед применением остановите worldserver. Файл можно применять повторно.
-- =====================================================================
SET NAMES utf8mb4;

DELETE FROM `gossip_menu_option_locale` WHERE `Locale`='ruRU' AND ((`MenuID`=0 AND `OptionID`=0) OR (`MenuID`=0 AND `OptionID`=2) OR (`MenuID`=0 AND `OptionID`=4) OR (`MenuID`=0 AND `OptionID`=5) OR (`MenuID`=0 AND `OptionID`=7) OR (`MenuID`=0 AND `OptionID`=10) OR (`MenuID`=0 AND `OptionID`=11) OR (`MenuID`=0 AND `OptionID`=15) OR (`MenuID`=0 AND `OptionID`=17) OR (`MenuID`=85 AND `OptionID`=4) OR (`MenuID`=141 AND `OptionID`=4) OR (`MenuID`=161 AND `OptionID`=1) OR (`MenuID`=381 AND `OptionID`=4) OR (`MenuID`=410 AND `OptionID`=4) OR (`MenuID`=411 AND `OptionID`=4) OR (`MenuID`=435 AND `OptionID`=0) OR (`MenuID`=435 AND `OptionID`=6) OR (`MenuID`=435 AND `OptionID`=10) OR (`MenuID`=435 AND `OptionID`=11) OR (`MenuID`=436 AND `OptionID`=4) OR (`MenuID`=721 AND `OptionID`=2) OR (`MenuID`=721 AND `OptionID`=4) OR (`MenuID`=721 AND `OptionID`=5) OR (`MenuID`=721 AND `OptionID`=6) OR (`MenuID`=721 AND `OptionID`=8) OR (`MenuID`=721 AND `OptionID`=12) OR (`MenuID`=1041 AND `OptionID`=0) OR (`MenuID`=1042 AND `OptionID`=0) OR (`MenuID`=1047 AND `OptionID`=1) OR (`MenuID`=1050 AND `OptionID`=1) OR (`MenuID`=1465 AND `OptionID`=0) OR (`MenuID`=1467 AND `OptionID`=0) OR (`MenuID`=1468 AND `OptionID`=0) OR (`MenuID`=1469 AND `OptionID`=0) OR (`MenuID`=1950 AND `OptionID`=0) OR (`MenuID`=1951 AND `OptionID`=2) OR (`MenuID`=1951 AND `OptionID`=4) OR (`MenuID`=1951 AND `OptionID`=5) OR (`MenuID`=1951 AND `OptionID`=6) OR (`MenuID`=1951 AND `OptionID`=7) OR (`MenuID`=1951 AND `OptionID`=9) OR (`MenuID`=1951 AND `OptionID`=10) OR (`MenuID`=1952 AND `OptionID`=0) OR (`MenuID`=1953 AND `OptionID`=0) OR (`MenuID`=1969 AND `OptionID`=0) OR (`MenuID`=1971 AND `OptionID`=0) OR (`MenuID`=2101 AND `OptionID`=0) OR (`MenuID`=2121 AND `OptionID`=0) OR (`MenuID`=2121 AND `OptionID`=4) OR (`MenuID`=2121 AND `OptionID`=6) OR (`MenuID`=2121 AND `OptionID`=9) OR (`MenuID`=2298 AND `OptionID`=0) OR (`MenuID`=2298 AND `OptionID`=1) OR (`MenuID`=2298 AND `OptionID`=2) OR (`MenuID`=2298 AND `OptionID`=3) OR (`MenuID`=2298 AND `OptionID`=4) OR (`MenuID`=2352 AND `OptionID`=0) OR (`MenuID`=2352 AND `OptionID`=3) OR (`MenuID`=2352 AND `OptionID`=5) OR (`MenuID`=2352 AND `OptionID`=8) OR (`MenuID`=2387 AND `OptionID`=0) OR (`MenuID`=2441 AND `OptionID`=0) OR (`MenuID`=2741 AND `OptionID`=0) OR (`MenuID`=2743 AND `OptionID`=0) OR (`MenuID`=2749 AND `OptionID`=0) OR (`MenuID`=2784 AND `OptionID`=0) OR (`MenuID`=2849 AND `OptionID`=0) OR (`MenuID`=2849 AND `OptionID`=4) OR (`MenuID`=2849 AND `OptionID`=5) OR (`MenuID`=2849 AND `OptionID`=8) OR (`MenuID`=2849 AND `OptionID`=10) OR (`MenuID`=2849 AND `OptionID`=11) OR (`MenuID`=3202 AND `OptionID`=0) OR (`MenuID`=3203 AND `OptionID`=0) OR (`MenuID`=3506 AND `OptionID`=2) OR (`MenuID`=3533 AND `OptionID`=2) OR (`MenuID`=3580 AND `OptionID`=2) OR (`MenuID`=3651 AND `OptionID`=0) OR (`MenuID`=3651 AND `OptionID`=1) OR (`MenuID`=3651 AND `OptionID`=2) OR (`MenuID`=3841 AND `OptionID`=0) OR (`MenuID`=3842 AND `OptionID`=0) OR (`MenuID`=3984 AND `OptionID`=4) OR (`MenuID`=4004 AND `OptionID`=1) OR (`MenuID`=4110 AND `OptionID`=0) OR (`MenuID`=4111 AND `OptionID`=0) OR (`MenuID`=4117 AND `OptionID`=0) OR (`MenuID`=4129 AND `OptionID`=0) OR (`MenuID`=4134 AND `OptionID`=0) OR (`MenuID`=4135 AND `OptionID`=0) OR (`MenuID`=4136 AND `OptionID`=0) OR (`MenuID`=4138 AND `OptionID`=0) OR (`MenuID`=4156 AND `OptionID`=0) OR (`MenuID`=4160 AND `OptionID`=0) OR (`MenuID`=4164 AND `OptionID`=0) OR (`MenuID`=4170 AND `OptionID`=0) OR (`MenuID`=4171 AND `OptionID`=0) OR (`MenuID`=4184 AND `OptionID`=0) OR (`MenuID`=4186 AND `OptionID`=0) OR (`MenuID`=4208 AND `OptionID`=0) OR (`MenuID`=4211 AND `OptionID`=0) OR (`MenuID`=4241 AND `OptionID`=0) OR (`MenuID`=4244 AND `OptionID`=0) OR (`MenuID`=4263 AND `OptionID`=0) OR (`MenuID`=4356 AND `OptionID`=0) OR (`MenuID`=4502 AND `OptionID`=4) OR (`MenuID`=4512 AND `OptionID`=4) OR (`MenuID`=4513 AND `OptionID`=4) OR (`MenuID`=4533 AND `OptionID`=3) OR (`MenuID`=4540 AND `OptionID`=4) OR (`MenuID`=4541 AND `OptionID`=4) OR (`MenuID`=4542 AND `OptionID`=4) OR (`MenuID`=4561 AND `OptionID`=4) OR (`MenuID`=4562 AND `OptionID`=4) OR (`MenuID`=4566 AND `OptionID`=3) OR (`MenuID`=4575 AND `OptionID`=4) OR (`MenuID`=4576 AND `OptionID`=4) OR (`MenuID`=4577 AND `OptionID`=4) OR (`MenuID`=4658 AND `OptionID`=4) OR (`MenuID`=4659 AND `OptionID`=4) OR (`MenuID`=4676 AND `OptionID`=4) OR (`MenuID`=4690 AND `OptionID`=4) OR (`MenuID`=4748 AND `OptionID`=0) OR (`MenuID`=4763 AND `OptionID`=4) OR (`MenuID`=4781 AND `OptionID`=1) OR (`MenuID`=4821 AND `OptionID`=1) OR (`MenuID`=4842 AND `OptionID`=0) OR (`MenuID`=4843 AND `OptionID`=0) OR (`MenuID`=5061 AND `OptionID`=4) OR (`MenuID`=5123 AND `OptionID`=0) OR (`MenuID`=5602 AND `OptionID`=0) OR (`MenuID`=5667 AND `OptionID`=2) OR (`MenuID`=5667 AND `OptionID`=3) OR (`MenuID`=5668 AND `OptionID`=0) OR (`MenuID`=5703 AND `OptionID`=0) OR (`MenuID`=5721 AND `OptionID`=0) OR (`MenuID`=5721 AND `OptionID`=1) OR (`MenuID`=5779 AND `OptionID`=0) OR (`MenuID`=5780 AND `OptionID`=0) OR (`MenuID`=5781 AND `OptionID`=0) OR (`MenuID`=5783 AND `OptionID`=0) OR (`MenuID`=5849 AND `OptionID`=2) OR (`MenuID`=6001 AND `OptionID`=0) OR (`MenuID`=6092 AND `OptionID`=0) OR (`MenuID`=6094 AND `OptionID`=0) OR (`MenuID`=6470 AND `OptionID`=0) OR (`MenuID`=6470 AND `OptionID`=1) OR (`MenuID`=6529 AND `OptionID`=0) OR (`MenuID`=6539 AND `OptionID`=1) OR (`MenuID`=6539 AND `OptionID`=2) OR (`MenuID`=6539 AND `OptionID`=3) OR (`MenuID`=6539 AND `OptionID`=4) OR (`MenuID`=6539 AND `OptionID`=5) OR (`MenuID`=6539 AND `OptionID`=6) OR (`MenuID`=6539 AND `OptionID`=7) OR (`MenuID`=6539 AND `OptionID`=8) OR (`MenuID`=6539 AND `OptionID`=9) OR (`MenuID`=6539 AND `OptionID`=10) OR (`MenuID`=6539 AND `OptionID`=11) OR (`MenuID`=6539 AND `OptionID`=12) OR (`MenuID`=6539 AND `OptionID`=13) OR (`MenuID`=6539 AND `OptionID`=14) OR (`MenuID`=6539 AND `OptionID`=15) OR (`MenuID`=6539 AND `OptionID`=16) OR (`MenuID`=6650 AND `OptionID`=4) OR (`MenuID`=6799 AND `OptionID`=0) OR (`MenuID`=6815 AND `OptionID`=4) OR (`MenuID`=6899 AND `OptionID`=2) OR (`MenuID`=7048 AND `OptionID`=0) OR (`MenuID`=7048 AND `OptionID`=1) OR (`MenuID`=7164 AND `OptionID`=0) OR (`MenuID`=7164 AND `OptionID`=1) OR (`MenuID`=7164 AND `OptionID`=2) OR (`MenuID`=7164 AND `OptionID`=3) OR (`MenuID`=7165 AND `OptionID`=0) OR (`MenuID`=7166 AND `OptionID`=0) OR (`MenuID`=7175 AND `OptionID`=0) OR (`MenuID`=7193 AND `OptionID`=0) OR (`MenuID`=7199 AND `OptionID`=0) OR (`MenuID`=7199 AND `OptionID`=1) OR (`MenuID`=7200 AND `OptionID`=0) OR (`MenuID`=7200 AND `OptionID`=1) OR (`MenuID`=7201 AND `OptionID`=0) OR (`MenuID`=7201 AND `OptionID`=1) OR (`MenuID`=7202 AND `OptionID`=0) OR (`MenuID`=7202 AND `OptionID`=1) OR (`MenuID`=7203 AND `OptionID`=0) OR (`MenuID`=7230 AND `OptionID`=0) OR (`MenuID`=7231 AND `OptionID`=0) OR (`MenuID`=7232 AND `OptionID`=0) OR (`MenuID`=7246 AND `OptionID`=0) OR (`MenuID`=7254 AND `OptionID`=0) OR (`MenuID`=7254 AND `OptionID`=1) OR (`MenuID`=7254 AND `OptionID`=2) OR (`MenuID`=7254 AND `OptionID`=3) OR (`MenuID`=7254 AND `OptionID`=4) OR (`MenuID`=7254 AND `OptionID`=5) OR (`MenuID`=7254 AND `OptionID`=6) OR (`MenuID`=7266 AND `OptionID`=0) OR (`MenuID`=7266 AND `OptionID`=1));
INSERT INTO `gossip_menu_option_locale` (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`) VALUES
(0, 0, 'ruRU', 'GOSSIP_OPTION_QUESTGIVER', ''),
(0, 2, 'ruRU', 'Я хочу быстро путешествовать', ''),
(0, 4, 'ruRU', 'Верни меня к жизни', ''),
(0, 5, 'ruRU', 'Верни меня к жизни', ''),
(0, 7, 'ruRU', 'Покажи мне мой банк', ''),
(0, 10, 'ruRU', 'Я хочу попасть на поле боя', ''),
(0, 11, 'ruRU', 'Аукцион!', ''),
(0, 15, 'ruRU', 'Я хочу, чтобы мой питомец забыл свои навыки', ''),
(0, 17, 'ruRU', 'GOSSIP_OPTION_OUTDOORPVP', ''),
(85, 4, 'ruRU', '<Взять письмо>', ''),
(141, 4, 'ruRU', '<Взять письмо>', ''),
(161, 1, 'ruRU', 'Мне нужен еще один набор воровских инструментов.', ''),
(381, 4, 'ruRU', '<Взять письмо>', ''),
(410, 4, 'ruRU', '<Взять письмо>', ''),
(411, 4, 'ruRU', '<Взять письмо>', ''),
(435, 0, 'ruRU', 'Аукцион', ''),
(435, 6, 'ruRU', 'Регистратор гильдий', ''),
(435, 10, 'ruRU', 'Офицерская комната', ''),
(435, 11, 'ruRU', 'Военачальник', ''),
(436, 4, 'ruRU', '<Взять письмо>', ''),
(721, 2, 'ruRU', 'Регистратор гильдий', ''),
(721, 4, 'ruRU', 'Почтовый ящик', ''),
(721, 5, 'ruRU', 'Аукцион', ''),
(721, 6, 'ruRU', 'Мастер оружия', ''),
(721, 8, 'ruRU', 'Военачальник', ''),
(721, 12, 'ruRU', 'Смотритель дирижаблей', ''),
(1041, 0, 'ruRU', 'Обучи меня.', ''),
(1042, 0, 'ruRU', 'Обучи меня.', ''),
(1047, 1, 'ruRU', 'Доступ: малый рекомбобулятор', ''),
(1050, 1, 'ruRU', 'Использовать инженерное дело, чтобы получить доступ к скрытым схемам!', ''),
(1465, 0, 'ruRU', 'Обучи меня.', ''),
(1467, 0, 'ruRU', 'Обучи меня.', ''),
(1468, 0, 'ruRU', 'Обучи меня.', ''),
(1469, 0, 'ruRU', 'Обучи меня.', ''),
(1950, 0, 'ruRU', 'Продолжай...', ''),
(1951, 2, 'ruRU', 'Регистратор гильдий', ''),
(1951, 4, 'ruRU', 'Почтовый ящик', ''),
(1951, 5, 'ruRU', 'Аукцион', ''),
(1951, 6, 'ruRU', 'Смотритель дирижаблей', ''),
(1951, 7, 'ruRU', 'Мастер оружия', ''),
(1951, 9, 'ruRU', 'Офицерская комната', ''),
(1951, 10, 'ruRU', 'Военачальник', ''),
(1952, 0, 'ruRU', 'Продолжай...', ''),
(1953, 0, 'ruRU', 'Продолжай...', ''),
(1969, 0, 'ruRU', 'Где сейчас дирижабль?', ''),
(1971, 0, 'ruRU', 'Где сейчас дирижабль?', ''),
(2101, 0, 'ruRU', 'Где сейчас дирижабль?', ''),
(2121, 0, 'ruRU', 'Аукцион', ''),
(2121, 4, 'ruRU', 'Регистратор гильдий', ''),
(2121, 6, 'ruRU', 'Почтовый ящик', ''),
(2121, 9, 'ruRU', 'Военачальник', ''),
(2298, 0, 'ruRU', 'Я преподношу тебе Либрам Размышлений.', ''),
(2298, 1, 'ruRU', 'Я преподношу тебе Либрам Телосложения.', ''),
(2298, 2, 'ruRU', 'Я преподношу тебе Либрам Упорства.', ''),
(2298, 3, 'ruRU', 'Я преподношу тебе Либрам Стойкости.', ''),
(2298, 4, 'ruRU', 'Я преподношу тебе Либрам Ненасытности.', ''),
(2352, 0, 'ruRU', 'Аукцион', ''),
(2352, 3, 'ruRU', 'Регистратор гильдий', ''),
(2352, 5, 'ruRU', 'Почтовый ящик', ''),
(2352, 8, 'ruRU', 'Военачальник', ''),
(2387, 0, 'ruRU', 'Эм... простите за беспокойство, но можно мне снова взглянуть на гроссбух Доброй Стали... если он вам не нужен.', NULL),
(2441, 0, 'ruRU', 'Где сейчас дирижабль?', ''),
(2741, 0, 'ruRU', 'Обучи меня.', ''),
(2743, 0, 'ruRU', 'Обучи меня.', ''),
(2749, 0, 'ruRU', 'Обучи меня.', ''),
(2784, 0, 'ruRU', 'Обучи меня.', ''),
(2849, 0, 'ruRU', 'Аукцион', ''),
(2849, 4, 'ruRU', 'Военачальник', ''),
(2849, 5, 'ruRU', 'Регистратор гильдий', ''),
(2849, 8, 'ruRU', 'Почтовый ящик', ''),
(2849, 10, 'ruRU', 'Мастер оружия', ''),
(2849, 11, 'ruRU', 'Смотритель дирижаблей', ''),
(3202, 0, 'ruRU', 'Обучи меня.', ''),
(3203, 0, 'ruRU', 'Обучи меня.', ''),
(3506, 2, 'ruRU', 'Регистратор гильдий', ''),
(3533, 2, 'ruRU', 'Регистратор гильдий', ''),
(3580, 2, 'ruRU', 'Регистратор гильдий', ''),
(3651, 0, 'ruRU', 'Можно мне еще один Гамбит Рассвета, Бетина? Хочу испытать его снова...', ''),
(3651, 1, 'ruRU', 'Бетина, мне нужна замена Печати Рассвета, пожалуйста!', ''),
(3651, 2, 'ruRU', 'Бетина, мне нужна замена Руны Рассвета, пожалуйста!', ''),
(3841, 0, 'ruRU', 'Где сейчас дирижабль?', ''),
(3842, 0, 'ruRU', 'Где сейчас дирижабль?', ''),
(3984, 4, 'ruRU', '<Взять письмо>', ''),
(4004, 1, 'ruRU', 'Меридет, можно мне еще немного обогащенного манной корма для лошадей?', ''),
(4110, 0, 'ruRU', 'Обучи меня.', ''),
(4111, 0, 'ruRU', 'Обучи меня.', ''),
(4117, 0, 'ruRU', 'Обучи меня.', ''),
(4129, 0, 'ruRU', 'Обучи меня.', ''),
(4134, 0, 'ruRU', 'Обучи меня.', ''),
(4135, 0, 'ruRU', 'Обучи меня.', ''),
(4136, 0, 'ruRU', 'Обучи меня.', ''),
(4138, 0, 'ruRU', 'Обучи меня.', ''),
(4156, 0, 'ruRU', 'Обучи меня.', ''),
(4160, 0, 'ruRU', 'Обучи меня.', ''),
(4164, 0, 'ruRU', 'Обучи меня.', ''),
(4170, 0, 'ruRU', 'Обучи меня.', ''),
(4171, 0, 'ruRU', 'Обучи меня.', ''),
(4184, 0, 'ruRU', 'Обучи меня.', ''),
(4186, 0, 'ruRU', 'Обучи меня.', ''),
(4208, 0, 'ruRU', 'Обучи меня.', ''),
(4211, 0, 'ruRU', 'Обучи меня.', ''),
(4241, 0, 'ruRU', 'Обучи меня.', ''),
(4244, 0, 'ruRU', 'Обучи меня.', ''),
(4263, 0, 'ruRU', 'Обучи меня.', ''),
(4356, 0, 'ruRU', 'Обучи меня.', ''),
(4502, 4, 'ruRU', '<Взять письмо>', ''),
(4512, 4, 'ruRU', '<Взять письмо>', ''),
(4513, 4, 'ruRU', '<Взять письмо>', ''),
(4533, 3, 'ruRU', 'Покажи, что у тебя есть на продажу.', ''),
(4540, 4, 'ruRU', '<Взять письмо>', ''),
(4541, 4, 'ruRU', '<Взять письмо>', ''),
(4542, 4, 'ruRU', '<Взять письмо>', ''),
(4561, 4, 'ruRU', '<Взять письмо>', ''),
(4562, 4, 'ruRU', '<Взять письмо>', ''),
(4566, 3, 'ruRU', 'Покажи, что у тебя есть на продажу.', ''),
(4575, 4, 'ruRU', '<Взять письмо>', ''),
(4576, 4, 'ruRU', '<Взять письмо>', ''),
(4577, 4, 'ruRU', '<Взять письмо>', ''),
(4658, 4, 'ruRU', '<Взять письмо>', ''),
(4659, 4, 'ruRU', '<Взять письмо>', ''),
(4676, 4, 'ruRU', '<Взять письмо>', ''),
(4690, 4, 'ruRU', '<Взять письмо>', ''),
(4748, 0, 'ruRU', 'Обучи меня.', ''),
(4763, 4, 'ruRU', 'Мой ответ — Ноздорму.', ''),
(4781, 1, 'ruRU', 'Получить контракт Братства Тория', NULL),
(4821, 1, 'ruRU', 'Покажи, что у тебя есть на продажу.', ''),
(4842, 0, 'ruRU', 'Обучи меня.', ''),
(4843, 0, 'ruRU', 'Обучи меня.', ''),
(5061, 4, 'ruRU', '<Взять письмо>', ''),
(5123, 0, 'ruRU', 'Научи меня путям духов.', ''),
(5602, 0, 'ruRU', 'Спасибо, Железнокор. Мы готовы, открывай дверь.', ''),
(5667, 2, 'ruRU', 'Итак, я нашел этот ключ от кандалов...', ''),
(5667, 3, 'ruRU', 'Зачем мне чинить ловушку? Почему бы просто не убрать стражника по старинке?', ''),
(5668, 0, 'ruRU', 'Похоже на то!', ''),
(5703, 0, 'ruRU', '<Передать Оковы Искателя Ветра>.', ''),
(5721, 0, 'ruRU', 'Что значит «купить»?! Теперь я король... а быть королем хорошо!', ''),
(5721, 1, 'ruRU', 'Покажи, какое пойло у тебя на продажу, Криг.', ''),
(5779, 0, 'ruRU', 'Что нужно сделать?', ''),
(5780, 0, 'ruRU', 'Повелитель Огня и все, кто посмеет встать на моем пути, испытают мой гнев.', ''),
(5781, 0, 'ruRU', 'Я обыщу всю землю в поисках этого Земледела. А что насчет эссенции?', ''),
(5783, 0, 'ruRU', 'Дай мне сосуд, верховный лорд.', ''),
(5849, 2, 'ruRU', 'Покажи, что у тебя есть на продажу.', ''),
(6001, 0, 'ruRU', '<Положить руку на сферу.>', ''),
(6092, 0, 'ruRU', 'Этот пространственный имплозер звучит опасно! Как мне его сделать?', ''),
(6094, 0, 'ruRU', 'Я должен построить маяк для этого чудесного устройства!', ''),
(6470, 0, 'ruRU', 'Я хочу отправиться на поле боя.', ''),
(6470, 1, 'ruRU', 'Покажи, что у тебя есть на продажу.', ''),
(6529, 0, 'ruRU', 'Баристольт, я потерял свой значок, и мне нужна замена.', ''),
(6539, 1, 'ruRU', 'Я потерял свою печатку Пути Завоевателя.', ''),
(6539, 2, 'ruRU', 'Я потерял свою печатку Пути Завоевателя.', ''),
(6539, 3, 'ruRU', 'Я потерял свою печатку Пути Завоевателя.', ''),
(6539, 4, 'ruRU', 'Я потерял свою печатку Пути Завоевателя.', ''),
(6539, 5, 'ruRU', 'Я потерял свою печатку Пути Заклинателя.', ''),
(6539, 6, 'ruRU', 'Я потерял свою печатку Пути Заклинателя.', ''),
(6539, 7, 'ruRU', 'Я потерял свою печатку Пути Заклинателя.', ''),
(6539, 8, 'ruRU', 'Я потерял свою печатку Пути Заклинателя.', ''),
(6539, 9, 'ruRU', 'Я потерял свою печатку Пути Защитника.', ''),
(6539, 10, 'ruRU', 'Я потерял свою печатку Пути Защитника.', ''),
(6539, 11, 'ruRU', 'Я потерял свою печатку Пути Защитника.', ''),
(6539, 12, 'ruRU', 'Я потерял свою печатку Пути Защитника.', ''),
(6539, 13, 'ruRU', 'Я потерял свою печатку Пути Завоевателя.', ''),
(6539, 14, 'ruRU', 'Я потерял свою печатку Пути Заклинателя.', ''),
(6539, 15, 'ruRU', 'Я потерял свою печатку Пути Защитника.', ''),
(6539, 16, 'ruRU', 'Я готов, Анахронос. Пожалуйста, вручи мне Скипетр Зыбучих Песков.', ''),
(6650, 4, 'ruRU', '<Взять письмо>', ''),
(6799, 0, 'ruRU', '<Скопировать выкройку в журнал.>', ''),
(6815, 4, 'ruRU', 'Где старейшина Темный Рог?', ''),
(6899, 2, 'ruRU', 'Где старейшина Пшеничное Копыто?', ''),
(7048, 0, 'ruRU', 'Покажи свои товары', ''),
(7048, 1, 'ruRU', 'Давай выясним.', ''),
(7164, 0, 'ruRU', 'Что происходит?', ''),
(7164, 1, 'ruRU', 'Что я могу сделать?', ''),
(7164, 2, 'ruRU', 'Где мы сражаемся с Плетью?', ''),
(7164, 3, 'ruRU', 'Сколько битв мы выиграли?', ''),
(7165, 0, 'ruRU', 'Я хочу потратить свои руны.', ''),
(7166, 0, 'ruRU', 'Использовать 8 некротических рун и сорвать его ритуал.', ''),
(7175, 0, 'ruRU', 'Я болен. Пожалуйста, вылечи меня, лекарь.', NULL),
(7193, 0, 'ruRU', 'У меня есть другой вопрос.', ''),
(7199, 0, 'ruRU', 'Где еще мы сражаемся с Плетью?', ''),
(7199, 1, 'ruRU', 'У меня есть другой вопрос.', ''),
(7200, 0, 'ruRU', 'Где еще мы сражаемся с Плетью?', ''),
(7200, 1, 'ruRU', 'У меня есть другой вопрос.', ''),
(7201, 0, 'ruRU', 'Где еще мы сражаемся с Плетью?', ''),
(7201, 1, 'ruRU', 'У меня есть другой вопрос.', ''),
(7202, 0, 'ruRU', 'Где еще мы сражаемся с Плетью?', ''),
(7202, 1, 'ruRU', 'У меня есть другой вопрос.', ''),
(7203, 0, 'ruRU', 'У меня есть другой вопрос.', ''),
(7230, 0, 'ruRU', 'Дай мне один из твоих магических предметов.', ''),
(7231, 0, 'ruRU', 'Дай мне один из твоих магических предметов.', ''),
(7232, 0, 'ruRU', 'Дай мне один из твоих магических предметов.', ''),
(7246, 0, 'ruRU', 'У меня есть другой вопрос.', ''),
(7254, 0, 'ruRU', 'Азшара сейчас под атакой?', ''),
(7254, 1, 'ruRU', 'Выжженные земли сейчас под атакой?', ''),
(7254, 2, 'ruRU', 'Пылающие степи сейчас под атакой?', ''),
(7254, 3, 'ruRU', 'Восточные Чумные земли сейчас под атакой?', ''),
(7254, 4, 'ruRU', 'Танарис сейчас под атакой?', ''),
(7254, 5, 'ruRU', 'Зимние Ключи сейчас под атакой?', ''),
(7254, 6, 'ruRU', 'У меня есть другой вопрос.', ''),
(7266, 0, 'ruRU', 'Где еще мы сражаемся с Плетью?', ''),
(7266, 1, 'ruRU', 'У меня есть другой вопрос.', '');

DELETE FROM `gossip_menu_option_locale` WHERE `Locale`='ruRU' AND ((`MenuID`=7267 AND `OptionID`=0) OR (`MenuID`=7267 AND `OptionID`=1) OR (`MenuID`=7268 AND `OptionID`=0) OR (`MenuID`=7269 AND `OptionID`=0) OR (`MenuID`=7270 AND `OptionID`=0) OR (`MenuID`=7271 AND `OptionID`=0) OR (`MenuID`=7272 AND `OptionID`=0) OR (`MenuID`=7273 AND `OptionID`=0) OR (`MenuID`=7274 AND `OptionID`=0) OR (`MenuID`=7275 AND `OptionID`=0) OR (`MenuID`=7276 AND `OptionID`=0) OR (`MenuID`=7277 AND `OptionID`=0) OR (`MenuID`=7278 AND `OptionID`=0) OR (`MenuID`=7279 AND `OptionID`=0) OR (`MenuID`=7280 AND `OptionID`=0) OR (`MenuID`=7281 AND `OptionID`=0) OR (`MenuID`=7282 AND `OptionID`=0) OR (`MenuID`=7283 AND `OptionID`=0) OR (`MenuID`=7421 AND `OptionID`=0) OR (`MenuID`=7422 AND `OptionID`=0) OR (`MenuID`=7455 AND `OptionID`=0) OR (`MenuID`=7459 AND `OptionID`=0) OR (`MenuID`=7486 AND `OptionID`=0) OR (`MenuID`=7512 AND `OptionID`=0) OR (`MenuID`=7520 AND `OptionID`=1) OR (`MenuID`=7552 AND `OptionID`=32918) OR (`MenuID`=7552 AND `OptionID`=32919) OR (`MenuID`=7552 AND `OptionID`=32920) OR (`MenuID`=7559 AND `OptionID`=0) OR (`MenuID`=7560 AND `OptionID`=0) OR (`MenuID`=7581 AND `OptionID`=35377) OR (`MenuID`=7581 AND `OptionID`=35378) OR (`MenuID`=7581 AND `OptionID`=35379) OR (`MenuID`=7633 AND `OptionID`=0) OR (`MenuID`=7633 AND `OptionID`=3) OR (`MenuID`=7633 AND `OptionID`=5) OR (`MenuID`=7633 AND `OptionID`=7) OR (`MenuID`=7706 AND `OptionID`=34158) OR (`MenuID`=7722 AND `OptionID`=2) OR (`MenuID`=7724 AND `OptionID`=2) OR (`MenuID`=7777 AND `OptionID`=0) OR (`MenuID`=7777 AND `OptionID`=3) OR (`MenuID`=7777 AND `OptionID`=5) OR (`MenuID`=7777 AND `OptionID`=7) OR (`MenuID`=7809 AND `OptionID`=0) OR (`MenuID`=7815 AND `OptionID`=0) OR (`MenuID`=7815 AND `OptionID`=1) OR (`MenuID`=7820 AND `OptionID`=0) OR (`MenuID`=7820 AND `OptionID`=1) OR (`MenuID`=7833 AND `OptionID`=0) OR (`MenuID`=7853 AND `OptionID`=0) OR (`MenuID`=8117 AND `OptionID`=0) OR (`MenuID`=8129 AND `OptionID`=2) OR (`MenuID`=8185 AND `OptionID`=1) OR (`MenuID`=8228 AND `OptionID`=0) OR (`MenuID`=8228 AND `OptionID`=1) OR (`MenuID`=8234 AND `OptionID`=0) OR (`MenuID`=8234 AND `OptionID`=1) OR (`MenuID`=8234 AND `OptionID`=2) OR (`MenuID`=8234 AND `OptionID`=3) OR (`MenuID`=8282 AND `OptionID`=4) OR (`MenuID`=8282 AND `OptionID`=6) OR (`MenuID`=8304 AND `OptionID`=5) OR (`MenuID`=8306 AND `OptionID`=0) OR (`MenuID`=8308 AND `OptionID`=0) OR (`MenuID`=8357 AND `OptionID`=4) OR (`MenuID`=8357 AND `OptionID`=6) OR (`MenuID`=8419 AND `OptionID`=4) OR (`MenuID`=8419 AND `OptionID`=6) OR (`MenuID`=8441 AND `OptionID`=0) OR (`MenuID`=8441 AND `OptionID`=1) OR (`MenuID`=8441 AND `OptionID`=2) OR (`MenuID`=8441 AND `OptionID`=3) OR (`MenuID`=8455 AND `OptionID`=0) OR (`MenuID`=8455 AND `OptionID`=4) OR (`MenuID`=8460 AND `OptionID`=0) OR (`MenuID`=8522 AND `OptionID`=0) OR (`MenuID`=8615 AND `OptionID`=0) OR (`MenuID`=8718 AND `OptionID`=1) OR (`MenuID`=8719 AND `OptionID`=1) OR (`MenuID`=8725 AND `OptionID`=1) OR (`MenuID`=8730 AND `OptionID`=0) OR (`MenuID`=8760 AND `OptionID`=0) OR (`MenuID`=8760 AND `OptionID`=1) OR (`MenuID`=8786 AND `OptionID`=0) OR (`MenuID`=8786 AND `OptionID`=1) OR (`MenuID`=8863 AND `OptionID`=0) OR (`MenuID`=8934 AND `OptionID`=4) OR (`MenuID`=8973 AND `OptionID`=0) OR (`MenuID`=8976 AND `OptionID`=4) OR (`MenuID`=9025 AND `OptionID`=4) OR (`MenuID`=9046 AND `OptionID`=0) OR (`MenuID`=9046 AND `OptionID`=1) OR (`MenuID`=9046 AND `OptionID`=2) OR (`MenuID`=9046 AND `OptionID`=3) OR (`MenuID`=9084 AND `OptionID`=0) OR (`MenuID`=9131 AND `OptionID`=0) OR (`MenuID`=9132 AND `OptionID`=0) OR (`MenuID`=9182 AND `OptionID`=0) OR (`MenuID`=9251 AND `OptionID`=0) OR (`MenuID`=9254 AND `OptionID`=0) OR (`MenuID`=9255 AND `OptionID`=0) OR (`MenuID`=9286 AND `OptionID`=3) OR (`MenuID`=9286 AND `OptionID`=4) OR (`MenuID`=9286 AND `OptionID`=5) OR (`MenuID`=9295 AND `OptionID`=0) OR (`MenuID`=9296 AND `OptionID`=0) OR (`MenuID`=9429 AND `OptionID`=1) OR (`MenuID`=9434 AND `OptionID`=0) OR (`MenuID`=9517 AND `OptionID`=0) OR (`MenuID`=9666 AND `OptionID`=0) OR (`MenuID`=9667 AND `OptionID`=0) OR (`MenuID`=9762 AND `OptionID`=0) OR (`MenuID`=9832 AND `OptionID`=11) OR (`MenuID`=9832 AND `OptionID`=12) OR (`MenuID`=9854 AND `OptionID`=1) OR (`MenuID`=9929 AND `OptionID`=1) OR (`MenuID`=9997 AND `OptionID`=1) OR (`MenuID`=10043 AND `OptionID`=1) OR (`MenuID`=10043 AND `OptionID`=7) OR (`MenuID`=10043 AND `OptionID`=10) OR (`MenuID`=10119 AND `OptionID`=1) OR (`MenuID`=10173 AND `OptionID`=2) OR (`MenuID`=10189 AND `OptionID`=0) OR (`MenuID`=10192 AND `OptionID`=0) OR (`MenuID`=10192 AND `OptionID`=1) OR (`MenuID`=10210 AND `OptionID`=1) OR (`MenuID`=10248 AND `OptionID`=0) OR (`MenuID`=10248 AND `OptionID`=1) OR (`MenuID`=10265 AND `OptionID`=0) OR (`MenuID`=10265 AND `OptionID`=3) OR (`MenuID`=10265 AND `OptionID`=5) OR (`MenuID`=10265 AND `OptionID`=8) OR (`MenuID`=10311 AND `OptionID`=0) OR (`MenuID`=10363 AND `OptionID`=0) OR (`MenuID`=10363 AND `OptionID`=1) OR (`MenuID`=10416 AND `OptionID`=0) OR (`MenuID`=10437 AND `OptionID`=0) OR (`MenuID`=10437 AND `OptionID`=1) OR (`MenuID`=10568 AND `OptionID`=0) OR (`MenuID`=10769 AND `OptionID`=0) OR (`MenuID`=10769 AND `OptionID`=4) OR (`MenuID`=10769 AND `OptionID`=5) OR (`MenuID`=10769 AND `OptionID`=8) OR (`MenuID`=10769 AND `OptionID`=10) OR (`MenuID`=10769 AND `OptionID`=11) OR (`MenuID`=10995 AND `OptionID`=0) OR (`MenuID`=10995 AND `OptionID`=1) OR (`MenuID`=10995 AND `OptionID`=2) OR (`MenuID`=10995 AND `OptionID`=3) OR (`MenuID`=10995 AND `OptionID`=4) OR (`MenuID`=10995 AND `OptionID`=5) OR (`MenuID`=10995 AND `OptionID`=6) OR (`MenuID`=10995 AND `OptionID`=7) OR (`MenuID`=10995 AND `OptionID`=8) OR (`MenuID`=10995 AND `OptionID`=9) OR (`MenuID`=10995 AND `OptionID`=10) OR (`MenuID`=10995 AND `OptionID`=11) OR (`MenuID`=10995 AND `OptionID`=12) OR (`MenuID`=10995 AND `OptionID`=13) OR (`MenuID`=10995 AND `OptionID`=14) OR (`MenuID`=10995 AND `OptionID`=15) OR (`MenuID`=10995 AND `OptionID`=16) OR (`MenuID`=10995 AND `OptionID`=17) OR (`MenuID`=10995 AND `OptionID`=18) OR (`MenuID`=10995 AND `OptionID`=19) OR (`MenuID`=10996 AND `OptionID`=6) OR (`MenuID`=11095 AND `OptionID`=0) OR (`MenuID`=11097 AND `OptionID`=0) OR (`MenuID`=11098 AND `OptionID`=0) OR (`MenuID`=11099 AND `OptionID`=0) OR (`MenuID`=11100 AND `OptionID`=0) OR (`MenuID`=11102 AND `OptionID`=0) OR (`MenuID`=11103 AND `OptionID`=0) OR (`MenuID`=21222 AND `OptionID`=0) OR (`MenuID`=21249 AND `OptionID`=0) OR (`MenuID`=21263 AND `OptionID`=3) OR (`MenuID`=21263 AND `OptionID`=4) OR (`MenuID`=21263 AND `OptionID`=5) OR (`MenuID`=21263 AND `OptionID`=6) OR (`MenuID`=21264 AND `OptionID`=3) OR (`MenuID`=21264 AND `OptionID`=4) OR (`MenuID`=21264 AND `OptionID`=5) OR (`MenuID`=21264 AND `OptionID`=6) OR (`MenuID`=21265 AND `OptionID`=3) OR (`MenuID`=21265 AND `OptionID`=4) OR (`MenuID`=21265 AND `OptionID`=5) OR (`MenuID`=21265 AND `OptionID`=6) OR (`MenuID`=21266 AND `OptionID`=3) OR (`MenuID`=21266 AND `OptionID`=4) OR (`MenuID`=21266 AND `OptionID`=5) OR (`MenuID`=21266 AND `OptionID`=6) OR (`MenuID`=21267 AND `OptionID`=3) OR (`MenuID`=21267 AND `OptionID`=4) OR (`MenuID`=21267 AND `OptionID`=5) OR (`MenuID`=21267 AND `OptionID`=6) OR (`MenuID`=21268 AND `OptionID`=3) OR (`MenuID`=21268 AND `OptionID`=4) OR (`MenuID`=21268 AND `OptionID`=5) OR (`MenuID`=21268 AND `OptionID`=6));
INSERT INTO `gossip_menu_option_locale` (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`) VALUES
(7267, 0, 'ruRU', 'Где еще мы сражаемся с Плетью?', ''),
(7267, 1, 'ruRU', 'У меня есть другой вопрос.', ''),
(7268, 0, 'ruRU', 'Но его сын мертв.', ''),
(7269, 0, 'ruRU', 'Невероятная история, Фэйрбанкс. А что с клинком? Его уже не спасти?', ''),
(7270, 0, 'ruRU', 'И ты это сделал...', ''),
(7271, 0, 'ruRU', 'Ты был прав, Фэйрбанкс. Это трагично.', ''),
(7272, 0, 'ruRU', 'Ты хочешь сказать...', ''),
(7273, 0, 'ruRU', 'Продолжай, пожалуйста, Фэйрбанкс.', ''),
(7274, 0, 'ruRU', 'И он это сделал?', ''),
(7275, 0, 'ruRU', 'Но? Но что??', ''),
(7276, 0, 'ruRU', 'Тысяча? На одного человека?', ''),
(7277, 0, 'ruRU', 'Откуда ты все это знаешь?', ''),
(7278, 0, 'ruRU', 'Ты хочешь сказать...', ''),
(7279, 0, 'ruRU', 'Невероятная история. Так как же он умер?', ''),
(7280, 0, 'ruRU', 'Я все еще не до конца понимаю.', ''),
(7281, 0, 'ruRU', 'Что ты имеешь в виду?', ''),
(7282, 0, 'ruRU', 'Могрейн?', ''),
(7283, 0, 'ruRU', 'Проклятие? Что здесь ПРОИСХОДИТ, Фэйрбанкс?', ''),
(7421, 0, 'ruRU', 'Я не актер.', NULL),
(7422, 0, 'ruRU', 'Ладно, тогда я попробую.', NULL),
(7455, 0, 'ruRU', 'Обучи меня.', ''),
(7459, 0, 'ruRU', 'Обучи меня.', ''),
(7486, 0, 'ruRU', 'Взять знак отличия рыцаря крови', ''),
(7512, 0, 'ruRU', 'Обучи меня.', ''),
(7520, 1, 'ruRU', 'Натуралист, пожалуйста, даруй мне свое благословение.', ''),
(7552, 32918, 'ruRU', 'Мои спутники и я с вами, леди Праудмур.', ''),
(7552, 32919, 'ruRU', 'Мы готовы ко всему, что может послать Архимонд, леди Праудмур.', ''),
(7552, 32920, 'ruRU', 'До новой встречи, леди Праудмур.', ''),
(7559, 0, 'ruRU', 'Даруй мне свою метку, мудрый древний.', ''),
(7560, 0, 'ruRU', 'Даруй мне свою метку, могучий древний.', ''),
(7581, 35377, 'ruRU', 'Нам нечего бояться.', ''),
(7581, 35378, 'ruRU', 'Я с тобой, Тралл.', ''),
(7581, 35379, 'ruRU', 'До новой встречи, Тралл.', ''),
(7633, 0, 'ruRU', 'Аукцион', ''),
(7633, 3, 'ruRU', 'Регистратор гильдий', ''),
(7633, 5, 'ruRU', 'Почтовый ящик', ''),
(7633, 7, 'ruRU', 'Мастер оружия', ''),
(7706, 34158, 'ruRU', 'Я буду благодарен за любую помощь, жрица.', ''),
(7722, 2, 'ruRU', 'Дай мне флаг!', ''),
(7724, 2, 'ruRU', 'Дай мне флаг!', ''),
(7777, 0, 'ruRU', 'Аукцион', ''),
(7777, 3, 'ruRU', 'Регистратор гильдий', ''),
(7777, 5, 'ruRU', 'Почтовый ящик', ''),
(7777, 7, 'ruRU', 'Мастер оружия', ''),
(7809, 0, 'ruRU', 'Обучи меня.', ''),
(7815, 0, 'ruRU', 'Обучи меня.', ''),
(7815, 1, 'ruRU', 'Позволь взглянуть на твои товары.', ''),
(7820, 0, 'ruRU', 'Обучи меня.', ''),
(7820, 1, 'ruRU', 'Позволь взглянуть на твои товары.', ''),
(7833, 0, 'ruRU', 'Обучи меня.', ''),
(7853, 0, 'ruRU', 'Мы готовы, Тралл.', ''),
(8117, 0, 'ruRU', 'Я готов, Адьен.', ''),
(8129, 2, 'ruRU', 'Регистратор гильдий', ''),
(8185, 1, 'ruRU', 'Регистратор гильдий', ''),
(8228, 0, 'ruRU', 'Я и есть тот смертный, Саид. Вперед!', ''),
(8228, 1, 'ruRU', 'Я готов. Давай войдем в историю!', ''),
(8234, 0, 'ruRU', 'Кажется, я потерял свое кольцо.', ''),
(8234, 1, 'ruRU', 'Кажется, я потерял свое кольцо.', ''),
(8234, 2, 'ruRU', 'Кажется, я потерял свое кольцо.', ''),
(8234, 3, 'ruRU', 'Кажется, я потерял свое кольцо.', ''),
(8282, 4, 'ruRU', 'Почтовый ящик', ''),
(8282, 6, 'ruRU', 'Военачальник', ''),
(8304, 5, 'ruRU', 'Я хочу полететь в прежнее место!', ''),
(8306, 0, 'ruRU', 'Я должен построить маяк для этого чудесного устройства!', ''),
(8308, 0, 'ruRU', 'Этот пространственный имплозер звучит опасно! Как мне его сделать?', ''),
(8357, 4, 'ruRU', 'Почтовый ящик', ''),
(8357, 6, 'ruRU', 'Военачальник', ''),
(8419, 4, 'ruRU', 'Почтовый ящик', ''),
(8419, 6, 'ruRU', 'Военачальник', ''),
(8441, 0, 'ruRU', 'Я потерял свою Аметистовую печатку мастера-убийцы.', ''),
(8441, 1, 'ruRU', 'Я потерял свою Аметистовую печатку верховного мага.', ''),
(8441, 2, 'ruRU', 'Я потерял свою Аметистовую печатку великого защитника.', ''),
(8441, 3, 'ruRU', 'Я потерял свою Аметистовую печатку великого целителя.', ''),
(8455, 0, 'ruRU', 'Отправь меня обратно на Зазубренный хребет.', ''),
(8455, 4, 'ruRU', 'Отправь меня обратно в Вороний лес.', ''),
(8460, 0, 'ruRU', 'Обучи меня.', ''),
(8522, 0, 'ruRU', 'Обучи меня.', ''),
(8615, 0, 'ruRU', 'Я потерял свой свисток.', ''),
(8718, 1, 'ruRU', 'Да, я бы с радостью слетал в Лагерь Черного Ветра.', ''),
(8719, 1, 'ruRU', 'Конечно! Отправь меня на Заставу Стражи Небес.', ''),
(8725, 1, 'ruRU', 'Начать ритуал.', ''),
(8730, 0, 'ruRU', 'Покажи, что у тебя есть на продажу.', ''),
(8760, 0, 'ruRU', 'Обучи меня.', ''),
(8760, 1, 'ruRU', 'Позволь взглянуть на твои товары.', ''),
(8786, 0, 'ruRU', 'Где сейчас дирижабль в Оргриммар?', ''),
(8786, 1, 'ruRU', 'Где сейчас дирижабль в Гром\'гол?', ''),
(8863, 0, 'ruRU', 'Обучи меня.', ''),
(8934, 4, 'ruRU', 'Тебе все еще нужна помощь с доставкой бочонков из Караноса?', ''),
(8973, 0, 'ruRU', 'Я готов поработать на тебя сегодня! Давай сюда барана!', NULL),
(8976, 4, 'ruRU', 'Тебе все еще нужна помощь с перевозкой бочонков с места крушения у Колючего Холма?', ''),
(9025, 4, 'ruRU', 'Нападения дворфов Черного Железа', NULL),
(9046, 0, 'ruRU', 'Какие новости о битве за Оружейную Солнечного Края?', ''),
(9046, 1, 'ruRU', 'Скоро ли будут готовы наковальня и кузня в Оружейной Солнечного Края?', ''),
(9046, 2, 'ruRU', 'Экзарх, мы уже захватили Гавань Солнечного Края?', ''),
(9046, 3, 'ruRU', 'Насуун, ты не знаешь, когда в Гавани Солнечного Края появится алхимическая лаборатория?', ''),
(9084, 0, 'ruRU', 'Обучи меня.', ''),
(9131, 0, 'ruRU', 'Обучи меня.', ''),
(9132, 0, 'ruRU', 'Обучи меня.', ''),
(9182, 0, 'ruRU', 'Спасибо, что рассказал мне свою историю.', ''),
(9251, 0, 'ruRU', 'Положить руку на Ледяной камень.', ''),
(9254, 0, 'ruRU', 'Положить руку на Ледяной камень.', ''),
(9255, 0, 'ruRU', 'Положить руку на Ледяной камень.', ''),
(9286, 3, 'ruRU', 'Калесгос освобожден. Можешь телепортировать меня на Вершину?', ''),
(9286, 4, 'ruRU', 'Теперь, когда леди Сакролаш и великая чернокнижница Алитесс повержены, можешь телепортировать меня в Святилище Ведьмы?', ''),
(9286, 5, 'ruRU', 'Мы расчистили путь к Кил\'джедену! Можешь перенести меня поближе к Солнечному Колодцу?', ''),
(9295, 0, 'ruRU', 'Ты здесь не одна?', ''),
(9296, 0, 'ruRU', 'Зачем Кил\'джедену смертная женщина?', ''),
(9429, 1, 'ruRU', 'Я тебе покажу! Давай сюда тренировочный парашют!', NULL),
(9434, 0, 'ruRU', 'Это спустит ледяного змея на землю и покончит с ней.', ''),
(9517, 0, 'ruRU', 'Я хочу ввести секретный код, чтобы получить сувенир участника.', NULL),
(9666, 0, 'ruRU', 'Но я же проделал весь этот путь на своей бурильной машине...', ''),
(9667, 0, 'ruRU', 'Я готов.', ''),
(9762, 0, 'ruRU', 'Колтира, давай выбираться отсюда!', NULL),
(9832, 11, 'ruRU', 'Я потерял свою боевую гербовую накидку Аратора.', ''),
(9832, 12, 'ruRU', 'Я потерял свою боевую гербовую накидку Осквернителей.', ''),
(9854, 1, 'ruRU', 'Я потерял коммуникатор Бранна', ''),
(9929, 1, 'ruRU', 'Я потерял коммуникатор Бранна', ''),
(9997, 1, 'ruRU', 'Я не сражаюсь, так что отправь меня туда сейчас же!', ''),
(10043, 1, 'ruRU', 'Аукцион', ''),
(10043, 7, 'ruRU', 'Регистратор гильдий', ''),
(10043, 10, 'ruRU', 'Почтовый ящик', ''),
(10119, 1, 'ruRU', 'Дай мне бомбардировщик!', ''),
(10173, 2, 'ruRU', 'Снаряжение за эмблемы', ''),
(10189, 0, 'ruRU', 'Леди Праудмур, я готов отправиться в Оргриммар. Пожалуйста, откройте портал.', ''),
(10192, 0, 'ruRU', 'О великая Королева драконов, я каким-то образом потерял Ключ от Радужного Средоточия. Не могли бы вы найти его для меня?', ''),
(10192, 1, 'ruRU', 'О великая Королева драконов, я каким-то образом потерял Героический ключ от Радужного Средоточия. Не могли бы вы найти его для меня?', ''),
(10210, 1, 'ruRU', 'Я хочу посмотреть ваши товары.', ''),
(10248, 0, 'ruRU', 'Как мне получить гербовую накидку участника?', NULL),
(10248, 1, 'ruRU', 'Как мне заслужить благосклонность Духа состязаний?', NULL),
(10265, 0, 'ruRU', 'Аукцион', ''),
(10265, 3, 'ruRU', 'Регистратор гильдий', ''),
(10265, 5, 'ruRU', 'Почтовый ящик', ''),
(10265, 8, 'ruRU', 'Военачальник', ''),
(10311, 0, 'ruRU', 'Я хочу посмотреть ваши товары', ''),
(10363, 0, 'ruRU', 'Обучи меня.', ''),
(10363, 1, 'ruRU', 'Позволь взглянуть на твои товары.', ''),
(10416, 0, 'ruRU', 'Я хочу посмотреть ваши товары.', ''),
(10437, 0, 'ruRU', 'Я хочу научиться рыбной ловле.', ''),
(10437, 1, 'ruRU', 'Я хочу у тебя кое-что купить.', ''),
(10568, 0, 'ruRU', 'Обучи меня.', ''),
(10769, 0, 'ruRU', 'Аукцион', ''),
(10769, 4, 'ruRU', 'Военачальник', ''),
(10769, 5, 'ruRU', 'Регистратор гильдий', ''),
(10769, 8, 'ruRU', 'Почтовый ящик', ''),
(10769, 10, 'ruRU', 'Мастер оружия', ''),
(10769, 11, 'ruRU', 'Смотритель дирижаблей', ''),
(10995, 0, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 1, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 2, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 3, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 4, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 5, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 6, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 7, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 8, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 9, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 10, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 11, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 12, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 13, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 14, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 15, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 16, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 17, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 18, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10995, 19, 'ruRU', 'Не будет.', 'Требуется пожертвование.'),
(10996, 6, 'ruRU', 'Похоже, я потерял свое кольцо.', ''),
(11095, 0, 'ruRU', 'Я хочу посмотреть ваши товары', ''),
(11097, 0, 'ruRU', 'Я хочу посмотреть ваши товары', ''),
(11098, 0, 'ruRU', 'Я хочу посмотреть ваши товары', ''),
(11099, 0, 'ruRU', 'Я хочу посмотреть ваши товары', ''),
(11100, 0, 'ruRU', 'Я хочу посмотреть ваши товары', ''),
(11102, 0, 'ruRU', 'Я хочу посмотреть ваши товары', ''),
(11103, 0, 'ruRU', 'Я хочу посмотреть ваши товары', ''),
(21222, 0, 'ruRU', 'Обучи меня.', ''),
(21249, 0, 'ruRU', 'Пожать руку', NULL),
(21263, 3, 'ruRU', 'Кажется, я потерял Клеймо героя. Поможешь?', ''),
(21263, 4, 'ruRU', 'Кажется, я потерял Клеймо язычника. Поможешь?', ''),
(21263, 5, 'ruRU', 'Кажется, я потерял Клеймо язычника. Поможешь?', ''),
(21263, 6, 'ruRU', 'Кажется, я потерял Клеймо язычника. Поможешь?', ''),
(21264, 3, 'ruRU', 'Кажется, я потерял Ярость Мугамбы. Поможешь?', ''),
(21264, 4, 'ruRU', 'Кажется, я потерял Сила Мугамбы. Поможешь?', ''),
(21264, 5, 'ruRU', 'Кажется, я потерял Сила Мугамбы. Поможешь?', ''),
(21264, 6, 'ruRU', 'Кажется, я потерял Сила Мугамбы. Поможешь?', ''),
(21265, 3, 'ruRU', 'Кажется, я потерял Всевидящее око Зулдазара. Поможешь?', ''),
(21265, 4, 'ruRU', 'Кажется, я потерял Око Зулдазара. Поможешь?', ''),
(21265, 5, 'ruRU', 'Кажется, я потерял Око Зулдазара. Поможешь?', ''),
(21265, 6, 'ruRU', 'Кажется, я потерял Око Зулдазара. Поможешь?', ''),
(21266, 3, 'ruRU', 'Кажется, я потерял Неудержимая порча Кезана. Поможешь?', ''),
(21266, 4, 'ruRU', 'Кажется, я потерял Порча Кезана. Поможешь?', ''),
(21266, 5, 'ruRU', 'Кажется, я потерял Порча Кезана. Поможешь?', ''),
(21266, 6, 'ruRU', 'Кажется, я потерял Порча Кезана. Поможешь?', ''),
(21267, 3, 'ruRU', 'Кажется, я потерял Самоцвет Каджаро. Поможешь?', ''),
(21267, 4, 'ruRU', 'Кажется, я потерял Камешек Каджаро. Поможешь?', ''),
(21267, 5, 'ruRU', 'Кажется, я потерял Камешек Каджаро. Поможешь?', ''),
(21267, 6, 'ruRU', 'Кажется, я потерял Камешек Каджаро. Поможешь?', ''),
(21268, 3, 'ruRU', 'Кажется, я потерял Незамутненное видение Вудресс. Поможешь?', ''),
(21268, 4, 'ruRU', 'Кажется, я потерял Видение Вудресс. Поможешь?', ''),
(21268, 5, 'ruRU', 'Кажется, я потерял Видение Вудресс. Поможешь?', ''),
(21268, 6, 'ruRU', 'Кажется, я потерял Видение Вудресс. Поможешь?', '');

DELETE FROM `gossip_menu_option_locale` WHERE `Locale`='ruRU' AND ((`MenuID`=21269 AND `OptionID`=3) OR (`MenuID`=21269 AND `OptionID`=4) OR (`MenuID`=21269 AND `OptionID`=5) OR (`MenuID`=21269 AND `OptionID`=6) OR (`MenuID`=21270 AND `OptionID`=3) OR (`MenuID`=21270 AND `OptionID`=4) OR (`MenuID`=21270 AND `OptionID`=5) OR (`MenuID`=21270 AND `OptionID`=6) OR (`MenuID`=21271 AND `OptionID`=3) OR (`MenuID`=21271 AND `OptionID`=4) OR (`MenuID`=21271 AND `OptionID`=5) OR (`MenuID`=21271 AND `OptionID`=6) OR (`MenuID`=21893 AND `OptionID`=0) OR (`MenuID`=30005 AND `OptionID`=0) OR (`MenuID`=30005 AND `OptionID`=1) OR (`MenuID`=30008 AND `OptionID`=1) OR (`MenuID`=30200 AND `OptionID`=0) OR (`MenuID`=30201 AND `OptionID`=0) OR (`MenuID`=30201 AND `OptionID`=1) OR (`MenuID`=30211 AND `OptionID`=0) OR (`MenuID`=30211 AND `OptionID`=1) OR (`MenuID`=30212 AND `OptionID`=0) OR (`MenuID`=30213 AND `OptionID`=0) OR (`MenuID`=30214 AND `OptionID`=0) OR (`MenuID`=30215 AND `OptionID`=0) OR (`MenuID`=30216 AND `OptionID`=0) OR (`MenuID`=30228 AND `OptionID`=0) OR (`MenuID`=30228 AND `OptionID`=1) OR (`MenuID`=30228 AND `OptionID`=2) OR (`MenuID`=30230 AND `OptionID`=0) OR (`MenuID`=30231 AND `OptionID`=0) OR (`MenuID`=30232 AND `OptionID`=0) OR (`MenuID`=30233 AND `OptionID`=0) OR (`MenuID`=37523 AND `OptionID`=0) OR (`MenuID`=37552 AND `OptionID`=0) OR (`MenuID`=50000 AND `OptionID`=1) OR (`MenuID`=50000 AND `OptionID`=2) OR (`MenuID`=50000 AND `OptionID`=3) OR (`MenuID`=50000 AND `OptionID`=4) OR (`MenuID`=50000 AND `OptionID`=5) OR (`MenuID`=50000 AND `OptionID`=6) OR (`MenuID`=50000 AND `OptionID`=7) OR (`MenuID`=50000 AND `OptionID`=8) OR (`MenuID`=50000 AND `OptionID`=9) OR (`MenuID`=50000 AND `OptionID`=10) OR (`MenuID`=50000 AND `OptionID`=11) OR (`MenuID`=50000 AND `OptionID`=12) OR (`MenuID`=50000 AND `OptionID`=13) OR (`MenuID`=50000 AND `OptionID`=14) OR (`MenuID`=50000 AND `OptionID`=15) OR (`MenuID`=50000 AND `OptionID`=16) OR (`MenuID`=50000 AND `OptionID`=17) OR (`MenuID`=50000 AND `OptionID`=18) OR (`MenuID`=50000 AND `OptionID`=19) OR (`MenuID`=50000 AND `OptionID`=20) OR (`MenuID`=50001 AND `OptionID`=0) OR (`MenuID`=50001 AND `OptionID`=1) OR (`MenuID`=50001 AND `OptionID`=2) OR (`MenuID`=50001 AND `OptionID`=3) OR (`MenuID`=50001 AND `OptionID`=4) OR (`MenuID`=50001 AND `OptionID`=5) OR (`MenuID`=50001 AND `OptionID`=6) OR (`MenuID`=50001 AND `OptionID`=7) OR (`MenuID`=50001 AND `OptionID`=8) OR (`MenuID`=50001 AND `OptionID`=9) OR (`MenuID`=50001 AND `OptionID`=10) OR (`MenuID`=50001 AND `OptionID`=11) OR (`MenuID`=50001 AND `OptionID`=12) OR (`MenuID`=50001 AND `OptionID`=13) OR (`MenuID`=50001 AND `OptionID`=14) OR (`MenuID`=50001 AND `OptionID`=15) OR (`MenuID`=50001 AND `OptionID`=16) OR (`MenuID`=50001 AND `OptionID`=17) OR (`MenuID`=50001 AND `OptionID`=18) OR (`MenuID`=50001 AND `OptionID`=19) OR (`MenuID`=50002 AND `OptionID`=0) OR (`MenuID`=50002 AND `OptionID`=1) OR (`MenuID`=50002 AND `OptionID`=2) OR (`MenuID`=50002 AND `OptionID`=3) OR (`MenuID`=50002 AND `OptionID`=4) OR (`MenuID`=50002 AND `OptionID`=5) OR (`MenuID`=50002 AND `OptionID`=6) OR (`MenuID`=50003 AND `OptionID`=0) OR (`MenuID`=50003 AND `OptionID`=1) OR (`MenuID`=50003 AND `OptionID`=2) OR (`MenuID`=50003 AND `OptionID`=3) OR (`MenuID`=50003 AND `OptionID`=4) OR (`MenuID`=50003 AND `OptionID`=5) OR (`MenuID`=50003 AND `OptionID`=6) OR (`MenuID`=50003 AND `OptionID`=7) OR (`MenuID`=50003 AND `OptionID`=8) OR (`MenuID`=50003 AND `OptionID`=9) OR (`MenuID`=50003 AND `OptionID`=10) OR (`MenuID`=50003 AND `OptionID`=11) OR (`MenuID`=50003 AND `OptionID`=12) OR (`MenuID`=50004 AND `OptionID`=0) OR (`MenuID`=50004 AND `OptionID`=1) OR (`MenuID`=50004 AND `OptionID`=2) OR (`MenuID`=50004 AND `OptionID`=3) OR (`MenuID`=50004 AND `OptionID`=4) OR (`MenuID`=50004 AND `OptionID`=5) OR (`MenuID`=50004 AND `OptionID`=6) OR (`MenuID`=50004 AND `OptionID`=7) OR (`MenuID`=50004 AND `OptionID`=8) OR (`MenuID`=50004 AND `OptionID`=9) OR (`MenuID`=50004 AND `OptionID`=10) OR (`MenuID`=50004 AND `OptionID`=11) OR (`MenuID`=50004 AND `OptionID`=12) OR (`MenuID`=50004 AND `OptionID`=13) OR (`MenuID`=50004 AND `OptionID`=14) OR (`MenuID`=50004 AND `OptionID`=15) OR (`MenuID`=50004 AND `OptionID`=16) OR (`MenuID`=50004 AND `OptionID`=17) OR (`MenuID`=50004 AND `OptionID`=18) OR (`MenuID`=50004 AND `OptionID`=19) OR (`MenuID`=50004 AND `OptionID`=21) OR (`MenuID`=50004 AND `OptionID`=22) OR (`MenuID`=50004 AND `OptionID`=23) OR (`MenuID`=50005 AND `OptionID`=0) OR (`MenuID`=50005 AND `OptionID`=1) OR (`MenuID`=50005 AND `OptionID`=2) OR (`MenuID`=50005 AND `OptionID`=3) OR (`MenuID`=50005 AND `OptionID`=4) OR (`MenuID`=50005 AND `OptionID`=5) OR (`MenuID`=50005 AND `OptionID`=6) OR (`MenuID`=50005 AND `OptionID`=7) OR (`MenuID`=50005 AND `OptionID`=8) OR (`MenuID`=50005 AND `OptionID`=9) OR (`MenuID`=50005 AND `OptionID`=10) OR (`MenuID`=50005 AND `OptionID`=11) OR (`MenuID`=50005 AND `OptionID`=12) OR (`MenuID`=50005 AND `OptionID`=13) OR (`MenuID`=50005 AND `OptionID`=14) OR (`MenuID`=50005 AND `OptionID`=15) OR (`MenuID`=50005 AND `OptionID`=16) OR (`MenuID`=50005 AND `OptionID`=17) OR (`MenuID`=50005 AND `OptionID`=18) OR (`MenuID`=50005 AND `OptionID`=19) OR (`MenuID`=50005 AND `OptionID`=20) OR (`MenuID`=50005 AND `OptionID`=21) OR (`MenuID`=50005 AND `OptionID`=22) OR (`MenuID`=50005 AND `OptionID`=23) OR (`MenuID`=50005 AND `OptionID`=24) OR (`MenuID`=50006 AND `OptionID`=0) OR (`MenuID`=50006 AND `OptionID`=1) OR (`MenuID`=50006 AND `OptionID`=2) OR (`MenuID`=50006 AND `OptionID`=3) OR (`MenuID`=50006 AND `OptionID`=4) OR (`MenuID`=50006 AND `OptionID`=5) OR (`MenuID`=50006 AND `OptionID`=6) OR (`MenuID`=50006 AND `OptionID`=7) OR (`MenuID`=50006 AND `OptionID`=8) OR (`MenuID`=50006 AND `OptionID`=9) OR (`MenuID`=50006 AND `OptionID`=10) OR (`MenuID`=50006 AND `OptionID`=11) OR (`MenuID`=50006 AND `OptionID`=12) OR (`MenuID`=50006 AND `OptionID`=13) OR (`MenuID`=50006 AND `OptionID`=14) OR (`MenuID`=50006 AND `OptionID`=15) OR (`MenuID`=50006 AND `OptionID`=16) OR (`MenuID`=50006 AND `OptionID`=17) OR (`MenuID`=50006 AND `OptionID`=18) OR (`MenuID`=50006 AND `OptionID`=19) OR (`MenuID`=50007 AND `OptionID`=0) OR (`MenuID`=50007 AND `OptionID`=1) OR (`MenuID`=50007 AND `OptionID`=2) OR (`MenuID`=50007 AND `OptionID`=3) OR (`MenuID`=50007 AND `OptionID`=4) OR (`MenuID`=50007 AND `OptionID`=5) OR (`MenuID`=50007 AND `OptionID`=6) OR (`MenuID`=50007 AND `OptionID`=7) OR (`MenuID`=50008 AND `OptionID`=0) OR (`MenuID`=50008 AND `OptionID`=1) OR (`MenuID`=50008 AND `OptionID`=2) OR (`MenuID`=50008 AND `OptionID`=3) OR (`MenuID`=50008 AND `OptionID`=4) OR (`MenuID`=50008 AND `OptionID`=5) OR (`MenuID`=50008 AND `OptionID`=6) OR (`MenuID`=50008 AND `OptionID`=7) OR (`MenuID`=50008 AND `OptionID`=8) OR (`MenuID`=50008 AND `OptionID`=9) OR (`MenuID`=50008 AND `OptionID`=10) OR (`MenuID`=51000 AND `OptionID`=0) OR (`MenuID`=51001 AND `OptionID`=0) OR (`MenuID`=51002 AND `OptionID`=0) OR (`MenuID`=51003 AND `OptionID`=0) OR (`MenuID`=61021 AND `OptionID`=0) OR (`MenuID`=61025 AND `OptionID`=0));
INSERT INTO `gossip_menu_option_locale` (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`) VALUES
(21269, 3, 'ruRU', 'Кажется, я потерял Безупречная зачарованная водоросль южных морей. Поможешь?', ''),
(21269, 4, 'ruRU', 'Кажется, я потерял Зачарованная водоросль южных морей. Поможешь?', ''),
(21269, 5, 'ruRU', 'Кажется, я потерял Зачарованная водоросль южных морей. Поможешь?', ''),
(21269, 6, 'ruRU', 'Кажется, я потерял Зачарованная водоросль южных морей. Поможешь?', ''),
(21270, 3, 'ruRU', 'Кажется, я потерял Зандаларский талисман власти над тенью. Поможешь?', ''),
(21270, 4, 'ruRU', 'Кажется, я потерял Зандаларский талисман тени. Поможешь?', ''),
(21270, 5, 'ruRU', 'Кажется, я потерял Зандаларский талисман тени. Поможешь?', ''),
(21270, 6, 'ruRU', 'Кажется, я потерял Зандаларский талисман тени. Поможешь?', ''),
(21271, 3, 'ruRU', 'Кажется, я потерял Гнев Водоворота. Поможешь?', ''),
(21271, 4, 'ruRU', 'Кажется, я потерял Щупальце Водоворота. Поможешь?', ''),
(21271, 5, 'ruRU', 'Кажется, я потерял Щупальце Водоворота. Поможешь?', ''),
(21271, 6, 'ruRU', 'Кажется, я потерял Щупальце Водоворота. Поможешь?', ''),
(21893, 0, 'ruRU', 'Отдай лунный камень Южной Ярости, и я тебя отпущу.', ''),
(30005, 0, 'ruRU', 'Я потерял призрачные очки.', ''),
(30005, 1, 'ruRU', 'Я потерял призрачные очки.', ''),
(30008, 1, 'ruRU', 'Я потерял свою сигнальную ракетницу Кор\'крона.', ''),
(30200, 0, 'ruRU', 'Мне нужны еще одни ториевые кандалы.', ''),
(30201, 0, 'ruRU', 'Приветствую, древний. Я сделал все, о чем меня просили. Теперь я прошу вручить мне Рок\'делар.', ''),
(30201, 1, 'ruRU', 'Приветствую, древний. Я сделал все, о чем меня просили. Теперь я прошу вручить мне Лок\'делар.', ''),
(30211, 0, 'ruRU', 'Покажи, куда я могу полететь.', ''),
(30211, 1, 'ruRU', 'Мне нужно добраться до Крепости Стражей Зимы.', ''),
(30212, 0, 'ruRU', 'Око привело меня сюда, Эрис.', ''),
(30213, 0, 'ruRU', 'И мне было суждено это увидеть?', ''),
(30214, 0, 'ruRU', 'Я правда не знал, чего ожидать, Эрис. Я использую свои силы, чтобы помочь тебе, если это то, о чем меня просят.', ''),
(30215, 0, 'ruRU', 'Те дни прошли, Эрис.', ''),
(30216, 0, 'ruRU', 'Так чем я могу помочь?', ''),
(30228, 0, 'ruRU', 'Я потерял левую часть амулета лорда Валтхалака.', ''),
(30228, 1, 'ruRU', 'Я потерял верхнюю часть амулета лорда Валтхалака.', ''),
(30228, 2, 'ruRU', 'Я потерял правую часть амулета лорда Валтхалака.', ''),
(30230, 0, 'ruRU', 'Я готов, Оронок. Давай уничтожим Цирука и освободим стихии!', ''),
(30231, 0, 'ruRU', 'Я с тобой, Торим.', ''),
(30232, 0, 'ruRU', 'Дай мне бомбардировщик!', ''),
(30233, 0, 'ruRU', 'Я готов, верховный лорд.', ''),
(37523, 0, 'ruRU', 'Я готов войти в Солнечный Колодец.', ''),
(37552, 0, 'ruRU', 'Осмотреть останки.', ''),
(50000, 1, 'ruRU', 'Штормград', 'Вы уверены, что хотите отправиться: Штормград?'),
(50000, 2, 'ruRU', 'Оргриммар', 'Вы уверены, что хотите отправиться: Оргриммар?'),
(50000, 3, 'ruRU', 'Дарнас', 'Вы уверены, что хотите отправиться: Дарнас?'),
(50000, 4, 'ruRU', 'Стальгорн', 'Вы уверены, что хотите отправиться: Стальгорн?'),
(50000, 5, 'ruRU', 'Экзодар', 'Вы уверены, что хотите отправиться: Экзодар?'),
(50000, 6, 'ruRU', 'Громовой Утёс', 'Вы уверены, что хотите отправиться: Громовой Утёс?'),
(50000, 7, 'ruRU', 'Подгород', 'Вы уверены, что хотите отправиться: Подгород?'),
(50000, 8, 'ruRU', 'Луносвет', 'Вы уверены, что хотите отправиться: Луносвет?'),
(50000, 9, 'ruRU', 'Даларан', 'Вы уверены, что хотите отправиться: Даларан?'),
(50000, 10, 'ruRU', 'Шаттрат', 'Вы уверены, что хотите отправиться: Шаттрат?'),
(50000, 11, 'ruRU', 'Пиратская Бухта', 'Вы уверены, что хотите отправиться: Пиратская Бухта?'),
(50000, 12, 'ruRU', 'Арена Гурубаши', 'Вы уверены, что хотите отправиться: Арена?'),
(50000, 13, 'ruRU', 'Восточные королевства', NULL),
(50000, 14, 'ruRU', 'Калимдор', NULL),
(50000, 15, 'ruRU', 'Запределье', NULL),
(50000, 16, 'ruRU', 'Нордскол', NULL),
(50000, 17, 'ruRU', 'Подземелья (классика)', NULL),
(50000, 18, 'ruRU', 'Подземелья (Burning Crusade)', NULL),
(50000, 19, 'ruRU', 'Подземелья (Wrath of the Lich King)', NULL),
(50000, 20, 'ruRU', 'Рейды', NULL),
(50001, 0, 'ruRU', 'Гномреган', 'Вы уверены, что хотите отправиться: Гномреган?'),
(50001, 1, 'ruRU', 'Мертвые копи', 'Вы уверены, что хотите отправиться: Мертвые копи?'),
(50001, 2, 'ruRU', 'Тюрьма', 'Вы уверены, что хотите отправиться: Тюрьма?'),
(50001, 3, 'ruRU', 'Огненная пропасть', 'Вы уверены, что хотите отправиться: Огненная пропасть?'),
(50001, 4, 'ruRU', 'Курганы Иглошкурых', 'Вы уверены, что хотите отправиться: Курганы Иглошкурых?'),
(50001, 5, 'ruRU', 'Лабиринты Иглошкурых', 'Вы уверены, что хотите отправиться: Лабиринты Иглошкурых?'),
(50001, 6, 'ruRU', 'Монастырь Алого ордена', 'Вы уверены, что хотите отправиться: Монастырь Алого ордена?'),
(50001, 7, 'ruRU', 'Крепость Темного Клыка', 'Вы уверены, что хотите отправиться: Крепость Темного Клыка?'),
(50001, 8, 'ruRU', 'Пещеры Стенаний', 'Вы уверены, что хотите отправиться: Пещеры Стенаний?'),
(50001, 9, 'ruRU', 'Непроглядная Пучина', 'Вы уверены, что хотите отправиться: Непроглядная Пучина?'),
(50001, 10, 'ruRU', 'Глубины Черной горы', 'Вы уверены, что хотите отправиться: Глубины Черной горы?'),
(50001, 11, 'ruRU', 'Пик Черной горы', 'Вы уверены, что хотите отправиться: Пик Черной горы?'),
(50001, 12, 'ruRU', 'Забытый Город', 'Вы уверены, что хотите отправиться: Забытый Город?'),
(50001, 13, 'ruRU', 'Мародон', 'Вы уверены, что хотите отправиться: Мародон?'),
(50001, 14, 'ruRU', 'Некроситет', 'Вы уверены, что хотите отправиться: Некроситет?'),
(50001, 15, 'ruRU', 'Стратхольм', 'Вы уверены, что хотите отправиться: Стратхольм?'),
(50001, 16, 'ruRU', 'Затонувший храм', 'Вы уверены, что хотите отправиться: Затонувший храм?'),
(50001, 17, 'ruRU', 'Ульдаман', 'Вы уверены, что хотите отправиться: Ульдаман?'),
(50001, 18, 'ruRU', 'Зул\'Фаррак', 'Вы уверены, что хотите отправиться: Зул\'Фаррак?'),
(50001, 19, 'ruRU', 'Назад..', NULL),
(50002, 0, 'ruRU', 'Аукиндон', 'Вы уверены, что хотите отправиться: Аукиндон?'),
(50002, 1, 'ruRU', 'Пещеры Времени', 'Вы уверены, что хотите отправиться: Пещеры Времени?'),
(50002, 2, 'ruRU', 'Резервуар Кривого Клыка', 'Вы уверены, что хотите отправиться: Резервуар Кривого Клыка?'),
(50002, 3, 'ruRU', 'Цитадель Адского Пламени', 'Вы уверены, что хотите отправиться: Цитадель Адского Пламени?'),
(50002, 4, 'ruRU', 'Терраса Магистров', 'Вы уверены, что хотите отправиться: Терраса Магистров?'),
(50002, 5, 'ruRU', 'Крепость Бурь', 'Вы уверены, что хотите отправиться: Крепость Бурь?'),
(50002, 6, 'ruRU', 'Назад..', NULL),
(50003, 0, 'ruRU', 'Азжол-Неруб', 'Вы уверены, что хотите отправиться: Азжол-Неруб?'),
(50003, 1, 'ruRU', 'Очищение Стратхольма', 'Вы уверены, что хотите отправиться: Очищение Стратхольма?'),
(50003, 2, 'ruRU', 'Испытание чемпиона', 'Вы уверены, что хотите отправиться: Испытание чемпиона?'),
(50003, 3, 'ruRU', 'Крепость Драк\'Тарон', 'Вы уверены, что хотите отправиться: Крепость Драк\'Тарон?'),
(50003, 4, 'ruRU', 'Гундрак', 'Вы уверены, что хотите отправиться: Гундрак?'),
(50003, 5, 'ruRU', 'Подземелья Цитадели Ледяной Короны', 'Вы уверены, что хотите отправиться: Подземелья Цитадели Ледяной Короны?'),
(50003, 6, 'ruRU', 'Подземелья Нексуса', 'Вы уверены, что хотите отправиться: Подземелья Нексуса?'),
(50003, 7, 'ruRU', 'Аметистовая крепость', 'Вы уверены, что хотите отправиться: Аметистовая крепость?'),
(50003, 8, 'ruRU', 'Чертоги Молний', 'Вы уверены, что хотите отправиться: Чертоги Молний?'),
(50003, 9, 'ruRU', 'Чертоги Камня', 'Вы уверены, что хотите отправиться: Чертоги Камня?'),
(50003, 10, 'ruRU', 'Крепость Утгард', 'Вы уверены, что хотите отправиться: Крепость Утгард?'),
(50003, 11, 'ruRU', 'Вершина Утгард', 'Вы уверены, что хотите отправиться: Вершина Утгард?'),
(50003, 12, 'ruRU', 'Назад..', NULL),
(50004, 0, 'ruRU', 'Черный храм', 'Вы уверены, что хотите отправиться: Черный храм?'),
(50004, 1, 'ruRU', 'Логово Крыла Тьмы', 'Вы уверены, что хотите отправиться: Логово Крыла Тьмы?'),
(50004, 2, 'ruRU', 'Вершина Хиджала', 'Вы уверены, что хотите отправиться: Вершина Хиджала?'),
(50004, 3, 'ruRU', 'Змеиное святилище', 'Вы уверены, что хотите отправиться: Змеиное святилище?'),
(50004, 4, 'ruRU', 'Испытание крестоносца', 'Вы уверены, что хотите отправиться: Испытание крестоносца?'),
(50004, 5, 'ruRU', 'Логово Груула', 'Вы уверены, что хотите отправиться: Логово Груула?'),
(50004, 6, 'ruRU', 'Логово Магтеридона', 'Вы уверены, что хотите отправиться: Логово Магтеридона?'),
(50004, 7, 'ruRU', 'Цитадель Ледяной Короны', 'Вы уверены, что хотите отправиться: Цитадель Ледяной Короны?'),
(50004, 8, 'ruRU', 'Каражан', 'Вы уверены, что хотите отправиться: Каражан?'),
(50004, 9, 'ruRU', 'Огненные Недра', 'Вы уверены, что хотите отправиться: Огненные Недра?'),
(50004, 10, 'ruRU', 'Наксрамас', 'Вы уверены, что хотите отправиться: Наксрамас?'),
(50004, 11, 'ruRU', 'Логово Ониксии', 'Вы уверены, что хотите отправиться: Логово Ониксии?'),
(50004, 12, 'ruRU', 'Руины Ан\'Киража', 'Вы уверены, что хотите отправиться: Руины Ан\'Киража?'),
(50004, 13, 'ruRU', 'Плато Солнечного Колодца', 'Вы уверены, что хотите отправиться: Плато Солнечного Колодца?'),
(50004, 14, 'ruRU', 'Око', 'Вы уверены, что хотите отправиться: Око?'),
(50004, 15, 'ruRU', 'Храм Ан\'Киража', 'Вы уверены, что хотите отправиться: Храм Ан\'Киража?'),
(50004, 16, 'ruRU', 'Око Вечности', 'Вы уверены, что хотите отправиться: Око Вечности?'),
(50004, 17, 'ruRU', 'Обсидиановое святилище', 'Вы уверены, что хотите отправиться: Обсидиановое святилище?'),
(50004, 18, 'ruRU', 'Ульдуар', 'Вы уверены, что хотите отправиться: Ульдуар?'),
(50004, 19, 'ruRU', 'Склеп Аркавона', 'Вы уверены, что хотите отправиться: Склеп Аркавона?'),
(50004, 21, 'ruRU', 'Зул\'Гуруб', 'Вы уверены, что хотите отправиться: Зул\'Гуруб?'),
(50004, 22, 'ruRU', 'Зул\'Аман', 'Вы уверены, что хотите отправиться: Зул\'Аман?'),
(50004, 23, 'ruRU', 'Назад..', NULL),
(50005, 0, 'ruRU', 'Элвиннский лес', 'Вы уверены, что хотите отправиться: Элвиннский лес?'),
(50005, 1, 'ruRU', 'Леса Вечной Песни', 'Вы уверены, что хотите отправиться: Леса Вечной Песни?'),
(50005, 2, 'ruRU', 'Дун Морог', 'Вы уверены, что хотите отправиться: Дун Морог?'),
(50005, 3, 'ruRU', 'Тирисфальские леса', 'Вы уверены, что хотите отправиться: Тирисфальские леса?'),
(50005, 4, 'ruRU', 'Призрачные земли', 'Вы уверены, что хотите отправиться: Призрачные земли?'),
(50005, 5, 'ruRU', 'Лок Модан', 'Вы уверены, что хотите отправиться: Лок Модан?'),
(50005, 6, 'ruRU', 'Серебряный бор', 'Вы уверены, что хотите отправиться: Серебряный бор?'),
(50005, 7, 'ruRU', 'Западный Край', 'Вы уверены, что хотите отправиться: Западный Край?'),
(50005, 8, 'ruRU', 'Красногорье', 'Вы уверены, что хотите отправиться: Красногорье?'),
(50005, 9, 'ruRU', 'Сумеречный лес', 'Вы уверены, что хотите отправиться: Сумеречный лес?'),
(50005, 10, 'ruRU', 'Предгорья Хилсбрада', 'Вы уверены, что хотите отправиться: Предгорья Хилсбрада?'),
(50005, 11, 'ruRU', 'Болотина', 'Вы уверены, что хотите отправиться: Болотина?'),
(50005, 12, 'ruRU', 'Альтеракские горы', 'Вы уверены, что хотите отправиться: Альтеракские горы?'),
(50005, 13, 'ruRU', 'Нагорье Арати', 'Вы уверены, что хотите отправиться: Нагорье Арати?'),
(50005, 14, 'ruRU', 'Тернистая долина', 'Вы уверены, что хотите отправиться: Тернистая долина?'),
(50005, 15, 'ruRU', 'Бесплодные земли', 'Вы уверены, что хотите отправиться: Бесплодные земли?'),
(50005, 16, 'ruRU', 'Болото Печали', 'Вы уверены, что хотите отправиться: Болото Печали?'),
(50005, 17, 'ruRU', 'Внутренние земли', 'Вы уверены, что хотите отправиться: Внутренние земли?'),
(50005, 18, 'ruRU', 'Тлеющее ущелье', 'Вы уверены, что хотите отправиться: Тлеющее ущелье?'),
(50005, 19, 'ruRU', 'Выжженные земли', 'Вы уверены, что хотите отправиться: Выжженные земли?'),
(50005, 20, 'ruRU', 'Пылающие степи', 'Вы уверены, что хотите отправиться: Пылающие степи?'),
(50005, 21, 'ruRU', 'Западные Чумные земли', 'Вы уверены, что хотите отправиться: Западные Чумные земли?'),
(50005, 22, 'ruRU', 'Восточные Чумные земли', 'Вы уверены, что хотите отправиться: Восточные Чумные земли?'),
(50005, 23, 'ruRU', 'Остров Кель\'Данас', 'Вы уверены, что хотите отправиться: Остров Кель\'Данас?'),
(50005, 24, 'ruRU', 'Назад..', NULL),
(50006, 0, 'ruRU', 'Остров Лазурной Дымки', 'Вы уверены, что хотите отправиться: Остров Лазурной Дымки?'),
(50006, 1, 'ruRU', 'Тельдрассил', 'Вы уверены, что хотите отправиться: Тельдрассил?'),
(50006, 2, 'ruRU', 'Дуротар', 'Вы уверены, что хотите отправиться: Дуротар?'),
(50006, 3, 'ruRU', 'Мулгор', 'Вы уверены, что хотите отправиться: Мулгор?'),
(50006, 4, 'ruRU', 'Остров Кровавой Дымки', 'Вы уверены, что хотите отправиться: Остров Кровавой Дымки?'),
(50006, 5, 'ruRU', 'Темные берега', 'Вы уверены, что хотите отправиться: Темные берега?'),
(50006, 6, 'ruRU', 'Степи', 'Вы уверены, что хотите отправиться: Степи?'),
(50006, 7, 'ruRU', 'Когтистые горы', 'Вы уверены, что хотите отправиться: Когтистые горы?'),
(50006, 8, 'ruRU', 'Ясеневый лес', 'Вы уверены, что хотите отправиться: Ясеневый лес?'),
(50006, 9, 'ruRU', 'Тысяча Игл', 'Вы уверены, что хотите отправиться: Тысяча Игл?'),
(50006, 10, 'ruRU', 'Пустоши', 'Вы уверены, что хотите отправиться: Пустоши?'),
(50006, 11, 'ruRU', 'Пылевые топи', 'Вы уверены, что хотите отправиться: Пылевые топи?'),
(50006, 12, 'ruRU', 'Фералас', 'Вы уверены, что хотите отправиться: Фералас?'),
(50006, 13, 'ruRU', 'Танарис', 'Вы уверены, что хотите отправиться: Танарис?'),
(50006, 14, 'ruRU', 'Азшара', 'Вы уверены, что хотите отправиться: Азшара?'),
(50006, 15, 'ruRU', 'Оскверненный лес', 'Вы уверены, что хотите отправиться: Оскверненный лес?'),
(50006, 16, 'ruRU', 'Кратер Ун\'Горо', 'Вы уверены, что хотите отправиться: Кратер Ун\'Горо?'),
(50006, 17, 'ruRU', 'Силитус', 'Вы уверены, что хотите отправиться: Силитус?'),
(50006, 18, 'ruRU', 'Зимние Ключи', 'Вы уверены, что хотите отправиться: Зимние Ключи?'),
(50006, 19, 'ruRU', 'Назад..', NULL),
(50007, 0, 'ruRU', 'Полуостров Адского Пламени', 'Вы уверены, что хотите отправиться: Полуостров Адского Пламени?'),
(50007, 1, 'ruRU', 'Зангартопь', 'Вы уверены, что хотите отправиться: Зангартопь?'),
(50007, 2, 'ruRU', 'Лес Тероккар', 'Вы уверены, что хотите отправиться: Лес Тероккар?'),
(50007, 3, 'ruRU', 'Награнд', 'Вы уверены, что хотите отправиться: Награнд?'),
(50007, 4, 'ruRU', 'Острогорье', 'Вы уверены, что хотите отправиться: Острогорье?'),
(50007, 5, 'ruRU', 'Пустоверть', 'Вы уверены, что хотите отправиться: Пустоверть?'),
(50007, 6, 'ruRU', 'Долина Призрачной Луны', 'Вы уверены, что хотите отправиться: Долина Призрачной Луны?'),
(50007, 7, 'ruRU', 'Назад..', NULL),
(50008, 0, 'ruRU', 'Борейская тундра', 'Вы уверены, что хотите отправиться: Борейская тундра?'),
(50008, 1, 'ruRU', 'Ревущий фьорд', 'Вы уверены, что хотите отправиться: Ревущий фьорд?'),
(50008, 2, 'ruRU', 'Драконий Погост', 'Вы уверены, что хотите отправиться: Драконий Погост?'),
(50008, 3, 'ruRU', 'Седые холмы', 'Вы уверены, что хотите отправиться: Седые холмы?'),
(50008, 4, 'ruRU', 'Зул\'Драк', 'Вы уверены, что хотите отправиться: Зул\'Драк?'),
(50008, 5, 'ruRU', 'Низина Шолазар', 'Вы уверены, что хотите отправиться: Низина Шолазар?'),
(50008, 6, 'ruRU', 'Лес Хрустальной Песни', 'Вы уверены, что хотите отправиться: Лес Хрустальной Песни?'),
(50008, 7, 'ruRU', 'Грозовая Гряда', 'Вы уверены, что хотите отправиться: Грозовая Гряда?'),
(50008, 8, 'ruRU', 'Ледяная Корона', 'Вы уверены, что хотите отправиться: Ледяная Корона?'),
(50008, 9, 'ruRU', 'Озеро Ледяных Оков', 'Вы уверены, что хотите отправиться: Озеро Ледяных Оков?'),
(50008, 10, 'ruRU', 'Назад..', NULL),
(51000, 0, 'ruRU', 'Я хочу спросить тебя кое о чем еще.', ''),
(51001, 0, 'ruRU', 'Я хочу спросить тебя кое о чем еще.', ''),
(51002, 0, 'ruRU', 'Я хочу спросить тебя кое о чем еще.', ''),
(51003, 0, 'ruRU', 'Я хочу спросить тебя кое о чем еще.', ''),
(61021, 0, 'ruRU', 'Я готов, Адьен', NULL),
(61025, 0, 'ruRU', 'Обучи меня.', '');



-- ---------------- 05_soobscheniya_servera.sql ----------------
-- =====================================================================
-- Системные сообщения сервера и ответы на команды
-- База: acore_world. Таблица: acore_string. Сгенерировано tools/gen.py
-- Перед применением остановите worldserver. Файл можно применять повторно.
-- =====================================================================
SET NAMES utf8mb4;

UPDATE `acore_string` SET `locale_ruRU`='Выберите персонажа или существо.' WHERE `entry`=1;
UPDATE `acore_string` SET `locale_ruRU`='Выберите существо.' WHERE `entry`=2;
UPDATE `acore_string` SET `locale_ruRU`='[СЕРВЕР] {}' WHERE `entry`=3;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Событие]: {}|r' WHERE `entry`=4;
UPDATE `acore_string` SET `locale_ruRU`='Справки по этой команде нет' WHERE `entry`=5;
UPDATE `acore_string` SET `locale_ruRU`='Команда \'{}\' не существует' WHERE `entry`=6;
UPDATE `acore_string` SET `locale_ruRU`='Подкоманда \'{}{}{}\' неоднозначна:' WHERE `entry`=7;
UPDATE `acore_string` SET `locale_ruRU`='Возможные подкоманды:' WHERE `entry`=8;
UPDATE `acore_string` SET `locale_ruRU`='Доступные вам команды:' WHERE `entry`=9;
UPDATE `acore_string` SET `locale_ruRU`='Неверный синтаксис.' WHERE `entry`=10;
UPDATE `acore_string` SET `locale_ruRU`='Уровень вашего аккаунта: {}' WHERE `entry`=11;
UPDATE `acore_string` SET `locale_ruRU`='Активных подключений: {} (макс.: {}) В очереди: {} (макс.: {})' WHERE `entry`=12;
UPDATE `acore_string` SET `locale_ruRU`='Время работы сервера: {}' WHERE `entry`=13;
UPDATE `acore_string` SET `locale_ruRU`='Игрок сохранён.' WHERE `entry`=14;
UPDATE `acore_string` SET `locale_ruRU`='Все игроки сохранены.' WHERE `entry`=15;
UPDATE `acore_string` SET `locale_ruRU`='На сервере сейчас находятся следующие ГМ:' WHERE `entry`=16;
UPDATE `acore_string` SET `locale_ruRU`='Сейчас на сервере нет ни одного ГМ.' WHERE `entry`=17;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя сделать это в полёте.' WHERE `entry`=18;
UPDATE `acore_string` SET `locale_ruRU`='Разница времени обновления: {}.' WHERE `entry`=19;
UPDATE `acore_string` SET `locale_ruRU`='До выключения/перезапуска осталось: {}' WHERE `entry`=20;
UPDATE `acore_string` SET `locale_ruRU`='{}: не удалось выполнить команду полёта.' WHERE `entry`=21;
UPDATE `acore_string` SET `locale_ruRU`='Вы не верхом, спешиваться не с чего.' WHERE `entry`=22;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя сделать это во время боя.' WHERE `entry`=23;
UPDATE `acore_string` SET `locale_ruRU`='Вы недавно это использовали.' WHERE `entry`=24;
UPDATE `acore_string` SET `locale_ruRU`='Пароль не изменён (неизвестная ошибка)!' WHERE `entry`=25;
UPDATE `acore_string` SET `locale_ruRU`='Пароль изменён' WHERE `entry`=26;
UPDATE `acore_string` SET `locale_ruRU`='Старый пароль неверен' WHERE `entry`=27;
UPDATE `acore_string` SET `locale_ruRU`='Ваш аккаунт заблокирован.' WHERE `entry`=28;
UPDATE `acore_string` SET `locale_ruRU`='Ваш аккаунт разблокирован.' WHERE `entry`=29;
UPDATE `acore_string` SET `locale_ruRU`=', ранг ' WHERE `entry`=30;
UPDATE `acore_string` SET `locale_ruRU`=' [известно]' WHERE `entry`=31;
UPDATE `acore_string` SET `locale_ruRU`=' [изучить]' WHERE `entry`=32;
UPDATE `acore_string` SET `locale_ruRU`=' [пассивное]' WHERE `entry`=33;
UPDATE `acore_string` SET `locale_ruRU`=' [талант]' WHERE `entry`=34;
UPDATE `acore_string` SET `locale_ruRU`=' [активно]' WHERE `entry`=35;
UPDATE `acore_string` SET `locale_ruRU`=' [выполнено]' WHERE `entry`=36;
UPDATE `acore_string` SET `locale_ruRU`=' (не в сети)' WHERE `entry`=37;
UPDATE `acore_string` SET `locale_ruRU`='вкл' WHERE `entry`=38;
UPDATE `acore_string` SET `locale_ruRU`='выкл' WHERE `entry`=39;
UPDATE `acore_string` SET `locale_ruRU`='Вы: {}' WHERE `entry`=40;
UPDATE `acore_string` SET `locale_ruRU`='видимы' WHERE `entry`=41;
UPDATE `acore_string` SET `locale_ruRU`='невидимы' WHERE `entry`=42;
UPDATE `acore_string` SET `locale_ruRU`='готово' WHERE `entry`=43;
UPDATE `acore_string` SET `locale_ruRU`='Вы' WHERE `entry`=44;
UPDATE `acore_string` SET `locale_ruRU`=' <неизвестно> ' WHERE `entry`=45;
UPDATE `acore_string` SET `locale_ruRU`='<ошибка>' WHERE `entry`=46;
UPDATE `acore_string` SET `locale_ruRU`='<несуществующий персонаж>' WHERE `entry`=47;
UPDATE `acore_string` SET `locale_ruRU`='НЕИЗВЕСТНО' WHERE `entry`=48;
UPDATE `acore_string` SET `locale_ruRU`='Для входа нужен уровень не ниже {}.' WHERE `entry`=49;
UPDATE `acore_string` SET `locale_ruRU`='Для входа нужен уровень не ниже {} и предмет {}.' WHERE `entry`=50;
UPDATE `acore_string` SET `locale_ruRU`='Привет! Готов к тренировке?' WHERE `entry`=51;
UPDATE `acore_string` SET `locale_ruRU`='Неверное количество ({}) для предмета {}' WHERE `entry`=52;
UPDATE `acore_string` SET `locale_ruRU`='В письме не может быть больше {} стопок предметов' WHERE `entry`=53;
UPDATE `acore_string` SET `locale_ruRU`='Новые пароли не совпадают' WHERE `entry`=54;
UPDATE `acore_string` SET `locale_ruRU`='Текущее сообщение дня:' WHERE `entry`=56;
UPDATE `acore_string` SET `locale_ruRU`='Мировая БД: {}' WHERE `entry`=57;
UPDATE `acore_string` SET `locale_ruRU`='Библиотека скриптов: {}' WHERE `entry`=58;
UPDATE `acore_string` SET `locale_ruRU`='EventAI существ: {}' WHERE `entry`=59;
UPDATE `acore_string` SET `locale_ruRU`='Игроков в сети: {} (макс.: {})' WHERE `entry`=60;
UPDATE `acore_string` SET `locale_ruRU`='Сейчас разрешены дополнения до {}.' WHERE `entry`=61;
UPDATE `acore_string` SET `locale_ruRU`='Один или несколько параметров имеют неверные значения' WHERE `entry`=62;
UPDATE `acore_string` SET `locale_ruRU`='Неверный id параметра: {}, не существует' WHERE `entry`=63;
UPDATE `acore_string` SET `locale_ruRU`='Неверный параметр realmId: {}' WHERE `entry`=64;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунту {} ({}) выданы права:' WHERE `entry`=65;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунту {} ({}) запрещены права:' WHERE `entry`=66;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт {} ({}) унаследовал права от уровня доступа {} ({}):' WHERE `entry`=67;
UPDATE `acore_string` SET `locale_ruRU`='Права:' WHERE `entry`=68;
UPDATE `acore_string` SET `locale_ruRU`='Связанные права:' WHERE `entry`=69;
UPDATE `acore_string` SET `locale_ruRU`='Список пуст' WHERE `entry`=70;
UPDATE `acore_string` SET `locale_ruRU`='- {} ({})' WHERE `entry`=71;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось выдать право {} ({}) realmId {}. У аккаунта {} ({}) оно уже есть' WHERE `entry`=72;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось выдать право {} ({}) realmId {}. У аккаунта {} ({}) оно в списке запретов' WHERE `entry`=73;
UPDATE `acore_string` SET `locale_ruRU`='Право {} ({}) realmId {} выдано аккаунту {} ({})' WHERE `entry`=74;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось запретить право {} ({}) realmId {}. Аккаунту {} ({}) оно уже запрещено' WHERE `entry`=75;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось запретить право {} ({}) realmId {}. У аккаунта {} ({}) оно в списке выданных' WHERE `entry`=76;
UPDATE `acore_string` SET `locale_ruRU`='Право {} ({}) realmId {} запрещено аккаунту {} ({})' WHERE `entry`=77;
UPDATE `acore_string` SET `locale_ruRU`='Право {} ({}) realmId {} отозвано у аккаунта {} ({})' WHERE `entry`=78;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось отозвать право {} ({}) realmId {}. У аккаунта {} ({}) его нет' WHERE `entry`=79;
UPDATE `acore_string` SET `locale_ruRU`='Победы на полях боя за последние 7 дней\nАльянс: {}\nОрда: {}' WHERE `entry`=80;
UPDATE `acore_string` SET `locale_ruRU`='Сохранение результатов полей боя отключено!' WHERE `entry`=81;
UPDATE `acore_string` SET `locale_ruRU`='{}: {}' WHERE `entry`=82;
UPDATE `acore_string` SET `locale_ruRU`='Синтаксис: .rbac account list $account\nПоказать выданные, запрещённые и унаследованные права аккаунта.' WHERE `entry`=83;
UPDATE `acore_string` SET `locale_ruRU`='Синтаксис: .rbac account grant $account $permissionId [$realmId]\nВыдать право аккаунту. Необязательный realmId (-1 = все миры).' WHERE `entry`=84;
UPDATE `acore_string` SET `locale_ruRU`='Синтаксис: .rbac account deny $account $permissionId [$realmId]\nЗапретить право аккаунту. Необязательный realmId (-1 = все миры).' WHERE `entry`=85;
UPDATE `acore_string` SET `locale_ruRU`='Синтаксис: .rbac account revoke $account $permissionId [$realmId]\nОтозвать ранее выданное или запрещённое право. Необязательный realmId (-1 = все миры).' WHERE `entry`=86;
UPDATE `acore_string` SET `locale_ruRU`='НЕИЗВЕСТНАЯ_ОШИБКА' WHERE `entry`=87;
UPDATE `acore_string` SET `locale_ruRU`='Команды двухфакторной аутентификации не настроены.' WHERE `entry`=88;
UPDATE `acore_string` SET `locale_ruRU`='Двухфакторная аутентификация для этого аккаунта уже включена.' WHERE `entry`=89;
UPDATE `acore_string` SET `locale_ruRU`='Указан неверный код двухфакторной аутентификации.' WHERE `entry`=90;
UPDATE `acore_string` SET `locale_ruRU`='Чтобы завершить настройку, подключите устройство, которое будет вторым фактором.\nВаш ключ 2FA: {}\nПосле настройки устройства подтвердите командой .account 2fa setup <код> с полученным кодом.' WHERE `entry`=91;
UPDATE `acore_string` SET `locale_ruRU`='Двухфакторная аутентификация успешно настроена.' WHERE `entry`=92;
UPDATE `acore_string` SET `locale_ruRU`='Двухфакторная аутентификация для этого аккаунта не включена.' WHERE `entry`=93;
UPDATE `acore_string` SET `locale_ruRU`='Чтобы отключить двухфакторную аутентификацию, укажите свежий код с вашего устройства.' WHERE `entry`=94;
UPDATE `acore_string` SET `locale_ruRU`='Двухфакторная аутентификация успешно отключена.' WHERE `entry`=95;
UPDATE `acore_string` SET `locale_ruRU`='Название гильдии \'{}\' уже занято' WHERE `entry`=96;
UPDATE `acore_string` SET `locale_ruRU`='Название гильдии \'{}\' изменено на \'{}\'' WHERE `entry`=97;
UPDATE `acore_string` SET `locale_ruRU`='Имя персонажа \'{}\' уже существует, выберите другое' WHERE `entry`=98;
UPDATE `acore_string` SET `locale_ruRU`='Игрок \'{}\' принудительно переименован в \'{}\'' WHERE `entry`=99;
UPDATE `acore_string` SET `locale_ruRU`='Общее оповещение: ' WHERE `entry`=100;
UPDATE `acore_string` SET `locale_ruRU`='Карта: {} ({}) Зона: {} ({}) Область: {} ({}) Фаза: {}\nX: {} Y: {} Z: {} Ориентация: {}\ngrid[{},{}]cell[{},{}] InstanceID: {}\n ZoneX: {} ZoneY: {}\nGroundZ: {} FloorZ: {} Данные высот (Map: {} VMap: {} MMap: {})' WHERE `entry`=101;
UPDATE `acore_string` SET `locale_ruRU`='{} уже телепортируется.' WHERE `entry`=102;
UPDATE `acore_string` SET `locale_ruRU`='Призвать игрока в своё подземелье можно, только если он в вашей группе, а вы — лидер.' WHERE `entry`=103;
UPDATE `acore_string` SET `locale_ruRU`='Вы не можете отправиться в подземелье игрока, так как сейчас состоите в группе.' WHERE `entry`=104;
UPDATE `acore_string` SET `locale_ruRU`='Отправиться в подземелье игрока, не состоя в его группе, можно только в режиме ГМ.' WHERE `entry`=105;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя переместиться к игроку {} из подземелья в подземелье.' WHERE `entry`=106;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя призвать игрока {} из подземелья в подземелье.' WHERE `entry`=107;
UPDATE `acore_string` SET `locale_ruRU`='Вы призываете {}{}.' WHERE `entry`=108;
UPDATE `acore_string` SET `locale_ruRU`='Вас призывает {}.' WHERE `entry`=109;
UPDATE `acore_string` SET `locale_ruRU`='Вы телепортируете {}{} в {}.' WHERE `entry`=110;
UPDATE `acore_string` SET `locale_ruRU`='Вас телепортирует {}.' WHERE `entry`=111;
UPDATE `acore_string` SET `locale_ruRU`='Игрок ({}) не существует.' WHERE `entry`=112;
UPDATE `acore_string` SET `locale_ruRU`='Перемещение к {}.' WHERE `entry`=113;
UPDATE `acore_string` SET `locale_ruRU`='{} перемещается к вам.' WHERE `entry`=114;
UPDATE `acore_string` SET `locale_ruRU`='Неверные значения.' WHERE `entry`=115;
UPDATE `acore_string` SET `locale_ruRU`='Персонаж не выбран.' WHERE `entry`=116;
UPDATE `acore_string` SET `locale_ruRU`='{} не состоит в группе.' WHERE `entry`=117;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили здоровье {} на {}/{}.' WHERE `entry`=118;
UPDATE `acore_string` SET `locale_ruRU`='{} изменил ваше здоровье на {}/{}.' WHERE `entry`=119;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили ману {} на {}/{}.' WHERE `entry`=120;
UPDATE `acore_string` SET `locale_ruRU`='{} изменил вашу ману на {}/{}.' WHERE `entry`=121;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили энергию {} на {}/{}.' WHERE `entry`=122;
UPDATE `acore_string` SET `locale_ruRU`='{} изменил вашу энергию на {}/{}.' WHERE `entry`=123;
UPDATE `acore_string` SET `locale_ruRU`='Текущая энергия: {}' WHERE `entry`=124;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили ярость {} на {}/{}.' WHERE `entry`=125;
UPDATE `acore_string` SET `locale_ruRU`='{} изменил вашу ярость на {}/{}.' WHERE `entry`=126;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили уровень {} на {}.' WHERE `entry`=127;
UPDATE `acore_string` SET `locale_ruRU`='GUID {}, фракция {}, flags {}, npcflag {}, DY flag {}' WHERE `entry`=128;
UPDATE `acore_string` SET `locale_ruRU`='Неверная фракция: {} (нет в factiontemplate.dbc).' WHERE `entry`=129;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили GUID={}: фракция {}, flags {}, npcflag {}, dyflag {}.' WHERE `entry`=130;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили spellflatid={}, val= {}, mark ={} для {}.' WHERE `entry`=131;
UPDATE `acore_string` SET `locale_ruRU`='{} изменил ваш spellflatid={}, val= {}, mark ={}.' WHERE `entry`=132;
UPDATE `acore_string` SET `locale_ruRU`='{} теперь имеет доступ ко всем точкам полётов (до выхода из игры).' WHERE `entry`=133;
UPDATE `acore_string` SET `locale_ruRU`='{} больше не имеет доступа ко всем точкам полётов (доступны только посещённые).' WHERE `entry`=134;
UPDATE `acore_string` SET `locale_ruRU`='{} открыл вам доступ ко всем точкам полётов (до выхода из игры).' WHERE `entry`=135;
UPDATE `acore_string` SET `locale_ruRU`='{} убрал доступ ко всем точкам полётов (доступны только посещённые).' WHERE `entry`=136;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили все скорости {} (обычная: {}).' WHERE `entry`=137;
UPDATE `acore_string` SET `locale_ruRU`='{} установил все ваши скорости на {} от обычной.' WHERE `entry`=138;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили скорость {} (обычная: {}).' WHERE `entry`=139;
UPDATE `acore_string` SET `locale_ruRU`='{} установил вашу скорость на {} от обычной.' WHERE `entry`=140;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили скорость плавания {} (обычная: {}).' WHERE `entry`=141;
UPDATE `acore_string` SET `locale_ruRU`='{} установил вашу скорость плавания на {} от обычной.' WHERE `entry`=142;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили скорость бега назад {} (обычная: {}).' WHERE `entry`=143;
UPDATE `acore_string` SET `locale_ruRU`='{} установил вашу скорость бега назад на {} от обычной.' WHERE `entry`=144;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили скорость полёта {} (обычная: {}).' WHERE `entry`=145;
UPDATE `acore_string` SET `locale_ruRU`='{} установил вашу скорость полёта на {} от обычной.' WHERE `entry`=146;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили размер {} для {}.' WHERE `entry`=147;
UPDATE `acore_string` SET `locale_ruRU`='{} установил ваш размер на {}.' WHERE `entry`=148;
UPDATE `acore_string` SET `locale_ruRU`='Такого транспорта нет.' WHERE `entry`=149;
UPDATE `acore_string` SET `locale_ruRU`='Вы выдали транспорт игроку {}.' WHERE `entry`=150;
UPDATE `acore_string` SET `locale_ruRU`='{} выдал вам транспорт.' WHERE `entry`=151;
UPDATE `acore_string` SET `locale_ruRU`='USER1: {}, ADD: {}, DIF: {}\n' WHERE `entry`=152;
UPDATE `acore_string` SET `locale_ruRU`='Вы забрали все деньги у {}.' WHERE `entry`=153;
UPDATE `acore_string` SET `locale_ruRU`='{} забрал у вас все деньги.' WHERE `entry`=154;
UPDATE `acore_string` SET `locale_ruRU`='Вы забрали {} меди у {}.' WHERE `entry`=155;
UPDATE `acore_string` SET `locale_ruRU`='{} забрал у вас {} меди.' WHERE `entry`=156;
UPDATE `acore_string` SET `locale_ruRU`='Вы дали {} меди игроку {}.' WHERE `entry`=157;
UPDATE `acore_string` SET `locale_ruRU`='{} дал вам {} меди.' WHERE `entry`=158;
UPDATE `acore_string` SET `locale_ruRU`='Вы слышите звук {}.' WHERE `entry`=159;
UPDATE `acore_string` SET `locale_ruRU`='USER2: {}, ADD: {}, RESULT: {}\n' WHERE `entry`=160;
UPDATE `acore_string` SET `locale_ruRU`='Сброшен бит {} в поле {}.' WHERE `entry`=161;
UPDATE `acore_string` SET `locale_ruRU`='Установлен бит {} в поле {}.' WHERE `entry`=162;
UPDATE `acore_string` SET `locale_ruRU`='Таблица точек телепорта пуста!' WHERE `entry`=163;
UPDATE `acore_string` SET `locale_ruRU`='Точка телепорта не найдена!' WHERE `entry`=164;
UPDATE `acore_string` SET `locale_ruRU`='Нужен параметр поиска.' WHERE `entry`=165;
UPDATE `acore_string` SET `locale_ruRU`='Нет точек телепорта, подходящих под запрос.' WHERE `entry`=166;
UPDATE `acore_string` SET `locale_ruRU`='Это имя зарезервировано, выберите другое' WHERE `entry`=167;
UPDATE `acore_string` SET `locale_ruRU`='Найденные точки:\n{}' WHERE `entry`=168;
UPDATE `acore_string` SET `locale_ruRU`='Письмо отправлено: {}' WHERE `entry`=169;
UPDATE `acore_string` SET `locale_ruRU`='Вы пытаетесь услышать звук {}, но его не существует.' WHERE `entry`=170;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя телепортировать себя к себе!' WHERE `entry`=171;
UPDATE `acore_string` SET `locale_ruRU`='команда серверной консоли' WHERE `entry`=172;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили силу рун {} на {}/{}.' WHERE `entry`=173;
UPDATE `acore_string` SET `locale_ruRU`='{} изменил вашу силу рун на {}/{}.' WHERE `entry`=174;
UPDATE `acore_string` SET `locale_ruRU`='Уровень жидкости: {}, земля: {}, тип: {}, флаги {}, состояние: {}.' WHERE `entry`=175;
UPDATE `acore_string` SET `locale_ruRU`='Неверный тип объекта: нужно разрушаемое здание.' WHERE `entry`=176;
UPDATE `acore_string` SET `locale_ruRU`='Объект {} (GUID: {}) повреждён на {} (текущая прочность: {}).' WHERE `entry`=177;
UPDATE `acore_string` SET `locale_ruRU`='grid[{},{}]cell[{},{}] InstanceID: {}\n ZoneX: {} ZoneY: {}\nGroundZ: {} FloorZ: {} Данные высот (Map: {} VMap: {} MMap: {})' WHERE `entry`=178;
UPDATE `acore_string` SET `locale_ruRU`='| Флаги аккаунта:' WHERE `entry`=179;
UPDATE `acore_string` SET `locale_ruRU`='TransMapID: {} TransOffsetX: {} TransOffsetY: {} TransOffsetZ: {} TransOffsetO: {} (ID транспорта: {} {})' WHERE `entry`=186;
UPDATE `acore_string` SET `locale_ruRU`='Это имя недопустимо, выберите другое' WHERE `entry`=187;
UPDATE `acore_string` SET `locale_ruRU`='Указанный секрет двухфакторной аутентификации слишком длинный.' WHERE `entry`=188;
UPDATE `acore_string` SET `locale_ruRU`='Указанный секрет двухфакторной аутентификации недействителен.' WHERE `entry`=189;
UPDATE `acore_string` SET `locale_ruRU`='Двухфакторная аутентификация для \'{}\' успешно включена с указанным секретом.' WHERE `entry`=190;
UPDATE `acore_string` SET `locale_ruRU`='|- {}' WHERE `entry`=191;
UPDATE `acore_string` SET `locale_ruRU`='|- {} ...' WHERE `entry`=192;
UPDATE `acore_string` SET `locale_ruRU`='Подкоманда \'{}{}{}\' не существует.' WHERE `entry`=193;
UPDATE `acore_string` SET `locale_ruRU`='Команда \'{}\' неоднозначна:' WHERE `entry`=194;
UPDATE `acore_string` SET `locale_ruRU`='### ИСПОЛЬЗОВАНИЕ: .{} ...' WHERE `entry`=195;
UPDATE `acore_string` SET `locale_ruRU`='Для \'{}\' нет подробного описания использования.\nДля стандартных команд AzerothCore такого быть не должно — если это произошло, сообщите об ошибке.' WHERE `entry`=196;
UPDATE `acore_string` SET `locale_ruRU`='Id восстановления: {} | Предмет: {} ({}) | Кол-во: {}' WHERE `entry`=197;
UPDATE `acore_string` SET `locale_ruRU`='У игрока нет предметов для восстановления' WHERE `entry`=198;
UPDATE `acore_string` SET `locale_ruRU`='У игрока нет восстанавливаемого предмета с id {}' WHERE `entry`=199;
UPDATE `acore_string` SET `locale_ruRU`='Ничего не выбрано.' WHERE `entry`=200;
UPDATE `acore_string` SET `locale_ruRU`='GUID объекта: {}' WHERE `entry`=201;
UPDATE `acore_string` SET `locale_ruRU`='Имя длиннее допустимого на {} символов.' WHERE `entry`=202;
UPDATE `acore_string` SET `locale_ruRU`='Ошибка: имя может содержать только символы A-Z и a-z.' WHERE `entry`=203;
UPDATE `acore_string` SET `locale_ruRU`='Подпись длиннее допустимой на {} символов.' WHERE `entry`=204;
UPDATE `acore_string` SET `locale_ruRU`='Ещё не реализовано' WHERE `entry`=205;
UPDATE `acore_string` SET `locale_ruRU`='Предмет \'{}\' \'{}\' добавлен в список (maxcount \'{}\', incrtime \'{}\', extendedcost \'{}\')' WHERE `entry`=206;
UPDATE `acore_string` SET `locale_ruRU`='Предмет \'{}\' не найден в базе данных.' WHERE `entry`=207;
UPDATE `acore_string` SET `locale_ruRU`='Предмет \'{}\' \'{}\' удалён из списка торговца' WHERE `entry`=208;
UPDATE `acore_string` SET `locale_ruRU`='Предмет \'{}\' не найден в списке торговца.' WHERE `entry`=209;
UPDATE `acore_string` SET `locale_ruRU`='Предмет \'{}\' (с extended cost {}) уже есть в списке торговца.' WHERE `entry`=210;
UPDATE `acore_string` SET `locale_ruRU`='Заклинания {} сброшены.' WHERE `entry`=211;
UPDATE `acore_string` SET `locale_ruRU`='Заклинания {} будут сброшены при следующем входе.' WHERE `entry`=212;
UPDATE `acore_string` SET `locale_ruRU`='Таланты {} сброшены.' WHERE `entry`=213;
UPDATE `acore_string` SET `locale_ruRU`='Таланты {} будут сброшены при следующем входе.' WHERE `entry`=214;
UPDATE `acore_string` SET `locale_ruRU`='Ваши заклинания сброшены.' WHERE `entry`=215;
UPDATE `acore_string` SET `locale_ruRU`='Ваши таланты сброшены.' WHERE `entry`=216;
UPDATE `acore_string` SET `locale_ruRU`='Неизвестный вариант \'{}\' для команды .resetall. Введите полное правильное название.' WHERE `entry`=217;
UPDATE `acore_string` SET `locale_ruRU`='Заклинания будут сброшены у всех игроков при входе. Настоятельно рекомендуется перезайти!' WHERE `entry`=218;
UPDATE `acore_string` SET `locale_ruRU`='Таланты будут сброшены у всех игроков при входе. Настоятельно рекомендуется перезайти!' WHERE `entry`=219;
UPDATE `acore_string` SET `locale_ruRU`='Существо (GUID: {}): точка маршрута не найдена.' WHERE `entry`=220;
UPDATE `acore_string` SET `locale_ruRU`='Существо (GUID: {}): последняя точка маршрута не найдена.' WHERE `entry`=221;
UPDATE `acore_string` SET `locale_ruRU`='Существо (GUID: {}): точка маршрута не найдена по \'wpguid\'. Пробуем найти по позиции...' WHERE `entry`=222;
UPDATE `acore_string` SET `locale_ruRU`='Для существа (GUID: {}) нет данных о маршруте. Убедитесь, что команда \'wp show on\' выполнена правильно.' WHERE `entry`=223;
UPDATE `acore_string` SET `locale_ruRU`='Выбранное существо игнорируется — используется указанный GUID' WHERE `entry`=224;
UPDATE `acore_string` SET `locale_ruRU`='Существо (GUID: {}) не найдено' WHERE `entry`=225;
UPDATE `acore_string` SET `locale_ruRU`='Выберите визуальную точку маршрута.' WHERE `entry`=226;
UPDATE `acore_string` SET `locale_ruRU`='Визуальные точки маршрута не найдены' WHERE `entry`=227;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось создать визуальную точку маршрута с creatureID: {}' WHERE `entry`=228;
UPDATE `acore_string` SET `locale_ruRU`='Все визуальные точки маршрута удалены' WHERE `entry`=229;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось создать существо-точку маршрута с ID: {}' WHERE `entry`=230;
UPDATE `acore_string` SET `locale_ruRU`='GUID не указан.' WHERE `entry`=231;
UPDATE `acore_string` SET `locale_ruRU`='Номер точки маршрута не указан.' WHERE `entry`=232;
UPDATE `acore_string` SET `locale_ruRU`='Для \'{}\' нужен аргумент.' WHERE `entry`=233;
UPDATE `acore_string` SET `locale_ruRU`='Точка маршрута {} добавлена к GUID: {}' WHERE `entry`=234;
UPDATE `acore_string` SET `locale_ruRU`='Точка маршрута {} добавлена.' WHERE `entry`=235;
UPDATE `acore_string` SET `locale_ruRU`='Точка маршрута изменена.' WHERE `entry`=236;
UPDATE `acore_string` SET `locale_ruRU`='Точка маршрута {} изменена.' WHERE `entry`=237;
UPDATE `acore_string` SET `locale_ruRU`='Экспорт маршрута выполнен.' WHERE `entry`=238;
UPDATE `acore_string` SET `locale_ruRU`='В базе данных нет точек маршрута.' WHERE `entry`=239;
UPDATE `acore_string` SET `locale_ruRU`='Файл импортирован.' WHERE `entry`=240;
UPDATE `acore_string` SET `locale_ruRU`='Точка маршрута удалена.' WHERE `entry`=241;
UPDATE `acore_string` SET `locale_ruRU`='Внимание: не удалось удалить точку маршрута из мира, ID: {}' WHERE `entry`=242;
UPDATE `acore_string` SET `locale_ruRU`='Это бывает, если точка маршрута слишком далеко от вашего персонажа.' WHERE `entry`=243;
UPDATE `acore_string` SET `locale_ruRU`='Точка удалена из базы данных, но не из мира.' WHERE `entry`=244;
UPDATE `acore_string` SET `locale_ruRU`='Они исчезнут после перезапуска сервера.' WHERE `entry`=245;
UPDATE `acore_string` SET `locale_ruRU`='Точка маршрута {}: данные существа: {}, GUID: {}' WHERE `entry`=246;
UPDATE `acore_string` SET `locale_ruRU`='Время ожидания: {}' WHERE `entry`=247;
UPDATE `acore_string` SET `locale_ruRU`='Модель {}: {}' WHERE `entry`=248;
UPDATE `acore_string` SET `locale_ruRU`='Эмоция: {}' WHERE `entry`=249;
UPDATE `acore_string` SET `locale_ruRU`='Заклинание: {}' WHERE `entry`=250;
UPDATE `acore_string` SET `locale_ruRU`='Текст{} (ID: {}): {}' WHERE `entry`=251;
UPDATE `acore_string` SET `locale_ruRU`='AI-скрипт: {}' WHERE `entry`=252;
UPDATE `acore_string` SET `locale_ruRU`='Игроку {} будет предложено сменить имя при следующем входе.' WHERE `entry`=253;
UPDATE `acore_string` SET `locale_ruRU`='Игроку {} (GUID #{}) будет предложено сменить имя при следующем входе.' WHERE `entry`=254;
UPDATE `acore_string` SET `locale_ruRU`='Существо-точка маршрута (GUID: {}) не найдено' WHERE `entry`=255;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось найти NPC...' WHERE `entry`=256;
UPDATE `acore_string` SET `locale_ruRU`='Тип движения существа: \'{}\', точки маршрута удалены (если были).' WHERE `entry`=257;
UPDATE `acore_string` SET `locale_ruRU`='Тип движения существа: \'{}\', точки маршрута не удалены.' WHERE `entry`=258;
UPDATE `acore_string` SET `locale_ruRU`='Неверное значение, используйте on или off' WHERE `entry`=259;
UPDATE `acore_string` SET `locale_ruRU`='Значение сохранено.' WHERE `entry`=260;
UPDATE `acore_string` SET `locale_ruRU`='Значение сохранено. Возможно, нужно перезайти или очистить кэш клиента.' WHERE `entry`=261;
UPDATE `acore_string` SET `locale_ruRU`='Areatrigger с ID {} не найден!' WHERE `entry`=262;
UPDATE `acore_string` SET `locale_ruRU`='Неверная карта или координаты (X: {} Y: {} MapId: {})' WHERE `entry`=263;
UPDATE `acore_string` SET `locale_ruRU`='Неверные координаты зоны (X: {} Y: {} AreaId: {})' WHERE `entry`=264;
UPDATE `acore_string` SET `locale_ruRU`='Зона {} ({}) — часть инстансовой карты {} ({})' WHERE `entry`=265;
UPDATE `acore_string` SET `locale_ruRU`='Ничего не найдено!' WHERE `entry`=266;
UPDATE `acore_string` SET `locale_ruRU`='Объект не найден!' WHERE `entry`=267;
UPDATE `acore_string` SET `locale_ruRU`='Существо не найдено!' WHERE `entry`=268;
UPDATE `acore_string` SET `locale_ruRU`='Внимание: существо найдено несколько раз — вы будете телепортированы к первому найденному в БД.' WHERE `entry`=269;
UPDATE `acore_string` SET `locale_ruRU`='Существо удалено' WHERE `entry`=270;
UPDATE `acore_string` SET `locale_ruRU`='Существо перемещено.' WHERE `entry`=271;
UPDATE `acore_string` SET `locale_ruRU`='Существо (GUID:{}) должно быть на той же карте, что и игрок!' WHERE `entry`=272;
UPDATE `acore_string` SET `locale_ruRU`='Игровой объект (GUID: {}) не найден' WHERE `entry`=273;
UPDATE `acore_string` SET `locale_ruRU`='Игровой объект (GUID: {}) упоминается в списке объектов ненайденного существа {}, удалить нельзя.' WHERE `entry`=274;
UPDATE `acore_string` SET `locale_ruRU`='Игровой объект (GUID: {}) удалён' WHERE `entry`=275;
UPDATE `acore_string` SET `locale_ruRU`='Игровой объект |cffffffff|Hgameobject:{}|h[{}]|h|r (GUID: {}) повёрнут' WHERE `entry`=276;
UPDATE `acore_string` SET `locale_ruRU`='Игровой объект |cffffffff|Hgameobject:{}|h[{}]|h|r (GUID: {}) перемещён' WHERE `entry`=277;
UPDATE `acore_string` SET `locale_ruRU`='Выберите торговца' WHERE `entry`=278;
UPDATE `acore_string` SET `locale_ruRU`='Укажите id предмета' WHERE `entry`=279;
UPDATE `acore_string` SET `locale_ruRU`='У торговца слишком много предметов (макс. 128)' WHERE `entry`=280;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя кикнуть себя, просто выйдите из игры' WHERE `entry`=281;
UPDATE `acore_string` SET `locale_ruRU`='Игрок {} кикнут.' WHERE `entry`=282;
UPDATE `acore_string` SET `locale_ruRU`='{} заблокировал чат {} на {}, начиная со следующего входа игрока. Причина: {}.' WHERE `entry`=283;
UPDATE `acore_string` SET `locale_ruRU`='Приём личных сообщений: {}' WHERE `entry`=284;
UPDATE `acore_string` SET `locale_ruRU`='Приём личных сообщений: ВКЛ' WHERE `entry`=285;
UPDATE `acore_string` SET `locale_ruRU`='Приём личных сообщений: ВЫКЛ' WHERE `entry`=286;
UPDATE `acore_string` SET `locale_ruRU`='Существо (GUID: {}) не найдено' WHERE `entry`=287;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя перейти к точке появления {}, их всего {}' WHERE `entry`=288;
UPDATE `acore_string` SET `locale_ruRU`='Новый тикет от {}' WHERE `entry`=289;
UPDATE `acore_string` SET `locale_ruRU`='Тикет {} (обновлён: {}):\n{}' WHERE `entry`=290;
UPDATE `acore_string` SET `locale_ruRU`='Показ новых тикетов: ВКЛ' WHERE `entry`=291;
UPDATE `acore_string` SET `locale_ruRU`='Показ новых тикетов: ВЫКЛ' WHERE `entry`=292;
UPDATE `acore_string` SET `locale_ruRU`='Тикет {} не существует' WHERE `entry`=293;
UPDATE `acore_string` SET `locale_ruRU`='Все тикеты удалены.' WHERE `entry`=294;
UPDATE `acore_string` SET `locale_ruRU`='Тикет персонажа {} удалён.' WHERE `entry`=295;
UPDATE `acore_string` SET `locale_ruRU`='Тикет удалён.' WHERE `entry`=296;
UPDATE `acore_string` SET `locale_ruRU`='Радиус блуждания изменён на: {}' WHERE `entry`=297;
UPDATE `acore_string` SET `locale_ruRU`='Время появления изменено на: {}' WHERE `entry`=298;
UPDATE `acore_string` SET `locale_ruRU`='Честь {} установлена на {}!' WHERE `entry`=299;
UPDATE `acore_string` SET `locale_ruRU`='Ваш чат заблокирован на {}. Кем: {}, причина: {}.' WHERE `entry`=300;
UPDATE `acore_string` SET `locale_ruRU`='{} заблокировал чат {} на {}. Причина: {}.' WHERE `entry`=301;
UPDATE `acore_string` SET `locale_ruRU`='Чат игрока уже разблокирован.' WHERE `entry`=302;
UPDATE `acore_string` SET `locale_ruRU`='Ваш чат разблокирован.' WHERE `entry`=303;
UPDATE `acore_string` SET `locale_ruRU`='Вы разблокировали чат {}.' WHERE `entry`=304;
UPDATE `acore_string` SET `locale_ruRU`='Репутация {} ({}) у {} установлена на {}!' WHERE `entry`=305;
UPDATE `acore_string` SET `locale_ruRU`='Очки арены {} установлены на {}!' WHERE `entry`=306;
UPDATE `acore_string` SET `locale_ruRU`='Фракция не найдена!' WHERE `entry`=307;
UPDATE `acore_string` SET `locale_ruRU`='Фракция {} неизвестна!' WHERE `entry`=308;
UPDATE `acore_string` SET `locale_ruRU`='Неверный параметр {}' WHERE `entry`=309;
UPDATE `acore_string` SET `locale_ruRU`='delta должна быть от 0 до {} включительно' WHERE `entry`=310;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Hfaction:{}|h[{}]|h|r' WHERE `entry`=311;
UPDATE `acore_string` SET `locale_ruRU`=' [видима]' WHERE `entry`=312;
UPDATE `acore_string` SET `locale_ruRU`=' [война]' WHERE `entry`=313;
UPDATE `acore_string` SET `locale_ruRU`=' [принудительный мир]' WHERE `entry`=314;
UPDATE `acore_string` SET `locale_ruRU`=' [скрыта]' WHERE `entry`=315;
UPDATE `acore_string` SET `locale_ruRU`=' [принудительно невидима]' WHERE `entry`=316;
UPDATE `acore_string` SET `locale_ruRU`=' [неактивна]' WHERE `entry`=317;
UPDATE `acore_string` SET `locale_ruRU`='Ненависть' WHERE `entry`=318;
UPDATE `acore_string` SET `locale_ruRU`='Враждебность' WHERE `entry`=319;
UPDATE `acore_string` SET `locale_ruRU`='Неприязнь' WHERE `entry`=320;
UPDATE `acore_string` SET `locale_ruRU`='Равнодушие' WHERE `entry`=321;
UPDATE `acore_string` SET `locale_ruRU`='Дружелюбие' WHERE `entry`=322;
UPDATE `acore_string` SET `locale_ruRU`='Уважение' WHERE `entry`=323;
UPDATE `acore_string` SET `locale_ruRU`='Почтение' WHERE `entry`=324;
UPDATE `acore_string` SET `locale_ruRU`='Превознесение' WHERE `entry`=325;
UPDATE `acore_string` SET `locale_ruRU`='У фракции {} ({}) не может быть репутации.' WHERE `entry`=326;
UPDATE `acore_string` SET `locale_ruRU`=' [нет репутации]' WHERE `entry`=327;
UPDATE `acore_string` SET `locale_ruRU`='Персонажи аккаунта {} (Id: {})' WHERE `entry`=328;
UPDATE `acore_string` SET `locale_ruRU`='  {} (GUID {})' WHERE `entry`=329;
UPDATE `acore_string` SET `locale_ruRU`='Игроки не найдены!' WHERE `entry`=330;
UPDATE `acore_string` SET `locale_ruRU`='Extended item cost {} не существует' WHERE `entry`=331;
UPDATE `acore_string` SET `locale_ruRU`='Режим ГМ ВКЛЮЧЁН' WHERE `entry`=332;
UPDATE `acore_string` SET `locale_ruRU`='Режим ГМ ВЫКЛЮЧЕН' WHERE `entry`=333;
UPDATE `acore_string` SET `locale_ruRU`='Значок ГМ в чате ВКЛЮЧЁН' WHERE `entry`=334;
UPDATE `acore_string` SET `locale_ruRU`='Значок ГМ в чате ВЫКЛЮЧЕН' WHERE `entry`=335;
UPDATE `acore_string` SET `locale_ruRU`='Вы починили все предметы {}.' WHERE `entry`=336;
UPDATE `acore_string` SET `locale_ruRU`='Все ваши предметы починил {}.' WHERE `entry`=337;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили режим хождения по воде {} для {}.' WHERE `entry`=338;
UPDATE `acore_string` SET `locale_ruRU`='Ваш режим хождения по воде {} (изменил {}).' WHERE `entry`=339;
UPDATE `acore_string` SET `locale_ruRU`='{} теперь следует за вами.' WHERE `entry`=340;
UPDATE `acore_string` SET `locale_ruRU`='{} не следует за вами.' WHERE `entry`=341;
UPDATE `acore_string` SET `locale_ruRU`='{} больше не следует за вами.' WHERE `entry`=342;
UPDATE `acore_string` SET `locale_ruRU`='Существо (Entry: {}) нельзя приручить.' WHERE `entry`=343;
UPDATE `acore_string` SET `locale_ruRU`='У вас уже есть питомец.' WHERE `entry`=344;
UPDATE `acore_string` SET `locale_ruRU`='Игроку {} будет предложено изменить внешность при следующем входе.' WHERE `entry`=345;
UPDATE `acore_string` SET `locale_ruRU`='Игроку {} (GUID #{}) будет предложено изменить внешность при следующем входе.' WHERE `entry`=346;
UPDATE `acore_string` SET `locale_ruRU`='TaxiNode с ID {} не найден!' WHERE `entry`=347;
UPDATE `acore_string` SET `locale_ruRU`='Игровой объект (Entry: {}) содержит неверные данные и не может быть создан' WHERE `entry`=348;
UPDATE `acore_string` SET `locale_ruRU`='{} (idx:{}) - |cffffffff|Htitle:{}|h[{} {}]|h|r {} {} ' WHERE `entry`=349;
UPDATE `acore_string` SET `locale_ruRU`='{} (idx:{}) - [{} {}] {} {} ' WHERE `entry`=350;
UPDATE `acore_string` SET `locale_ruRU`='Звания не найдены!' WHERE `entry`=351;
UPDATE `acore_string` SET `locale_ruRU`='Неверный id звания: {}' WHERE `entry`=352;
UPDATE `acore_string` SET `locale_ruRU`='Звание {} ({}) добавлено в список известных званий игрока {}.' WHERE `entry`=353;
UPDATE `acore_string` SET `locale_ruRU`='Звание {} ({}) удалено из списка известных званий игрока {}.' WHERE `entry`=354;
UPDATE `acore_string` SET `locale_ruRU`='Звание {} ({}) выбрано текущим для игрока {}.' WHERE `entry`=355;
UPDATE `acore_string` SET `locale_ruRU`='Текущее звание игрока {} сброшено, так как оно больше не известно.' WHERE `entry`=356;
UPDATE `acore_string` SET `locale_ruRU`='Состояние чит-команд:' WHERE `entry`=357;
UPDATE `acore_string` SET `locale_ruRU`='Бессмертие: {}.' WHERE `entry`=358;
UPDATE `acore_string` SET `locale_ruRU`='Время произнесения: {}.' WHERE `entry`=359;
UPDATE `acore_string` SET `locale_ruRU`='Восстановление: {}.' WHERE `entry`=360;
UPDATE `acore_string` SET `locale_ruRU`='Ресурс: {}.' WHERE `entry`=361;
UPDATE `acore_string` SET `locale_ruRU`='Хождение по воде: {}.' WHERE `entry`=362;
UPDATE `acore_string` SET `locale_ruRU`='Игрок {} больше не может писать вам личные сообщения.' WHERE `entry`=363;
UPDATE `acore_string` SET `locale_ruRU`='Точки полётов: {}.' WHERE `entry`=364;
UPDATE `acore_string` SET `locale_ruRU`='Удалено надетых предметов: |cffffffff{}|r у {}' WHERE `entry`=365;
UPDATE `acore_string` SET `locale_ruRU`='Удалено предметов в сумках: |cffffffff{}|r у {}' WHERE `entry`=366;
UPDATE `acore_string` SET `locale_ruRU`='Удалено предметов в банке: |cffffffff{}|r у {}' WHERE `entry`=367;
UPDATE `acore_string` SET `locale_ruRU`='Удалено ключей из связки: |cffffffff{}|r у {}' WHERE `entry`=368;
UPDATE `acore_string` SET `locale_ruRU`='Удалено валют: |cffffffff{}|r у {}' WHERE `entry`=369;
UPDATE `acore_string` SET `locale_ruRU`='Удалено предметов из выкупа у торговцев: |cffffffff{}|r у {}' WHERE `entry`=370;
UPDATE `acore_string` SET `locale_ruRU`='У {} удалены все предметы:\n|cffffffff{}|r надетых\n|cffffffff{}|r в сумках\n|cffffffff{}|r в банке\n|cffffffff{}|r ключей в связке\n|cffffffff{}|r видов валюты\n|cffffffff{}|r в выкупе у торговцев' WHERE `entry`=371;
UPDATE `acore_string` SET `locale_ruRU`='У {} удалены все предметы (включая сумки):\n|cffffffff{}|r надетых\n|cffffffff{}|r в сумках\n|cffffffff{}|r в банке\n|cffffffff{}|r ключей в связке\n|cffffffff{}|r видов валюты\n|cffffffff{}|r в выкупе у торговцев\n|cffffffff{}|r обычных сумок\n|cffffffff{}|r банковских сумок' WHERE `entry`=372;
UPDATE `acore_string` SET `locale_ruRU`='У цели нет ауры {}!' WHERE `entry`=373;
UPDATE `acore_string` SET `locale_ruRU`='Не указано количество стаков!' WHERE `entry`=374;
UPDATE `acore_string` SET `locale_ruRU`='Заклинание {} не может складываться!' WHERE `entry`=375;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Системное сообщение]:|rСкрипты перезагружены' WHERE `entry`=400;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили уровень доступа аккаунта {} на {}.' WHERE `entry`=401;
UPDATE `acore_string` SET `locale_ruRU`='{} изменил ваш уровень доступа на {}.' WHERE `entry`=402;
UPDATE `acore_string` SET `locale_ruRU`='У вас недостаточный уровень доступа.' WHERE `entry`=403;
UPDATE `acore_string` SET `locale_ruRU`='Движение существа отключено.' WHERE `entry`=404;
UPDATE `acore_string` SET `locale_ruRU`='Движение существа включено.' WHERE `entry`=405;
UPDATE `acore_string` SET `locale_ruRU`='Погоду в этой зоне изменить нельзя.' WHERE `entry`=406;
UPDATE `acore_string` SET `locale_ruRU`='Система погоды на сервере отключена.' WHERE `entry`=407;
UPDATE `acore_string` SET `locale_ruRU`='{} забанен на {}. Причина: {}.' WHERE `entry`=408;
UPDATE `acore_string` SET `locale_ruRU`='{} забанен навсегда. Причина: {}.' WHERE `entry`=409;
UPDATE `acore_string` SET `locale_ruRU`='{} {} не найден' WHERE `entry`=410;
UPDATE `acore_string` SET `locale_ruRU`='{} разбанен.' WHERE `entry`=411;
UPDATE `acore_string` SET `locale_ruRU`='Ошибка при снятии бана с {}.' WHERE `entry`=412;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт не существует: {}' WHERE `entry`=413;
UPDATE `acore_string` SET `locale_ruRU`='Такого персонажа нет. Помните, что имена чувствительны к РеГиСтРу!' WHERE `entry`=414;
UPDATE `acore_string` SET `locale_ruRU`='Такого IP нет в списке банов.' WHERE `entry`=415;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт {} никогда не был забанен' WHERE `entry`=416;
UPDATE `acore_string` SET `locale_ruRU`='История банов аккаунта {}:' WHERE `entry`=417;
UPDATE `acore_string` SET `locale_ruRU`='Дата бана: {} Срок: {} Активен: {}  Причина: {} Кем: {}' WHERE `entry`=418;
UPDATE `acore_string` SET `locale_ruRU`='Бессрочно' WHERE `entry`=419;
UPDATE `acore_string` SET `locale_ruRU`='Никогда' WHERE `entry`=420;
UPDATE `acore_string` SET `locale_ruRU`='Да' WHERE `entry`=421;
UPDATE `acore_string` SET `locale_ruRU`='Нет' WHERE `entry`=422;
UPDATE `acore_string` SET `locale_ruRU`='IP: {}\nДата бана: {}\nДата разбана: {}\nОсталось: {}\nПричина: {}\nКем: {}' WHERE `entry`=423;
UPDATE `acore_string` SET `locale_ruRU`='Подходящий бан по IP не найден.' WHERE `entry`=424;
UPDATE `acore_string` SET `locale_ruRU`='Подходящий аккаунт не найден.' WHERE `entry`=425;
UPDATE `acore_string` SET `locale_ruRU`='Нет забаненного аккаунта с персонажем, подходящим под этот запрос.' WHERE `entry`=426;
UPDATE `acore_string` SET `locale_ruRU`='Под ваш шаблон подходят IP:' WHERE `entry`=427;
UPDATE `acore_string` SET `locale_ruRU`='Под ваш запрос подходят аккаунты:' WHERE `entry`=428;
UPDATE `acore_string` SET `locale_ruRU`='Вы изучили множество заклинаний/навыков.' WHERE `entry`=429;
UPDATE `acore_string` SET `locale_ruRU`='Вы изучили все заклинания класса.' WHERE `entry`=430;
UPDATE `acore_string` SET `locale_ruRU`='Вы изучили все таланты класса.' WHERE `entry`=431;
UPDATE `acore_string` SET `locale_ruRU`='Вы изучили все языки.' WHERE `entry`=432;
UPDATE `acore_string` SET `locale_ruRU`='Вы изучили все ремесленные навыки и рецепты.' WHERE `entry`=433;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось найти \'{}\'' WHERE `entry`=434;
UPDATE `acore_string` SET `locale_ruRU`='Неверный id предмета: {}' WHERE `entry`=435;
UPDATE `acore_string` SET `locale_ruRU`='Предметы не найдены!' WHERE `entry`=436;
UPDATE `acore_string` SET `locale_ruRU`='Неверный id игрового объекта: {}' WHERE `entry`=437;
UPDATE `acore_string` SET `locale_ruRU`='Найдено предметов {}: {} (инвентарь {} почта {} аукцион {} гильдия {})' WHERE `entry`=438;
UPDATE `acore_string` SET `locale_ruRU`='Найдено игровых объектов {}: {} ' WHERE `entry`=439;
UPDATE `acore_string` SET `locale_ruRU`='Неверный id существа: {}' WHERE `entry`=440;
UPDATE `acore_string` SET `locale_ruRU`='Найдено существ {}: {} ' WHERE `entry`=441;
UPDATE `acore_string` SET `locale_ruRU`='Область не найдена!' WHERE `entry`=442;
UPDATE `acore_string` SET `locale_ruRU`='Комплекты предметов не найдены!' WHERE `entry`=443;
UPDATE `acore_string` SET `locale_ruRU`='Навыки не найдены!' WHERE `entry`=444;
UPDATE `acore_string` SET `locale_ruRU`='Заклинания не найдены!' WHERE `entry`=445;
UPDATE `acore_string` SET `locale_ruRU`='Задания не найдены!' WHERE `entry`=446;
UPDATE `acore_string` SET `locale_ruRU`='Существа не найдены!' WHERE `entry`=447;
UPDATE `acore_string` SET `locale_ruRU`='Игровые объекты не найдены!' WHERE `entry`=448;
UPDATE `acore_string` SET `locale_ruRU`='Кладбище #{} не существует.' WHERE `entry`=449;
UPDATE `acore_string` SET `locale_ruRU`='Кладбище #{} уже привязано к зоне #{} (текущей).' WHERE `entry`=450;
UPDATE `acore_string` SET `locale_ruRU`='Кладбище #{} привязано к зоне #{} (текущей).' WHERE `entry`=451;
UPDATE `acore_string` SET `locale_ruRU`='Кладбище #{} нельзя привязать к подзоне или несуществующей зоне #{} (внутренняя ошибка).' WHERE `entry`=452;
UPDATE `acore_string` SET `locale_ruRU`='До снятия бана: {}, забанил: {}, причина: {}' WHERE `entry`=453;
UPDATE `acore_string` SET `locale_ruRU`='У кладбища с id= #{} нет фракции, исправьте БД' WHERE `entry`=454;
UPDATE `acore_string` SET `locale_ruRU`='неверная сторона, исправьте базу данных' WHERE `entry`=455;
UPDATE `acore_string` SET `locale_ruRU`='любая' WHERE `entry`=456;
UPDATE `acore_string` SET `locale_ruRU`='Альянс' WHERE `entry`=457;
UPDATE `acore_string` SET `locale_ruRU`='Орда' WHERE `entry`=458;
UPDATE `acore_string` SET `locale_ruRU`='Кладбище #{} (фракция: {}) — ближайшее из привязанных к зоне #{}.' WHERE `entry`=459;
UPDATE `acore_string` SET `locale_ruRU`='К зоне #{} не привязано ни одного кладбища.' WHERE `entry`=460;
UPDATE `acore_string` SET `locale_ruRU`='К зоне #{} не привязано кладбищ для фракции: {}.' WHERE `entry`=461;
UPDATE `acore_string` SET `locale_ruRU`='Такая точка телепорта уже существует!' WHERE `entry`=462;
UPDATE `acore_string` SET `locale_ruRU`='Точка телепорта добавлена.' WHERE `entry`=463;
UPDATE `acore_string` SET `locale_ruRU`='Точка телепорта НЕ добавлена: ошибка базы данных.' WHERE `entry`=464;
UPDATE `acore_string` SET `locale_ruRU`='Точка телепорта удалена.' WHERE `entry`=465;
UPDATE `acore_string` SET `locale_ruRU`='Точки полётов не найдены!' WHERE `entry`=466;
UPDATE `acore_string` SET `locale_ruRU`='У цели аур: {}:' WHERE `entry`=467;
UPDATE `acore_string` SET `locale_ruRU`='id: {} {} effmask: {} заряды: {} стаки: {} слот {} длительность: {} макс. длительность: {} {} {} заклинатель: {} guid: {}' WHERE `entry`=468;
UPDATE `acore_string` SET `locale_ruRU`='У цели {} аур типа {}:' WHERE `entry`=469;
UPDATE `acore_string` SET `locale_ruRU`='id: {} eff: {} значение: {}' WHERE `entry`=470;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} не найдено.' WHERE `entry`=471;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} начинается с предмета. Для корректной работы положите предмет в инвентарь и возьмите задание обычным способом: .additem {}' WHERE `entry`=472;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} ({}) удалено.' WHERE `entry`=473;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} ({}): награда получена.' WHERE `entry`=474;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} ({}) выполнено.' WHERE `entry`=475;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} ({}) уже активно.' WHERE `entry`=476;
UPDATE `acore_string` SET `locale_ruRU`='Режим полёта {}: {}' WHERE `entry`=477;
UPDATE `acore_string` SET `locale_ruRU`='Опкод {} отправлен {}' WHERE `entry`=478;
UPDATE `acore_string` SET `locale_ruRU`='Персонаж успешно загружен!' WHERE `entry`=479;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось загрузить персонажа!' WHERE `entry`=480;
UPDATE `acore_string` SET `locale_ruRU`='Дамп персонажа успешно создан!' WHERE `entry`=481;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось создать дамп персонажа!' WHERE `entry`=482;
UPDATE `acore_string` SET `locale_ruRU`='Заклинание {} сломано, его нельзя применять или изучать!' WHERE `entry`=483;
UPDATE `acore_string` SET `locale_ruRU`='Навык {} ({}) игрока {} установлен на {}, текущий максимум — {} (без постоянных бонусов от талантов).' WHERE `entry`=484;
UPDATE `acore_string` SET `locale_ruRU`='Для этой команды у игрока {} должен быть навык {} ({}).' WHERE `entry`=485;
UPDATE `acore_string` SET `locale_ruRU`='Неверный id навыка ({})' WHERE `entry`=486;
UPDATE `acore_string` SET `locale_ruRU`='Вы изучили стандартные заклинания/навыки ГМ.' WHERE `entry`=487;
UPDATE `acore_string` SET `locale_ruRU`='Вы уже знаете это заклинание.' WHERE `entry`=488;
UPDATE `acore_string` SET `locale_ruRU`='Цель ({}) уже знает это заклинание.' WHERE `entry`=489;
UPDATE `acore_string` SET `locale_ruRU`='{} не знает это заклинание.' WHERE `entry`=490;
UPDATE `acore_string` SET `locale_ruRU`='Вы уже забыли это заклинание.' WHERE `entry`=491;
UPDATE `acore_string` SET `locale_ruRU`='Все восстановления заклинаний сброшены для {}.' WHERE `entry`=492;
UPDATE `acore_string` SET `locale_ruRU`='Восстановление заклинания {} сброшено для {}.' WHERE `entry`=493;
UPDATE `acore_string` SET `locale_ruRU`='Команда: Additem, itemId = {}, кол-во = {}' WHERE `entry`=494;
UPDATE `acore_string` SET `locale_ruRU`='Команда: Additemset, itemsetId = {}' WHERE `entry`=495;
UPDATE `acore_string` SET `locale_ruRU`='Удалено: itemID = {}, кол-во = {} у {}' WHERE `entry`=496;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось создать предмет \'{}\' (кол-во: {})' WHERE `entry`=497;
UPDATE `acore_string` SET `locale_ruRU`='Укажите название гильдии!' WHERE `entry`=498;
UPDATE `acore_string` SET `locale_ruRU`='Игрок не найден!' WHERE `entry`=499;
UPDATE `acore_string` SET `locale_ruRU`='Игрок уже состоит в гильдии!' WHERE `entry`=500;
UPDATE `acore_string` SET `locale_ruRU`='Гильдия не создана! (уже существует?)' WHERE `entry`=501;
UPDATE `acore_string` SET `locale_ruRU`='Не найдено предметов из комплекта \'{}\'.' WHERE `entry`=502;
UPDATE `acore_string` SET `locale_ruRU`='Расстояние: (3D) {} (2D) {} (точное 3D) {} (точное 2D) {} м.' WHERE `entry`=503;
UPDATE `acore_string` SET `locale_ruRU`='Предмет \'{}\' \'{}\' Ячейка {}' WHERE `entry`=504;
UPDATE `acore_string` SET `locale_ruRU`='Предмет \'{}\' не существует.' WHERE `entry`=505;
UPDATE `acore_string` SET `locale_ruRU`='Предмет \'{}\' \'{}\' добавлен в ячейку {}' WHERE `entry`=506;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось сохранить предмет!' WHERE `entry`=507;
UPDATE `acore_string` SET `locale_ruRU`='{} - владелец: {} (guid: {} аккаунт: {} ) {}' WHERE `entry`=508;
UPDATE `acore_string` SET `locale_ruRU`='{} - отправитель: {} (guid: {} аккаунт: {} ) получатель: {} (guid: {} аккаунт: {} ) {}' WHERE `entry`=509;
UPDATE `acore_string` SET `locale_ruRU`='{} - владелец: {} (guid: {} аккаунт: {} ) {}' WHERE `entry`=510;
UPDATE `acore_string` SET `locale_ruRU`='Неверный тип ссылки!' WHERE `entry`=511;
UPDATE `acore_string` SET `locale_ruRU`='{} - |c{}|Hitem:{}:0:0:0:0:0:0:0:0|h[{}]|h|r ' WHERE `entry`=512;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Hquest:{}:{}|h[{}]|h|r {}' WHERE `entry`=513;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Hcreature_entry:{}|h[{}]|h|r ' WHERE `entry`=514;
UPDATE `acore_string` SET `locale_ruRU`='{} - (entry: {}) |cffffffff|Hcreature:{}|h[{} X:{} Y:{} Z:{} MapId:{}]|h|r' WHERE `entry`=515;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Hgameobject_entry:{}|h[{}]|h|r ' WHERE `entry`=516;
UPDATE `acore_string` SET `locale_ruRU`='{} (Entry: {}) - |cffffffff|Hgameobject:{}|h[{} X:{} Y:{} Z:{} MapId:{}]|h|r ' WHERE `entry`=517;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Hitemset:{}|h[{} {}]|h|r ' WHERE `entry`=518;
UPDATE `acore_string` SET `locale_ruRU`='|cffffffff|Htele:{}|h[{}]|h|r ' WHERE `entry`=519;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Hspell:{}|h[{}]|h|r ' WHERE `entry`=520;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Hskill:{}|h[{} {}]|h|r {} {}' WHERE `entry`=521;
UPDATE `acore_string` SET `locale_ruRU`='Игровой объект (Entry: {}) не найден' WHERE `entry`=522;
UPDATE `acore_string` SET `locale_ruRU`='>> Игровой объект {} (GUID: {}) в точке {} {} {}. Ориентация {}.' WHERE `entry`=523;
UPDATE `acore_string` SET `locale_ruRU`='Выбранный объект:\n|cffffffff|Hgameobject:{}|h[{}]|h|r GUID: {} ID: {}\nX: {} Y: {} Z: {} MapId: {}\nОриентация: {}\nPhasemask {}' WHERE `entry`=524;
UPDATE `acore_string` SET `locale_ruRU`='>> Игровой объект \'{}\' ({}) (GUID: {}) добавлен в точке \'{} {} {}\'.' WHERE `entry`=525;
UPDATE `acore_string` SET `locale_ruRU`='{} (lowguid: {}) стек генераторов движения:' WHERE `entry`=526;
UPDATE `acore_string` SET `locale_ruRU`='   Покой' WHERE `entry`=527;
UPDATE `acore_string` SET `locale_ruRU`='   Случайное' WHERE `entry`=528;
UPDATE `acore_string` SET `locale_ruRU`='   По маршруту' WHERE `entry`=529;
UPDATE `acore_string` SET `locale_ruRU`='   Случайное (животное)' WHERE `entry`=530;
UPDATE `acore_string` SET `locale_ruRU`='   Растерянность' WHERE `entry`=531;
UPDATE `acore_string` SET `locale_ruRU`='   К игроку {} (lowguid {})' WHERE `entry`=532;
UPDATE `acore_string` SET `locale_ruRU`='   К существу {} (lowguid {})' WHERE `entry`=533;
UPDATE `acore_string` SET `locale_ruRU`='   К <NULL>' WHERE `entry`=534;
UPDATE `acore_string` SET `locale_ruRU`='   Возврат домой в (X:{} Y:{} Z:{})' WHERE `entry`=535;
UPDATE `acore_string` SET `locale_ruRU`='   Возврат домой у игрока?!?' WHERE `entry`=536;
UPDATE `acore_string` SET `locale_ruRU`='   Полёт на транспорте' WHERE `entry`=537;
UPDATE `acore_string` SET `locale_ruRU`='   Неизвестный генератор движения ({})' WHERE `entry`=538;
UPDATE `acore_string` SET `locale_ruRU`='Игрок выбрал NPC\nGUID в БД: {}, текущий GUID: {}.\nТекущий Entry: {} из ({}, {}, {}).\nDisplayID: {} (исходный: {}).\nФракция: {}.\nnpcFlags: {}.' WHERE `entry`=539;
UPDATE `acore_string` SET `locale_ruRU`='Уровень: {}.' WHERE `entry`=540;
UPDATE `acore_string` SET `locale_ruRU`='Здоровье (базовое): {}. (макс.): {}. (текущее): {}.' WHERE `entry`=541;
UPDATE `acore_string` SET `locale_ruRU`='Unit Flags: {}.\nUnit Flags 2: {}.\nDynamic Flags: {}.\nFaction Template: {}.' WHERE `entry`=542;
UPDATE `acore_string` SET `locale_ruRU`='Добыча: {} Карманы: {} Снятие шкур: {}' WHERE `entry`=543;
UPDATE `acore_string` SET `locale_ruRU`='Позиция: {} {} {}.' WHERE `entry`=544;
UPDATE `acore_string` SET `locale_ruRU`='* торговец ({})' WHERE `entry`=545;
UPDATE `acore_string` SET `locale_ruRU`='* учитель ({})' WHERE `entry`=546;
UPDATE `acore_string` SET `locale_ruRU`='InstanceID: {}' WHERE `entry`=547;
UPDATE `acore_string` SET `locale_ruRU`='Игрок{} {} (guid: {}) Аккаунт: {} (id: {}) Email: {} Уровень ГМ: {} Последний IP: {} Последний вход: {} Задержка: {}мс' WHERE `entry`=548;
UPDATE `acore_string` SET `locale_ruRU`='Раса: {} Класс: {} Время в игре: {} Уровень: {} Деньги: {}з{}с{}м' WHERE `entry`=549;
UPDATE `acore_string` SET `locale_ruRU`='До снятия мута: {}, кем: {}, причина: {}' WHERE `entry`=550;
UPDATE `acore_string` SET `locale_ruRU`='{} теперь исследовал все зоны.' WHERE `entry`=551;
UPDATE `acore_string` SET `locale_ruRU`='{} больше не имеет исследованных зон.' WHERE `entry`=552;
UPDATE `acore_string` SET `locale_ruRU`='{} открыл для вас все зоны.' WHERE `entry`=553;
UPDATE `acore_string` SET `locale_ruRU`='{} скрыл от вас все зоны.' WHERE `entry`=554;
UPDATE `acore_string` SET `locale_ruRU`='SetData выполнен для [GUID: {}, entry: {}, имя: {}] Поле: {}, Данные: {}, с {}' WHERE `entry`=555;
UPDATE `acore_string` SET `locale_ruRU`='Найдено существ поблизости (радиус {}): {} ' WHERE `entry`=556;
UPDATE `acore_string` SET `locale_ruRU`='{} повысил ваш уровень до ({})' WHERE `entry`=557;
UPDATE `acore_string` SET `locale_ruRU`='{} понизил ваш уровень до ({})' WHERE `entry`=558;
UPDATE `acore_string` SET `locale_ruRU`='{} сбросил прогресс вашего уровня.' WHERE `entry`=559;
UPDATE `acore_string` SET `locale_ruRU`='Область отмечена как исследованная.' WHERE `entry`=560;
UPDATE `acore_string` SET `locale_ruRU`='Область отмечена как неисследованная.' WHERE `entry`=561;
UPDATE `acore_string` SET `locale_ruRU`='GUID={}: updateIndex: {}, значение:  {}.' WHERE `entry`=562;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили у GUID={} UpdateIndex: {} на значение {}.' WHERE `entry`=563;
UPDATE `acore_string` SET `locale_ruRU`='Индекс значения {} слишком велик для {} (количество: {}).' WHERE `entry`=564;
UPDATE `acore_string` SET `locale_ruRU`='Set {} uint32 Value:[OPCODE]:{} [VALUE]:{}' WHERE `entry`=565;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили {} поле:{} в uint32 значение: {}' WHERE `entry`=566;
UPDATE `acore_string` SET `locale_ruRU`='Set {} float Value:[OPCODE]:{} [VALUE]:{}' WHERE `entry`=567;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили {} поле:{} в float значение: {}' WHERE `entry`=568;
UPDATE `acore_string` SET `locale_ruRU`='Get {} uint32 Value:[OPCODE]:{} [VALUE]:{}' WHERE `entry`=569;
UPDATE `acore_string` SET `locale_ruRU`='uint32 значение {} в {}: {}' WHERE `entry`=570;
UPDATE `acore_string` SET `locale_ruRU`='Get {} float Value:[OPCODE]:{} [VALUE]:{}' WHERE `entry`=571;
UPDATE `acore_string` SET `locale_ruRU`='float значение {} в {}: {}' WHERE `entry`=572;
UPDATE `acore_string` SET `locale_ruRU`='.Set32Bit:[OPCODE]:{} [VALUE]:{}' WHERE `entry`=573;
UPDATE `acore_string` SET `locale_ruRU`='Вы установили бит поля:{} в значение: {}' WHERE `entry`=574;
UPDATE `acore_string` SET `locale_ruRU`='.Mod32Value:[OPCODE]:{} [VALUE]:{}' WHERE `entry`=575;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили значение поля:{} на: {}' WHERE `entry`=576;
UPDATE `acore_string` SET `locale_ruRU`='Теперь вы невидимы.' WHERE `entry`=577;
UPDATE `acore_string` SET `locale_ruRU`='Теперь вы видимы.' WHERE `entry`=578;
UPDATE `acore_string` SET `locale_ruRU`='У выбранного игрока или существа нет цели атаки.' WHERE `entry`=579;
UPDATE `acore_string` SET `locale_ruRU`='Игрок {} изучил все стандартные заклинания расы/класса и заклинания за выполненные задания.' WHERE `entry`=580;
UPDATE `acore_string` SET `locale_ruRU`='Найдено игровых объектов поблизости (радиус {}): {} ' WHERE `entry`=581;
UPDATE `acore_string` SET `locale_ruRU`='Время появления: полное:{} осталось:{}' WHERE `entry`=582;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Hgameevent:{}|h[{}]|h|r{}' WHERE `entry`=583;
UPDATE `acore_string` SET `locale_ruRU`='События не найдены!' WHERE `entry`=584;
UPDATE `acore_string` SET `locale_ruRU`='Событие не существует!' WHERE `entry`=585;
UPDATE `acore_string` SET `locale_ruRU`='Событие {}: {}{}\nНачало: {} Конец: {} Периодичность: {} Длительность: {}\nСледующая смена состояния: {}' WHERE `entry`=586;
UPDATE `acore_string` SET `locale_ruRU`='Событие {} ({}) уже активно!' WHERE `entry`=587;
UPDATE `acore_string` SET `locale_ruRU`='Событие {} ({}) не активно!' WHERE `entry`=588;
UPDATE `acore_string` SET `locale_ruRU`='   Движение к точке (X:{} Y:{} Z:{})' WHERE `entry`=589;
UPDATE `acore_string` SET `locale_ruRU`='   Бегство в страхе' WHERE `entry`=590;
UPDATE `acore_string` SET `locale_ruRU`='   Отвлечение' WHERE `entry`=591;
UPDATE `acore_string` SET `locale_ruRU`='Вы изучили все рецепты ремесла: {}' WHERE `entry`=592;
UPDATE `acore_string` SET `locale_ruRU`='Забаненные аккаунты:' WHERE `entry`=593;
UPDATE `acore_string` SET `locale_ruRU`='|    Аккаунт    |  Дата бана   |  Дата разбана |    Кем       |    Причина    |' WHERE `entry`=594;
UPDATE `acore_string` SET `locale_ruRU`='Забаненные IP:' WHERE `entry`=595;
UPDATE `acore_string` SET `locale_ruRU`='|      IP       |  Дата бана   |  Дата разбана |    Кем       |    Причина    |' WHERE `entry`=596;
UPDATE `acore_string` SET `locale_ruRU`='Текущие ГМ:' WHERE `entry`=597;
UPDATE `acore_string` SET `locale_ruRU`='|    Аккаунт    |  ГМ  |' WHERE `entry`=598;
UPDATE `acore_string` SET `locale_ruRU`='ГМ нет.' WHERE `entry`=599;
UPDATE `acore_string` SET `locale_ruRU`='Событие {} ({}) запущено' WHERE `entry`=600;
UPDATE `acore_string` SET `locale_ruRU`='Событие {} ({}) остановлено' WHERE `entry`=601;
UPDATE `acore_string` SET `locale_ruRU`=' [награда получена]' WHERE `entry`=602;
UPDATE `acore_string` SET `locale_ruRU`='Do Action выполнен для [GUID: {}, entry: {}, имя: {}] Действие: {}' WHERE `entry`=603;
UPDATE `acore_string` SET `locale_ruRU`='Вы сможете снова говорить через {}.' WHERE `entry`=705;
UPDATE `acore_string` SET `locale_ruRU`='С надеванием/размещением этих предметов в инвентаре возникли проблемы.' WHERE `entry`=706;
UPDATE `acore_string` SET `locale_ruRU`='{} просит не беспокоить: {}' WHERE `entry`=707;
UPDATE `acore_string` SET `locale_ruRU`='{} отошёл: {}' WHERE `entry`=708;
UPDATE `acore_string` SET `locale_ruRU`='Не беспокоить' WHERE `entry`=709;
UPDATE `acore_string` SET `locale_ruRU`='Отошёл' WHERE `entry`=710;
UPDATE `acore_string` SET `locale_ruRU`='Очередь на {} (ур. {}–{})\nВ очереди Альянса: {} (нужно ещё минимум {})\nВ очереди Орды: {} (нужно ещё минимум {})' WHERE `entry`=711;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на поле боя]:|r {} -- [{}-{}] [{}/{}]|r' WHERE `entry`=712;
UPDATE `acore_string` SET `locale_ruRU`='Очередь на {} (стычка {}) (ур. {}–{})\nВ очереди: {} (нужно ещё минимум {})' WHERE `entry`=713;
UPDATE `acore_string` SET `locale_ruRU`='Карта: {}, Область: {}, Зона: {}, Фаза: {}' WHERE `entry`=714;
UPDATE `acore_string` SET `locale_ruRU`='Вы не соответствуете требованиям поля боя по уровню' WHERE `entry`=715;
UPDATE `acore_string` SET `locale_ruRU`='Карта: {}, Область: {}' WHERE `entry`=716;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на поле боя]:|r {} -- [{}-{}] Началось!|r' WHERE `entry`=717;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r {} -- Вступили: {}x{} : {}|r' WHERE `entry`=718;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r {} -- Вышли: {}x{} : {}|r' WHERE `entry`=719;
UPDATE `acore_string` SET `locale_ruRU`='Ваша группа слишком велика для этого поля боя. Перегруппируйтесь, чтобы вступить.' WHERE `entry`=720;
UPDATE `acore_string` SET `locale_ruRU`='Ваша группа слишком велика для этой арены. Перегруппируйтесь, чтобы вступить.' WHERE `entry`=721;
UPDATE `acore_string` SET `locale_ruRU`='В вашей группе есть игроки не из вашей команды арены. Перегруппируйтесь, чтобы вступить.' WHERE `entry`=722;
UPDATE `acore_string` SET `locale_ruRU`='В вашей группе недостаточно игроков для этого матча.' WHERE `entry`=723;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r {} (стычка {}) -- [{}-{}] [{}/{}]|r' WHERE `entry`=726;
UPDATE `acore_string` SET `locale_ruRU`='В вашей группе есть игрок не в сети. Исключите его перед вступлением.' WHERE `entry`=727;
UPDATE `acore_string` SET `locale_ruRU`='В вашей группе есть игроки противоположной фракции. Вступить на поле боя группой нельзя.' WHERE `entry`=728;
UPDATE `acore_string` SET `locale_ruRU`='В вашей группе игроки из разных уровневых диапазонов поля боя. Вступить группой нельзя.' WHERE `entry`=729;
UPDATE `acore_string` SET `locale_ruRU`='Кто-то из вашей группы уже стоит в очереди на это поле боя. Ему нужно выйти из неё, чтобы вступить группой.' WHERE `entry`=730;
UPDATE `acore_string` SET `locale_ruRU`='Кто-то из вашей группы — дезертир. Вступить группой нельзя.' WHERE `entry`=731;
UPDATE `acore_string` SET `locale_ruRU`='Кто-то из вашей группы уже стоит в трёх очередях на поля боя. Вступить группой нельзя.' WHERE `entry`=732;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя телепортироваться на карту поля боя или арены.' WHERE `entry`=733;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя призывать игроков на карту поля боя или арены.' WHERE `entry`=734;
UPDATE `acore_string` SET `locale_ruRU`='Чтобы телепортироваться к игроку на поле боя, нужен режим ГМ.' WHERE `entry`=735;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя телепортироваться на поле боя с другого поля боя. Сначала покиньте текущее.' WHERE `entry`=736;
UPDATE `acore_string` SET `locale_ruRU`='Арены переведены в режим 1х1 для отладки. Не вступайте группой.' WHERE `entry`=737;
UPDATE `acore_string` SET `locale_ruRU`='Арены переведены в обычный режим по числу игроков.' WHERE `entry`=738;
UPDATE `acore_string` SET `locale_ruRU`='Поля боя переведены в режим 1х0 для отладки.' WHERE `entry`=739;
UPDATE `acore_string` SET `locale_ruRU`='Поля боя переведены в обычный режим по числу игроков.' WHERE `entry`=740;
UPDATE `acore_string` SET `locale_ruRU`='Начисление очков арены по рейтингу команд, это может занять несколько минут. Подождите...' WHERE `entry`=741;
UPDATE `acore_string` SET `locale_ruRU`='Распределение очков арены между игроками...' WHERE `entry`=742;
UPDATE `acore_string` SET `locale_ruRU`='Очки арены игрокам в сети начислены.' WHERE `entry`=743;
UPDATE `acore_string` SET `locale_ruRU`='Обновление числа игр, очков арены и т.д. для загруженных команд арены, отправка статистики игрокам в сети...' WHERE `entry`=744;
UPDATE `acore_string` SET `locale_ruRU`='Изменения выполнены.' WHERE `entry`=745;
UPDATE `acore_string` SET `locale_ruRU`='Начисление очков арены завершено.' WHERE `entry`=746;
UPDATE `acore_string` SET `locale_ruRU`='Это поле боя отключено. Встать в очередь нельзя.' WHERE `entry`=747;
UPDATE `acore_string` SET `locale_ruRU`='Арены отключены. Встать в очередь нельзя.' WHERE `entry`=748;
UPDATE `acore_string` SET `locale_ruRU`='¦ ОС: {} - Задержка: {} мс' WHERE `entry`=749;
UPDATE `acore_string` SET `locale_ruRU`='Недостаточно игроков. Игра закроется через {} мин.' WHERE `entry`=750;
UPDATE `acore_string` SET `locale_ruRU`='Недостаточно игроков. Игра закроется через {} сек.' WHERE `entry`=751;
UPDATE `acore_string` SET `locale_ruRU`='¦ Последний IP: {} (Привязка: {})' WHERE `entry`=752;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r {} -- Вступили: {}x{}|r' WHERE `entry`=773;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r {} -- Вышли: {}x{}|r' WHERE `entry`=774;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r Вступили: {}x{} : {}|r' WHERE `entry`=775;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r Вышли: {}x{} : {}|r' WHERE `entry`=776;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r Вступили: {}x{}|r' WHERE `entry`=777;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Очередь на арену]:|r Вышли: {}x{}|r' WHERE `entry`=778;
UPDATE `acore_string` SET `locale_ruRU`='Тестирование арены: {}' WHERE `entry`=785;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Автоматически]:|r' WHERE `entry`=786;
UPDATE `acore_string` SET `locale_ruRU`='|cffffff00[|c1f40af20Объявление от|r |cffff0000{}|cffffff00]:|r {}|r' WHERE `entry`=787;
UPDATE `acore_string` SET `locale_ruRU`='Недопустимое имя' WHERE `entry`=800;
UPDATE `acore_string` SET `locale_ruRU`='У вас недостаточно золота' WHERE `entry`=801;
UPDATE `acore_string` SET `locale_ruRU`='У вас недостаточно свободных ячеек' WHERE `entry`=802;
UPDATE `acore_string` SET `locale_ruRU`='У вашего партнёра недостаточно свободных ячеек в сумках' WHERE `entry`=803;
UPDATE `acore_string` SET `locale_ruRU`='У вас нет прав на это действие' WHERE `entry`=804;
UPDATE `acore_string` SET `locale_ruRU`='Неизвестный язык' WHERE `entry`=805;
UPDATE `acore_string` SET `locale_ruRU`='Вы не знаете этого языка' WHERE `entry`=806;
UPDATE `acore_string` SET `locale_ruRU`='Укажите имя персонажа' WHERE `entry`=807;
UPDATE `acore_string` SET `locale_ruRU`='Игрок {} не найден или не в сети' WHERE `entry`=808;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт персонажа {} не найден' WHERE `entry`=809;
UPDATE `acore_string` SET `locale_ruRU`='Глава гильдии' WHERE `entry`=811;
UPDATE `acore_string` SET `locale_ruRU`='Офицер' WHERE `entry`=812;
UPDATE `acore_string` SET `locale_ruRU`='Ветеран' WHERE `entry`=813;
UPDATE `acore_string` SET `locale_ruRU`='Участник' WHERE `entry`=814;
UPDATE `acore_string` SET `locale_ruRU`='Новичок' WHERE `entry`=815;
UPDATE `acore_string` SET `locale_ruRU`='Внимание: вы вошли в зону, где полёты запрещены, и сейчас будете спешены!' WHERE `entry`=816;
UPDATE `acore_string` SET `locale_ruRU`='Entry {} не найден в таблице creature_template.' WHERE `entry`=817;
UPDATE `acore_string` SET `locale_ruRU`='Entry {} не найден в sCreatureStorage. Возможно, это новая строка в creature_template, но добавлять новых существ без перезапуска нельзя — разрешено только изменение.' WHERE `entry`=818;
UPDATE `acore_string` SET `locale_ruRU`='Город' WHERE `entry`=819;
UPDATE `acore_string` SET `locale_ruRU`='* есть диалог ({})' WHERE `entry`=820;
UPDATE `acore_string` SET `locale_ruRU`='* выдаёт задания ({})' WHERE `entry`=821;
UPDATE `acore_string` SET `locale_ruRU`='* учитель класса ({})' WHERE `entry`=822;
UPDATE `acore_string` SET `locale_ruRU`='* учитель профессии ({})' WHERE `entry`=823;
UPDATE `acore_string` SET `locale_ruRU`='* торговец боеприпасами ({})' WHERE `entry`=824;
UPDATE `acore_string` SET `locale_ruRU`='* торговец едой ({})' WHERE `entry`=825;
UPDATE `acore_string` SET `locale_ruRU`='* торговец ядами ({})' WHERE `entry`=826;
UPDATE `acore_string` SET `locale_ruRU`='* торговец реагентами ({})' WHERE `entry`=827;
UPDATE `acore_string` SET `locale_ruRU`='* может чинить ({})' WHERE `entry`=828;
UPDATE `acore_string` SET `locale_ruRU`='* распорядитель полётов ({})' WHERE `entry`=829;
UPDATE `acore_string` SET `locale_ruRU`='* целитель душ ({})' WHERE `entry`=830;
UPDATE `acore_string` SET `locale_ruRU`='* проводник духов ({})' WHERE `entry`=831;
UPDATE `acore_string` SET `locale_ruRU`='* хозяин таверны ({})' WHERE `entry`=832;
UPDATE `acore_string` SET `locale_ruRU`='* банкир ({})' WHERE `entry`=833;
UPDATE `acore_string` SET `locale_ruRU`='* регистратор ({})' WHERE `entry`=834;
UPDATE `acore_string` SET `locale_ruRU`='* изготовитель гербовых накидок ({})' WHERE `entry`=835;
UPDATE `acore_string` SET `locale_ruRU`='* военачальник ({})' WHERE `entry`=836;
UPDATE `acore_string` SET `locale_ruRU`='* аукционист ({})' WHERE `entry`=837;
UPDATE `acore_string` SET `locale_ruRU`='* смотритель стойл ({})' WHERE `entry`=838;
UPDATE `acore_string` SET `locale_ruRU`='* банкир гильдии ({})' WHERE `entry`=839;
UPDATE `acore_string` SET `locale_ruRU`='* реагирует на клик ({})' WHERE `entry`=840;
UPDATE `acore_string` SET `locale_ruRU`='* почтовый ящик ({})' WHERE `entry`=841;
UPDATE `acore_string` SET `locale_ruRU`='* транспорт игрока ({})' WHERE `entry`=842;
UPDATE `acore_string` SET `locale_ruRU`='¦ Уровень: {} ({}/{} опыта (осталось {}))' WHERE `entry`=843;
UPDATE `acore_string` SET `locale_ruRU`='¦ Раса: {} {}, {}' WHERE `entry`=844;
UPDATE `acore_string` SET `locale_ruRU`='¦ Жив?: {}' WHERE `entry`=845;
UPDATE `acore_string` SET `locale_ruRU`='¦ Фаза: {}' WHERE `entry`=846;
UPDATE `acore_string` SET `locale_ruRU`='¦ Деньги: {}з{}с{}м' WHERE `entry`=847;
UPDATE `acore_string` SET `locale_ruRU`='¦ Карта: {}, Зона: {}' WHERE `entry`=848;
UPDATE `acore_string` SET `locale_ruRU`='¦ Гильдия: {} (ID: {})' WHERE `entry`=849;
UPDATE `acore_string` SET `locale_ruRU`='├─ Звание: {}' WHERE `entry`=850;
UPDATE `acore_string` SET `locale_ruRU`='├─ Заметка: {}' WHERE `entry`=851;
UPDATE `acore_string` SET `locale_ruRU`='├─ Заметка офицера: {}' WHERE `entry`=852;
UPDATE `acore_string` SET `locale_ruRU`='¦ Время в игре: {}' WHERE `entry`=853;
UPDATE `acore_string` SET `locale_ruRU`='¦ Письма: {} прочитано/{} всего' WHERE `entry`=854;
UPDATE `acore_string` SET `locale_ruRU`='Мужской' WHERE `entry`=855;
UPDATE `acore_string` SET `locale_ruRU`='Женский' WHERE `entry`=856;
UPDATE `acore_string` SET `locale_ruRU`='Команда арены [{}] не найдена' WHERE `entry`=857;
UPDATE `acore_string` SET `locale_ruRU`='Команда арены с названием "{}" уже существует' WHERE `entry`=858;
UPDATE `acore_string` SET `locale_ruRU`='{} уже состоит в команде арены такого размера' WHERE `entry`=859;
UPDATE `acore_string` SET `locale_ruRU`='Команда арены в бою' WHERE `entry`=860;
UPDATE `acore_string` SET `locale_ruRU`='Арена с названием "{}" или похожим не найдена' WHERE `entry`=861;
UPDATE `acore_string` SET `locale_ruRU`='[{}] не состоит в команде "{}"' WHERE `entry`=862;
UPDATE `acore_string` SET `locale_ruRU`='[{}] уже капитан команды "{}"' WHERE `entry`=863;
UPDATE `acore_string` SET `locale_ruRU`='Создана команда арены [Название: "{}"][Id: {}][Тип: {}][GUID капитана: {}]' WHERE `entry`=864;
UPDATE `acore_string` SET `locale_ruRU`='Команда арены "{}"[Id: {}] распущена' WHERE `entry`=865;
UPDATE `acore_string` SET `locale_ruRU`='Команда арены [Id: {}] переименована из "{}" в "{}"' WHERE `entry`=866;
UPDATE `acore_string` SET `locale_ruRU`='Команда арены "{}"[Id: {}]: капитан сменён с [{}] на [{}]' WHERE `entry`=867;
UPDATE `acore_string` SET `locale_ruRU`='Команда арены: "{}"[{}] - Рейтинг: {} - Тип: {}x{}' WHERE `entry`=868;
UPDATE `acore_string` SET `locale_ruRU`='Имя:"{}"[guid:{}] - ЛР: {} - {}' WHERE `entry`=869;
UPDATE `acore_string` SET `locale_ruRU`='|"{}"[ID:{}]({}x{})|' WHERE `entry`=870;
UPDATE `acore_string` SET `locale_ruRU`='¦ Уровень: {}' WHERE `entry`=871;
UPDATE `acore_string` SET `locale_ruRU`='Введённый email не совпадает с email регистрации, проверьте ввод' WHERE `entry`=872;
UPDATE `acore_string` SET `locale_ruRU`='Новые email не совпадают' WHERE `entry`=873;
UPDATE `acore_string` SET `locale_ruRU`='Email изменён' WHERE `entry`=874;
UPDATE `acore_string` SET `locale_ruRU`='Email не может быть длиннее 255 символов, email не изменён!' WHERE `entry`=875;
UPDATE `acore_string` SET `locale_ruRU`='Email не изменён (неизвестная ошибка)!' WHERE `entry`=876;
UPDATE `acore_string` SET `locale_ruRU`='Менять не нужно: новый email совпадает со старым' WHERE `entry`=877;
UPDATE `acore_string` SET `locale_ruRU`='Ваш email: {}' WHERE `entry`=878;
UPDATE `acore_string` SET `locale_ruRU`='¦ Email регистрации: {} - Email: {}' WHERE `entry`=879;
UPDATE `acore_string` SET `locale_ruRU`='Уровень доступа: {}' WHERE `entry`=880;
UPDATE `acore_string` SET `locale_ruRU`='Для смены пароля нужен email.' WHERE `entry`=881;
UPDATE `acore_string` SET `locale_ruRU`='Для входа нужно выполнить задания:' WHERE `entry`=882;
UPDATE `acore_string` SET `locale_ruRU`='Для входа нужно получить достижения:' WHERE `entry`=883;
UPDATE `acore_string` SET `locale_ruRU`='Для входа в инвентаре должны быть предметы:' WHERE `entry`=884;
UPDATE `acore_string` SET `locale_ruRU`='- Примечание:' WHERE `entry`=885;
UPDATE `acore_string` SET `locale_ruRU`='Вход невозможен. Требования не выполнены.' WHERE `entry`=886;
UPDATE `acore_string` SET `locale_ruRU`='Для входа средний уровень предметов вашей экипировки должен быть не ниже {}. Сейчас он равен: {}.' WHERE `entry`=887;
UPDATE `acore_string` SET `locale_ruRU`='Для входа ваш уровень должен быть ниже {}.' WHERE `entry`=888;
UPDATE `acore_string` SET `locale_ruRU`='Для входа лидер группы ({}) должен выполнить задания:' WHERE `entry`=889;
UPDATE `acore_string` SET `locale_ruRU`='Для входа лидер группы ({}) должен получить достижения:' WHERE `entry`=890;
UPDATE `acore_string` SET `locale_ruRU`='Для входа у лидера группы ({}) в инвентаре должны быть предметы:' WHERE `entry`=891;
UPDATE `acore_string` SET `locale_ruRU`='Завершение работы службы...' WHERE `entry`=1000;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт удалён: {}' WHERE `entry`=1001;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт {} НЕ удалён (вероятно, изменился формат sql-файла)' WHERE `entry`=1002;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт {} НЕ удалён (неизвестная ошибка)' WHERE `entry`=1003;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт создан: {}' WHERE `entry`=1004;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт с таким именем уже существует!' WHERE `entry`=1006;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт {} НЕ создан (вероятно, изменился формат sql-файла)' WHERE `entry`=1007;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт {} НЕ создан (неизвестная ошибка)' WHERE `entry`=1008;
UPDATE `acore_string` SET `locale_ruRU`='Игрок {} (Guid: {}) Аккаунт {} (Id: {}) удалён.' WHERE `entry`=1009;
UPDATE `acore_string` SET `locale_ruRU`='-[         Аккаунт][    Персонаж][             IP][Карта][Зона][Доп][ГМ]-' WHERE `entry`=1010;
UPDATE `acore_string` SET `locale_ruRU`='|<Ошибка>       | {} |<Ошибка>         |<Ош>| <Ошибка>  |' WHERE `entry`=1011;
UPDATE `acore_string` SET `locale_ruRU`='-==================================================================-' WHERE `entry`=1012;
UPDATE `acore_string` SET `locale_ruRU`='-[{}][{}][{}][{}][{}][{}][{}]-' WHERE `entry`=1013;
UPDATE `acore_string` SET `locale_ruRU`='Нет игроков в сети.' WHERE `entry`=1014;
UPDATE `acore_string` SET `locale_ruRU`='-======================== Персонажи в сети ========================-' WHERE `entry`=1015;
UPDATE `acore_string` SET `locale_ruRU`='| GUID       | Имя                  | Ур.   | Аккаунт                      | Дата удаления       |' WHERE `entry`=1016;
UPDATE `acore_string` SET `locale_ruRU`='| {} | {} | {} | {} ({}) | {} |' WHERE `entry`=1017;
UPDATE `acore_string` SET `locale_ruRU`='==================================================================================================' WHERE `entry`=1018;
UPDATE `acore_string` SET `locale_ruRU`='Персонажи не найдены.' WHERE `entry`=1019;
UPDATE `acore_string` SET `locale_ruRU`='Восстанавливаются персонажи:' WHERE `entry`=1020;
UPDATE `acore_string` SET `locale_ruRU`='Удаляются персонажи:' WHERE `entry`=1021;
UPDATE `acore_string` SET `locale_ruRU`='ОШИБКА: новое имя можно задать, только если выбран один персонаж!' WHERE `entry`=1022;
UPDATE `acore_string` SET `locale_ruRU`='Персонажа \'{}\' (GUID: {} Аккаунт {}) нельзя восстановить: аккаунт не существует!' WHERE `entry`=1023;
UPDATE `acore_string` SET `locale_ruRU`='Персонажа \'{}\' (GUID: {} Аккаунт {}) нельзя восстановить: список персонажей аккаунта заполнен!' WHERE `entry`=1024;
UPDATE `acore_string` SET `locale_ruRU`='Персонажа \'{}\' (GUID: {} Аккаунт {}) нельзя восстановить: новое имя уже занято!' WHERE `entry`=1025;
UPDATE `acore_string` SET `locale_ruRU`='GUID: {} Имя: {} Уровень: {} Аккаунт: {} ({}) Дата: {}' WHERE `entry`=1026;
UPDATE `acore_string` SET `locale_ruRU`='Журналирование запросов SQL-драйвера включено.' WHERE `entry`=1027;
UPDATE `acore_string` SET `locale_ruRU`='Журналирование запросов SQL-драйвера отключено.' WHERE `entry`=1028;
UPDATE `acore_string` SET `locale_ruRU`='Пароль аккаунта НЕ может быть длиннее 16 символов (ограничение клиента). Аккаунт НЕ создан.' WHERE `entry`=1031;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунту {} (Id: {}) теперь разрешены дополнения до {}.' WHERE `entry`=1100;
UPDATE `acore_string` SET `locale_ruRU`='Сообщение дня в мире {} для языка {} изменено на:\\r {}' WHERE `entry`=1101;
UPDATE `acore_string` SET `locale_ruRU`='Сообщение отправлено {}: {}' WHERE `entry`=1102;
UPDATE `acore_string` SET `locale_ruRU`='{} - {} {}' WHERE `entry`=1103;
UPDATE `acore_string` SET `locale_ruRU`='{} - {}' WHERE `entry`=1104;
UPDATE `acore_string` SET `locale_ruRU`='{} - {}' WHERE `entry`=1105;
UPDATE `acore_string` SET `locale_ruRU`='{} - {} {}' WHERE `entry`=1106;
UPDATE `acore_string` SET `locale_ruRU`='{} - {}' WHERE `entry`=1107;
UPDATE `acore_string` SET `locale_ruRU`='{} - {} {}' WHERE `entry`=1108;
UPDATE `acore_string` SET `locale_ruRU`='{} - {} {} {} {}' WHERE `entry`=1109;
UPDATE `acore_string` SET `locale_ruRU`='{} - {} X:{} Y:{} Z:{} MapId:{}' WHERE `entry`=1110;
UPDATE `acore_string` SET `locale_ruRU`='{} - {} X:{} Y:{} Z:{} MapId:{}' WHERE `entry`=1111;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось открыть файл: {}' WHERE `entry`=1112;
UPDATE `acore_string` SET `locale_ruRU`='У аккаунта {} ({}) максимальное число персонажей (ограничение клиента)' WHERE `entry`=1113;
UPDATE `acore_string` SET `locale_ruRU`='Файл дампа содержит повреждённые данные!' WHERE `entry`=1114;
UPDATE `acore_string` SET `locale_ruRU`='Недопустимое имя персонажа!' WHERE `entry`=1115;
UPDATE `acore_string` SET `locale_ruRU`='Недопустимый guid персонажа!' WHERE `entry`=1116;
UPDATE `acore_string` SET `locale_ruRU`='Guid персонажа {} уже используется!' WHERE `entry`=1117;
UPDATE `acore_string` SET `locale_ruRU`='{} - гильдия: {} (guid: {}) {}' WHERE `entry`=1118;
UPDATE `acore_string` SET `locale_ruRU`='Укажите пол: male или female.' WHERE `entry`=1119;
UPDATE `acore_string` SET `locale_ruRU`='Вы изменили пол {} на {}.' WHERE `entry`=1120;
UPDATE `acore_string` SET `locale_ruRU`='{} изменил ваш пол на {}.' WHERE `entry`=1121;
UPDATE `acore_string` SET `locale_ruRU`='({}/{} +пост. {} +врем. {})' WHERE `entry`=1122;
UPDATE `acore_string` SET `locale_ruRU`='Питомец не найден' WHERE `entry`=1123;
UPDATE `acore_string` SET `locale_ruRU`='Неверный тип питомца' WHERE `entry`=1124;
UPDATE `acore_string` SET `locale_ruRU`='Ваш питомец изучил все таланты' WHERE `entry`=1125;
UPDATE `acore_string` SET `locale_ruRU`='Таланты вашего питомца сброшены.' WHERE `entry`=1126;
UPDATE `acore_string` SET `locale_ruRU`='Таланты питомца {} сброшены.' WHERE `entry`=1127;
UPDATE `acore_string` SET `locale_ruRU`='{} - |cffffffff|Htaxinode:{}|h[{} {}]|h|r (Карта:{} X:{} Y:{} Z:{})' WHERE `entry`=1128;
UPDATE `acore_string` SET `locale_ruRU`='{} - {} {} (Карта:{} X:{} Y:{} Z:{})' WHERE `entry`=1129;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя сделать дамп удалённых персонажей, отмена.' WHERE `entry`=1130;
UPDATE `acore_string` SET `locale_ruRU`='Под ваш запрос подходят персонажи:' WHERE `entry`=1131;
UPDATE `acore_string` SET `locale_ruRU`='Забаненные персонажи:' WHERE `entry`=1132;
UPDATE `acore_string` SET `locale_ruRU`='|   Персонаж    |  Дата бана   |  Дата разбана |    Кем       |    Причина    |' WHERE `entry`=1133;
UPDATE `acore_string` SET `locale_ruRU`='Отправка тикетов разрешена.' WHERE `entry`=1134;
UPDATE `acore_string` SET `locale_ruRU`='Отправка тикетов запрещена.' WHERE `entry`=1135;
UPDATE `acore_string` SET `locale_ruRU`='Персонаж {} никогда не был забанен!' WHERE `entry`=1136;
UPDATE `acore_string` SET `locale_ruRU`='Режим разработчика ВКЛЮЧЁН' WHERE `entry`=1137;
UPDATE `acore_string` SET `locale_ruRU`='Режим разработчика ВЫКЛЮЧЕН' WHERE `entry`=1138;
UPDATE `acore_string` SET `locale_ruRU`='   Следование за игроком {} (lowguid {})' WHERE `entry`=1139;
UPDATE `acore_string` SET `locale_ruRU`='   Следование за существом {} (lowguid {})' WHERE `entry`=1140;
UPDATE `acore_string` SET `locale_ruRU`='   Следование за <NULL>' WHERE `entry`=1141;
UPDATE `acore_string` SET `locale_ruRU`='   Движение от эффекта' WHERE `entry`=1142;
UPDATE `acore_string` SET `locale_ruRU`='moveFlags цели: {}, moveFlagsExtra: {}.' WHERE `entry`=1143;
UPDATE `acore_string` SET `locale_ruRU`='moveFlags цели установлены: {}, moveFlagsExtra: {}' WHERE `entry`=1144;
UPDATE `acore_string` SET `locale_ruRU`='{} уже состоит в группе!' WHERE `entry`=1145;
UPDATE `acore_string` SET `locale_ruRU`='{} вступил в группу {}.' WHERE `entry`=1146;
UPDATE `acore_string` SET `locale_ruRU`='{} не состоит в группе!' WHERE `entry`=1147;
UPDATE `acore_string` SET `locale_ruRU`='Группа заполнена!' WHERE `entry`=1148;
UPDATE `acore_string` SET `locale_ruRU`='Тип группы: {}, игроков: {}.' WHERE `entry`=1149;
UPDATE `acore_string` SET `locale_ruRU`='Имя: {} ({}),\n\n Зона: {}, Фаза: {}, GUID: {}, Флаги: {}, Роли: {}' WHERE `entry`=1150;
UPDATE `acore_string` SET `locale_ruRU`='Список писем: писем: {}, игрок: {}({})' WHERE `entry`=1151;
UPDATE `acore_string` SET `locale_ruRU`='Письмо Id: {} Тема: "{}" Деньги: {}з{}с{}м' WHERE `entry`=1152;
UPDATE `acore_string` SET `locale_ruRU`='Отправитель: {}({}),\n\n Получатель: {}({})' WHERE `entry`=1153;
UPDATE `acore_string` SET `locale_ruRU`='Доставка: {}, истекает: {}' WHERE `entry`=1154;
UPDATE `acore_string` SET `locale_ruRU`='Предмет: {}[Entry:{} Guid:{} Кол-во:{}]' WHERE `entry`=1155;
UPDATE `acore_string` SET `locale_ruRU`='Список писем: у этого персонажа нет писем.' WHERE `entry`=1156;
UPDATE `acore_string` SET `locale_ruRU`='Все настройки перезагружены из файлов конфигурации.' WHERE `entry`=1157;
UPDATE `acore_string` SET `locale_ruRU`='==========================================================' WHERE `entry`=1158;
UPDATE `acore_string` SET `locale_ruRU`='|--------------------------------------------------------|' WHERE `entry`=1159;
UPDATE `acore_string` SET `locale_ruRU`='|            |  Альянс  |   Орда   | Нейтрал. |  Всего   |' WHERE `entry`=1160;
UPDATE `acore_string` SET `locale_ruRU`='          Альянс/Орда/Нейтральные/Всего' WHERE `entry`=1161;
UPDATE `acore_string` SET `locale_ruRU`='| {} | {} | {} | {} | {} |' WHERE `entry`=1162;
UPDATE `acore_string` SET `locale_ruRU`='{} = {} / {} / {} / {}' WHERE `entry`=1163;
UPDATE `acore_string` SET `locale_ruRU`='Количество' WHERE `entry`=1164;
UPDATE `acore_string` SET `locale_ruRU`='Доля предметов' WHERE `entry`=1165;
UPDATE `acore_string` SET `locale_ruRU`='|            |  Альянс  |   Орда   | Нейтрал. |  Кол-во  |' WHERE `entry`=1166;
UPDATE `acore_string` SET `locale_ruRU`='          Альянс/Орда/Нейтральные/Кол-во' WHERE `entry`=1167;
UPDATE `acore_string` SET `locale_ruRU`='Серые' WHERE `entry`=1168;
UPDATE `acore_string` SET `locale_ruRU`='Белые' WHERE `entry`=1169;
UPDATE `acore_string` SET `locale_ruRU`='Зелёные' WHERE `entry`=1170;
UPDATE `acore_string` SET `locale_ruRU`='Синие' WHERE `entry`=1171;
UPDATE `acore_string` SET `locale_ruRU`='Фиолетовые' WHERE `entry`=1172;
UPDATE `acore_string` SET `locale_ruRU`='Оранжевые' WHERE `entry`=1173;
UPDATE `acore_string` SET `locale_ruRU`='Жёлтые' WHERE `entry`=1174;
UPDATE `acore_string` SET `locale_ruRU`='Количество предметов {} установлено на {}.' WHERE `entry`=1175;
UPDATE `acore_string` SET `locale_ruRU`='Доля предметов для {} установлена на {}.' WHERE `entry`=1176;
UPDATE `acore_string` SET `locale_ruRU`='Сведения о гильдии {} (Id: {})' WHERE `entry`=1177;
UPDATE `acore_string` SET `locale_ruRU`='| Глава гильдии: {} (GUID: {})' WHERE `entry`=1178;
UPDATE `acore_string` SET `locale_ruRU`='| Дата создания: {}' WHERE `entry`=1179;
UPDATE `acore_string` SET `locale_ruRU`='| Участников: {}' WHERE `entry`=1180;
UPDATE `acore_string` SET `locale_ruRU`='| Банк гильдии: {} золота' WHERE `entry`=1181;
UPDATE `acore_string` SET `locale_ruRU`='| Сообщение дня гильдии: {}' WHERE `entry`=1182;
UPDATE `acore_string` SET `locale_ruRU`='| Информация о гильдии: {}' WHERE `entry`=1183;
UPDATE `acore_string` SET `locale_ruRU`='| Звания гильдии:' WHERE `entry`=1184;
UPDATE `acore_string` SET `locale_ruRU`='| {} - {}' WHERE `entry`=1185;
UPDATE `acore_string` SET `locale_ruRU`='Режим повелителя зверей: {}' WHERE `entry`=1186;
UPDATE `acore_string` SET `locale_ruRU`='Вы пытаетесь посмотреть ролик {}, но его не существует.' WHERE `entry`=1200;
UPDATE `acore_string` SET `locale_ruRU`='Вы пытаетесь посмотреть видео {}, но его не существует.' WHERE `entry`=1201;
UPDATE `acore_string` SET `locale_ruRU`='Отладка areatrigger включена.' WHERE `entry`=1202;
UPDATE `acore_string` SET `locale_ruRU`='Отладка areatrigger выключена.' WHERE `entry`=1203;
UPDATE `acore_string` SET `locale_ruRU`='Вы достигли areatrigger {}.' WHERE `entry`=1204;
UPDATE `acore_string` SET `locale_ruRU`='Генерал Северного Волка мёртв!' WHERE `entry`=1331;
UPDATE `acore_string` SET `locale_ruRU`='Генерал Грозовой Вершины мёртв!' WHERE `entry`=1332;
UPDATE `acore_string` SET `locale_ruRU`='Ваш тикет закрыт.' WHERE `entry`=1334;
UPDATE `acore_string` SET `locale_ruRU`='Вы получили ответ на тикет.' WHERE `entry`=1335;
UPDATE `acore_string` SET `locale_ruRU`='Либо:' WHERE `entry`=1500;
UPDATE `acore_string` SET `locale_ruRU`='Или:   ' WHERE `entry`=1501;
UPDATE `acore_string` SET `locale_ruRU`='Значение \'{}\' недопустимо для типа {}.' WHERE `entry`=1502;
UPDATE `acore_string` SET `locale_ruRU`='В строке найдены неверные последовательности UTF-8.' WHERE `entry`=1503;
UPDATE `acore_string` SET `locale_ruRU`='Ссылка содержит неверные данные.' WHERE `entry`=1504;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт \'{}\' не существует.' WHERE `entry`=1505;
UPDATE `acore_string` SET `locale_ruRU`='Аккаунт с ID {} не существует.' WHERE `entry`=1506;
UPDATE `acore_string` SET `locale_ruRU`='{} не существует.' WHERE `entry`=1507;
UPDATE `acore_string` SET `locale_ruRU`='Персонаж \'{}\' не существует.' WHERE `entry`=1508;
UPDATE `acore_string` SET `locale_ruRU`='\'{}\' — недопустимое имя персонажа.' WHERE `entry`=1509;
UPDATE `acore_string` SET `locale_ruRU`='Достижение с ID {} не существует.' WHERE `entry`=1510;
UPDATE `acore_string` SET `locale_ruRU`='Точка телепорта {} не существует.' WHERE `entry`=1511;
UPDATE `acore_string` SET `locale_ruRU`='Точка телепорта \'{}\' не существует.' WHERE `entry`=1512;
UPDATE `acore_string` SET `locale_ruRU`='Предмет с ID {} не существует.' WHERE `entry`=1513;
UPDATE `acore_string` SET `locale_ruRU`='Заклинание с ID {} не существует.' WHERE `entry`=1514;
UPDATE `acore_string` SET `locale_ruRU`='Ожидалось \'{}\', получено \'{}\'.' WHERE `entry`=1515;
UPDATE `acore_string` SET `locale_ruRU`='Задание с ID {} не существует' WHERE `entry`=1516;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Новый тикет от|r|cffff00ff {}.|r |cff00ff00Номер тикета:|r|cffff00ff {}.|r' WHERE `entry`=2000;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Персонаж|r|cffff00ff {} |r|cff00ff00изменил тикет:|r|cffff00ff {}.|r' WHERE `entry`=2001;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Персонаж|r|cffff00ff {} |r|cff00ff00отозвал тикет:|r|cffff00ff {}.|r' WHERE `entry`=2002;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Закрыл|r:|cff00ccff {}|r ' WHERE `entry`=2003;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Удалил|r:|cff00ccff {}|r ' WHERE `entry`=2004;
UPDATE `acore_string` SET `locale_ruRU`='Тикет не найден.' WHERE `entry`=2005;
UPDATE `acore_string` SET `locale_ruRU`='Закройте тикет, прежде чем удалить его навсегда.' WHERE `entry`=2006;
UPDATE `acore_string` SET `locale_ruRU`='Тикет {} уже назначен.' WHERE `entry`=2007;
UPDATE `acore_string` SET `locale_ruRU`='Тикетов загружено из базы данных: {}.' WHERE `entry`=2008;
UPDATE `acore_string` SET `locale_ruRU`='Список открытых тикетов.' WHERE `entry`=2009;
UPDATE `acore_string` SET `locale_ruRU`='Список открытых тикетов, авторы которых в сети.' WHERE `entry`=2010;
UPDATE `acore_string` SET `locale_ruRU`='Список закрытых тикетов.' WHERE `entry`=2011;
UPDATE `acore_string` SET `locale_ruRU`='Указано неверное имя. Нужно имя ГМ, находящегося в сети.' WHERE `entry`=2012;
UPDATE `acore_string` SET `locale_ruRU`='Этот тикет уже назначен вам. Чтобы снять назначение, используйте .ticket unassign {} и назначьте заново.' WHERE `entry`=2013;
UPDATE `acore_string` SET `locale_ruRU`='Тикет {} не назначен, снимать назначение не с чего.' WHERE `entry`=2014;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя снимать тикеты с сотрудников с уровнем доступа выше вашего.' WHERE `entry`=2015;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя закрыть тикет {}: он назначен другому ГМ.' WHERE `entry`=2016;
UPDATE `acore_string` SET `locale_ruRU`='|cffaaffaaТикет|r:|cffaaccff {}.|r ' WHERE `entry`=2017;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Создал|r:|cff00ccff {}|r ' WHERE `entry`=2018;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Изменён|r:|cff00ccff {} назад|r ' WHERE `entry`=2019;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Назначен|r:|cff00ccff {}|r ' WHERE `entry`=2020;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Назначение снял|r:|cff00ccff {}|r ' WHERE `entry`=2021;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Текст тикета|r: [{}]|r' WHERE `entry`=2022;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Комментарий ГМ|r: [{}]|r' WHERE `entry`=2023;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ccff{}|r |cff00ff00добавил комментарий|r: [{}]|r' WHERE `entry`=2024;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Создан|r:|cff00ccff {} назад|r ' WHERE `entry`=2025;
UPDATE `acore_string` SET `locale_ruRU`='Есть открытые тикеты, сначала закройте их!' WHERE `entry`=2027;
UPDATE `acore_string` SET `locale_ruRU`='Все закрытые тикеты удалены, счётчик сброшен на |cffff00ff 1|r' WHERE `entry`=2028;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Ответ на тикет|r: [{}]|r' WHERE `entry`=2029;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Выполнил|r:|cff00ccff {}|r' WHERE `entry`=2030;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Ответ дополнен|r:|cff00ccff [{}]|r' WHERE `entry`=2031;
UPDATE `acore_string` SET `locale_ruRU`='|cff00ff00Ответ удалил|r:|cff00ccff {}|r' WHERE `entry`=2032;
UPDATE `acore_string` SET `locale_ruRU`='Вы заморозили игрока {}.' WHERE `entry`=5000;
UPDATE `acore_string` SET `locale_ruRU`='Было бы забавно, но нет... заморозить себя нельзя!' WHERE `entry`=5001;
UPDATE `acore_string` SET `locale_ruRU`='Неверный ввод, проверьте имя цели.' WHERE `entry`=5002;
UPDATE `acore_string` SET `locale_ruRU`='Вы разморозили игрока {}.' WHERE `entry`=5003;
UPDATE `acore_string` SET `locale_ruRU`='Замороженных игроков нет.' WHERE `entry`=5004;
UPDATE `acore_string` SET `locale_ruRU`='На сервере заморожены игроки:' WHERE `entry`=5005;
UPDATE `acore_string` SET `locale_ruRU`='- {}' WHERE `entry`=5006;
UPDATE `acore_string` SET `locale_ruRU`='Для входа в это подземелье нужно быть в рейдовой группе.' WHERE `entry`=5007;
UPDATE `acore_string` SET `locale_ruRU`='Это подземелье закрыто.' WHERE `entry`=5008;
UPDATE `acore_string` SET `locale_ruRU`='Звук {} воспроизведён для всего сервера' WHERE `entry`=5009;
UPDATE `acore_string` SET `locale_ruRU`='linkGUID: {}, Entry: {} ({})' WHERE `entry`=5010;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя телепортировать себя к себе!' WHERE `entry`=5011;
UPDATE `acore_string` SET `locale_ruRU`='Карты не найдены!' WHERE `entry`=5012;
UPDATE `acore_string` SET `locale_ruRU`='[Континент]' WHERE `entry`=5013;
UPDATE `acore_string` SET `locale_ruRU`='[Подземелье]' WHERE `entry`=5014;
UPDATE `acore_string` SET `locale_ruRU`='[Поле боя]' WHERE `entry`=5015;
UPDATE `acore_string` SET `locale_ruRU`='[Арена]' WHERE `entry`=5016;
UPDATE `acore_string` SET `locale_ruRU`='[Рейд]' WHERE `entry`=5017;
UPDATE `acore_string` SET `locale_ruRU`='Phasemask: {}' WHERE `entry`=5020;
UPDATE `acore_string` SET `locale_ruRU`='Броня: {}' WHERE `entry`=5021;
UPDATE `acore_string` SET `locale_ruRU`='Передача прав владельца первому вошедшему в канал "{}": включена.' WHERE `entry`=5022;
UPDATE `acore_string` SET `locale_ruRU`='Передача прав владельца первому вошедшему в канал "{}": отключена.' WHERE `entry`=5023;
UPDATE `acore_string` SET `locale_ruRU`='Entry: {}' WHERE `entry`=5024;
UPDATE `acore_string` SET `locale_ruRU`='Тип: {}' WHERE `entry`=5025;
UPDATE `acore_string` SET `locale_ruRU`='DisplayID: {}' WHERE `entry`=5026;
UPDATE `acore_string` SET `locale_ruRU`='Имя: {}' WHERE `entry`=5027;
UPDATE `acore_string` SET `locale_ruRU`='Lootid: {}' WHERE `entry`=5028;
UPDATE `acore_string` SET `locale_ruRU`='Достигнут лимит результатов (макс.: {})' WHERE `entry`=5029;
UPDATE `acore_string` SET `locale_ruRU`='AIName: {} ScriptName: {}' WHERE `entry`=5031;
UPDATE `acore_string` SET `locale_ruRU`='Поле боя не найдено!' WHERE `entry`=5032;
UPDATE `acore_string` SET `locale_ruRU`='Критерии достижений не найдены!' WHERE `entry`=5033;
UPDATE `acore_string` SET `locale_ruRU`='Мировое PvP не найдено!' WHERE `entry`=5034;
UPDATE `acore_string` SET `locale_ruRU`='EquipmentId: {} (исходный: {}).' WHERE `entry`=5036;
UPDATE `acore_string` SET `locale_ruRU`='MechanicImmuneMask: {}' WHERE `entry`=5037;
UPDATE `acore_string` SET `locale_ruRU`='Unit Flags: {}' WHERE `entry`=5038;
UPDATE `acore_string` SET `locale_ruRU`='Консоль' WHERE `entry`=5039;
UPDATE `acore_string` SET `locale_ruRU`='Персонаж' WHERE `entry`=5040;
UPDATE `acore_string` SET `locale_ruRU`='Навсегда' WHERE `entry`=5041;
UPDATE `acore_string` SET `locale_ruRU`='Вы на открытом воздухе.' WHERE `entry`=5042;
UPDATE `acore_string` SET `locale_ruRU`='Вы в помещении.' WHERE `entry`=5043;
UPDATE `acore_string` SET `locale_ruRU`='нет данных VMAP для информации об области' WHERE `entry`=5044;
UPDATE `acore_string` SET `locale_ruRU`='Карта: {} | ID: {} | пост.: {} | продлено: {} | сложность: {} | можно сбросить: {} | до сброса: {}' WHERE `entry`=5045;
UPDATE `acore_string` SET `locale_ruRU`='Привязки игрока: {}' WHERE `entry`=5046;
UPDATE `acore_string` SET `locale_ruRU`='Привязки группы: {}' WHERE `entry`=5047;
UPDATE `acore_string` SET `locale_ruRU`='Снятие привязки: карта {} инст. {} пост. {} сложн. {} можно сбросить {} до сброса {}' WHERE `entry`=5048;
UPDATE `acore_string` SET `locale_ruRU`='Снято привязок к подземельям: {}' WHERE `entry`=5049;
UPDATE `acore_string` SET `locale_ruRU`='Загружено подземелий: {}' WHERE `entry`=5050;
UPDATE `acore_string` SET `locale_ruRU`='Игроков в подземельях: {}' WHERE `entry`=5051;
UPDATE `acore_string` SET `locale_ruRU`='Сохранений подземелий: {}' WHERE `entry`=5052;
UPDATE `acore_string` SET `locale_ruRU`='Привязанных игроков: {}' WHERE `entry`=5053;
UPDATE `acore_string` SET `locale_ruRU`='Привязанных групп: {}' WHERE `entry`=5054;
UPDATE `acore_string` SET `locale_ruRU`='Карта не является подземельем.' WHERE `entry`=5055;
UPDATE `acore_string` SET `locale_ruRU`='У карты нет данных подземелья.' WHERE `entry`=5056;
UPDATE `acore_string` SET `locale_ruRU`='Состояние босса id {} установлено на {} ({}).' WHERE `entry`=5057;
UPDATE `acore_string` SET `locale_ruRU`='Состояние босса id {} ({}): {} ({}).' WHERE `entry`=5058;
UPDATE `acore_string` SET `locale_ruRU`='Муты аккаунта: {}' WHERE `entry`=5059;
UPDATE `acore_string` SET `locale_ruRU`='У аккаунта нет мутов: {}' WHERE `entry`=5060;
UPDATE `acore_string` SET `locale_ruRU`='Дата мута: {} Длительность: {} мин. Причина: {} Кем: {}' WHERE `entry`=5061;
UPDATE `acore_string` SET `locale_ruRU`='SpellSchoolImmuneMask: {}' WHERE `entry`=5062;
UPDATE `acore_string` SET `locale_ruRU`='Кэшированные данные персонажа: \n|- Имя: {} (Guid: {}) \n|- Аккаунт: {} \n|- Класс: {} \n|- Раса: {} \n|- Пол: {} \n|- Уровень: {} \n|- Писем: {} \n|- Гильдия: {} \n|- ID группы: {} \n|- Команда арены 2x2: {} \n|- Команда арены 3x3: {} \n|- Команда арены 5x5: {}' WHERE `entry`=5063;
UPDATE `acore_string` SET `locale_ruRU`='Кэш персонажа {} ({}) очищен.' WHERE `entry`=5064;
UPDATE `acore_string` SET `locale_ruRU`='Кэш персонажа {} ({}) обновлён.' WHERE `entry`=5065;
UPDATE `acore_string` SET `locale_ruRU`='Кэш персонажа {} не найден' WHERE `entry`=5066;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} ({}) добавлено.' WHERE `entry`=5067;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} ({}) не найдено в журнале заданий.' WHERE `entry`=5068;
UPDATE `acore_string` SET `locale_ruRU`='Для получения награды задание должно быть активно и выполнено' WHERE `entry`=5069;
UPDATE `acore_string` SET `locale_ruRU`='Команда отключена в настройках' WHERE `entry`=5070;
UPDATE `acore_string` SET `locale_ruRU`='Указанная запись extendedcost не существует.' WHERE `entry`=5071;
UPDATE `acore_string` SET `locale_ruRU`='Возврат {} ({}) превысит лимит очков чести цели (лимит: {}, сейчас: {}, к возврату: {}).' WHERE `entry`=5072;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось вернуть предмет {}: будет превышен лимит очков чести.' WHERE `entry`=5073;
UPDATE `acore_string` SET `locale_ruRU`='Предмет {} ({}) возвращён, восстановлено очков чести: {}.' WHERE `entry`=5074;
UPDATE `acore_string` SET `locale_ruRU`='Возврат {} ({}) превысит лимит очков арены цели (лимит: {}, сейчас: {}, к возврату: {}).' WHERE `entry`=5075;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось вернуть предмет {}: будет превышен лимит очков арены.' WHERE `entry`=5076;
UPDATE `acore_string` SET `locale_ruRU`='Предмет {} ({}) возвращён, восстановлено очков арены: {}.' WHERE `entry`=5077;
UPDATE `acore_string` SET `locale_ruRU`='Предмет не найден в инвентаре персонажа (включая банк)' WHERE `entry`=5078;
UPDATE `acore_string` SET `locale_ruRU`='Отключать автоматические объявления можно с уровня {}.' WHERE `entry`=5079;
UPDATE `acore_string` SET `locale_ruRU`='Теперь вы получаете общие сообщения {}.' WHERE `entry`=5080;
UPDATE `acore_string` SET `locale_ruRU`='Вы больше не будете получать общие сообщения {}.' WHERE `entry`=5081;
UPDATE `acore_string` SET `locale_ruRU`='Неверный синтаксис. Укажите \'starter\' или \'ender\'.' WHERE `entry`=5082;
UPDATE `acore_string` SET `locale_ruRU`='Персонаж {} ({}) перенесён с аккаунта {} ({}) на аккаунт {} ({}).' WHERE `entry`=5083;
UPDATE `acore_string` SET `locale_ruRU`='Не удалось применить заклинание! SpellCastResult: {} ({}).' WHERE `entry`=5084;
UPDATE `acore_string` SET `locale_ruRU`='Объект {} (entry :{} guid: {}) возрождён!' WHERE `entry`=5085;
UPDATE `acore_string` SET `locale_ruRU`='В радиусе {} м дверей не найдено.' WHERE `entry`=5086;
UPDATE `acore_string` SET `locale_ruRU`='Дверь {} (Entry: {}) открыта!' WHERE `entry`=5087;
UPDATE `acore_string` SET `locale_ruRU`='Задание: {} ({}) \nСостояние: {}' WHERE `entry`=5088;
UPDATE `acore_string` SET `locale_ruRU`='Задание {} нельзя взять. Причины:' WHERE `entry`=5089;
UPDATE `acore_string` SET `locale_ruRU`='  - Задание отключено.' WHERE `entry`=5090;
UPDATE `acore_string` SET `locale_ruRU`='  - Задание уже взято или выполнено.' WHERE `entry`=5091;
UPDATE `acore_string` SET `locale_ruRU`='  - Не подходит класс.' WHERE `entry`=5092;
UPDATE `acore_string` SET `locale_ruRU`='  - Не подходит раса.' WHERE `entry`=5093;
UPDATE `acore_string` SET `locale_ruRU`='  - Слишком низкий уровень (нужен: {}).' WHERE `entry`=5094;
UPDATE `acore_string` SET `locale_ruRU`='  - Слишком высокий уровень (макс.: {}).' WHERE `entry`=5095;
UPDATE `acore_string` SET `locale_ruRU`='  - Не выполнены требования к навыку.' WHERE `entry`=5096;
UPDATE `acore_string` SET `locale_ruRU`='  - Не выполнены требования к репутации.' WHERE `entry`=5097;
UPDATE `acore_string` SET `locale_ruRU`='  - Не выполнено предыдущее задание цепочки.' WHERE `entry`=5098;
UPDATE `acore_string` SET `locale_ruRU`='  - Уже есть задание на время.' WHERE `entry`=5099;
UPDATE `acore_string` SET `locale_ruRU`='  - Конфликт с заданием из взаимоисключающей группы.' WHERE `entry`=5100;
UPDATE `acore_string` SET `locale_ruRU`='  - Следующее задание цепочки уже начато.' WHERE `entry`=5101;
UPDATE `acore_string` SET `locale_ruRU`='  - Предыдущее задание цепочки всё ещё активно.' WHERE `entry`=5102;
UPDATE `acore_string` SET `locale_ruRU`='  - Конфликт с заданием-указателем.' WHERE `entry`=5103;
UPDATE `acore_string` SET `locale_ruRU`='  - Ежедневное задание сегодня недоступно.' WHERE `entry`=5104;
UPDATE `acore_string` SET `locale_ruRU`='  - Еженедельное задание на этой неделе уже выполнено.' WHERE `entry`=5105;
UPDATE `acore_string` SET `locale_ruRU`='  - Ежемесячное задание в этом месяце уже выполнено.' WHERE `entry`=5106;
UPDATE `acore_string` SET `locale_ruRU`='  - Сезонное задание в этом сезоне уже выполнено.' WHERE `entry`=5107;
UPDATE `acore_string` SET `locale_ruRU`='  - Не выполнены условия:' WHERE `entry`=5108;
UPDATE `acore_string` SET `locale_ruRU`='  - Журнал заданий заполнен.' WHERE `entry`=5109;
UPDATE `acore_string` SET `locale_ruRU`='    - Условие не выполнено: тип {} value1: {} value2: {} value3: {}' WHERE `entry`=5110;
UPDATE `acore_string` SET `locale_ruRU`='Очки чести сброшены у всех игроков.' WHERE `entry`=5118;
UPDATE `acore_string` SET `locale_ruRU`='Очки арены сброшены у всех игроков.' WHERE `entry`=5119;
UPDATE `acore_string` SET `locale_ruRU`='  [З] {}' WHERE `entry`=5123;
UPDATE `acore_string` SET `locale_ruRU`='  [П] {} ({}с)' WHERE `entry`=5124;
UPDATE `acore_string` SET `locale_ruRU`='  [М] {}' WHERE `entry`=5125;
UPDATE `acore_string` SET `locale_ruRU`='Вы не можете говорить, кричать и использовать эмоции до {} уровня.' WHERE `entry`=6604;
UPDATE `acore_string` SET `locale_ruRU`='Вы не можете писать личные сообщения до {} уровня.' WHERE `entry`=6605;
UPDATE `acore_string` SET `locale_ruRU`='Вы не можете писать в каналы до {} уровня.' WHERE `entry`=6606;
UPDATE `acore_string` SET `locale_ruRU`='Вы не можете пользоваться аукционом до {} уровня.' WHERE `entry`=6607;
UPDATE `acore_string` SET `locale_ruRU`='Вы не можете отправлять тикеты до {} уровня.' WHERE `entry`=6608;
UPDATE `acore_string` SET `locale_ruRU`='Вы не можете торговать до {} уровня.' WHERE `entry`=6609;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя торговать с персонажами ниже {} уровня.' WHERE `entry`=6610;
UPDATE `acore_string` SET `locale_ruRU`='Вы не можете отправлять почту до {} уровня.' WHERE `entry`=6611;
UPDATE `acore_string` SET `locale_ruRU`='Нельзя отправлять почту персонажам ниже {} уровня.' WHERE `entry`=6612;
UPDATE `acore_string` SET `locale_ruRU`='|cfff00000[Объявление ГМ]: {}|r' WHERE `entry`=6613;
UPDATE `acore_string` SET `locale_ruRU`='Оповещение для ГМ - ' WHERE `entry`=6614;
UPDATE `acore_string` SET `locale_ruRU`='|cffffff00[|c1f40af20Объявление ГМ от|r |cffff0000{}|cffffff00]:|r {}|r' WHERE `entry`=6615;
UPDATE `acore_string` SET `locale_ruRU`='Режим тишины ВКЛЮЧЁН для {}' WHERE `entry`=6616;
UPDATE `acore_string` SET `locale_ruRU`='Режим наблюдателя ГМ ВКЛЮЧЁН' WHERE `entry`=6617;
UPDATE `acore_string` SET `locale_ruRU`='Режим наблюдателя ГМ ВЫКЛЮЧЕН' WHERE `entry`=6618;
UPDATE `acore_string` SET `locale_ruRU`='МИР: подключения запрещены.' WHERE `entry`=7523;
UPDATE `acore_string` SET `locale_ruRU`='МИР: подключения разрешены.' WHERE `entry`=7524;
UPDATE `acore_string` SET `locale_ruRU`='Игрок: {}, Состояние: {}, Подземелья: {} ({}),\n\n Роли: {}, Комментарий: {}' WHERE `entry`=9980;
UPDATE `acore_string` SET `locale_ruRU`='Группа поиска?: {}, Состояние: {}, Подземелье: {}' WHERE `entry`=9981;
UPDATE `acore_string` SET `locale_ruRU`='Не в группе' WHERE `entry`=9982;
UPDATE `acore_string` SET `locale_ruRU`='Очереди очищены' WHERE `entry`=9983;
UPDATE `acore_string` SET `locale_ruRU`='Параметры поиска группы: {}' WHERE `entry`=9984;
UPDATE `acore_string` SET `locale_ruRU`='Параметры поиска группы изменены' WHERE `entry`=9985;
UPDATE `acore_string` SET `locale_ruRU`='Нет' WHERE `entry`=9986;
UPDATE `acore_string` SET `locale_ruRU`='Проверка ролей' WHERE `entry`=9987;
UPDATE `acore_string` SET `locale_ruRU`='В очереди' WHERE `entry`=9988;
UPDATE `acore_string` SET `locale_ruRU`='Предложение' WHERE `entry`=9989;
UPDATE `acore_string` SET `locale_ruRU`='Голосование за исключение' WHERE `entry`=9990;
UPDATE `acore_string` SET `locale_ruRU`='В подземелье' WHERE `entry`=9991;
UPDATE `acore_string` SET `locale_ruRU`='Подземелье пройдено' WHERE `entry`=9992;
UPDATE `acore_string` SET `locale_ruRU`='Поиск рейда' WHERE `entry`=9993;
UPDATE `acore_string` SET `locale_ruRU`='Танк' WHERE `entry`=9994;
UPDATE `acore_string` SET `locale_ruRU`='Лекарь' WHERE `entry`=9995;
UPDATE `acore_string` SET `locale_ruRU`='Урон' WHERE `entry`=9996;
UPDATE `acore_string` SET `locale_ruRU`='Лидер' WHERE `entry`=9997;
UPDATE `acore_string` SET `locale_ruRU`='Нет' WHERE `entry`=9998;
UPDATE `acore_string` SET `locale_ruRU`='Ошибка' WHERE `entry`=9999;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Смотровую площадку!' WHERE `entry`=10001;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Смотровую площадку!' WHERE `entry`=10002;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Стадион!' WHERE `entry`=10003;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Стадион!' WHERE `entry`=10004;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Разбитый холм!' WHERE `entry`=10005;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Разбитый холм!' WHERE `entry`=10006;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Смотровую площадку!' WHERE `entry`=10007;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Смотровую площадку!' WHERE `entry`=10008;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Стадион!' WHERE `entry`=10009;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Стадион!' WHERE `entry`=10010;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Разбитый холм!' WHERE `entry`=10011;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Разбитый холм!' WHERE `entry`=10012;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Западный маяк!' WHERE `entry`=10013;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Западный маяк!' WHERE `entry`=10014;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Восточный маяк!' WHERE `entry`=10015;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Восточный маяк!' WHERE `entry`=10016;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила кладбище Двух Шпилей!' WHERE `entry`=10017;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил кладбище Двух Шпилей!' WHERE `entry`=10018;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Западный маяк!' WHERE `entry`=10019;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Западный маяк!' WHERE `entry`=10020;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Восточный маяк!' WHERE `entry`=10021;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Восточный маяк!' WHERE `entry`=10022;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла кладбище Двух Шпилей!' WHERE `entry`=10023;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял кладбище Двух Шпилей!' WHERE `entry`=10024;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Халаа!' WHERE `entry`=10025;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Халаа!' WHERE `entry`=10026;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Халаа!' WHERE `entry`=10027;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Халаа!' WHERE `entry`=10028;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Башню духов!' WHERE `entry`=10029;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Башню духов!' WHERE `entry`=10030;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Башню духов!' WHERE `entry`=10031;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Башню духов!' WHERE `entry`=10032;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Северную башню!' WHERE `entry`=10033;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Северную башню!' WHERE `entry`=10034;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Восточную башню!' WHERE `entry`=10035;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Восточную башню!' WHERE `entry`=10036;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила башню Королевской Стражи!' WHERE `entry`=10037;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил башню Королевской Стражи!' WHERE `entry`=10038;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила башню Чумного леса!' WHERE `entry`=10039;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил башню Чумного леса!' WHERE `entry`=10040;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Северную башню!' WHERE `entry`=10041;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Северную башню!' WHERE `entry`=10042;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла Восточную башню!' WHERE `entry`=10043;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял Восточную башню!' WHERE `entry`=10044;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла башню Королевской Стражи!' WHERE `entry`=10045;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял башню Королевской Стражи!' WHERE `entry`=10046;
UPDATE `acore_string` SET `locale_ruRU`='Орда потеряла башню Чумного леса!' WHERE `entry`=10047;
UPDATE `acore_string` SET `locale_ruRU`='Альянс потерял башню Чумного леса!' WHERE `entry`=10048;
UPDATE `acore_string` SET `locale_ruRU`='Орда собрала 200 силитиста!' WHERE `entry`=10049;
UPDATE `acore_string` SET `locale_ruRU`='Альянс собрал 200 силитиста!' WHERE `entry`=10050;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня к Северной башне.' WHERE `entry`=10051;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня к Восточной башне.' WHERE `entry`=10052;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня к башне Королевской Стражи.' WHERE `entry`=10053;
UPDATE `acore_string` SET `locale_ruRU`='Дай мне флаг, я отнесу его к центральному маяку во славу Альянса!' WHERE `entry`=10054;
UPDATE `acore_string` SET `locale_ruRU`='Дай мне флаг, я отнесу его к центральному маяку во славу Орды!' WHERE `entry`=10055;
UPDATE `acore_string` SET `locale_ruRU`='Битва за Берег Древних начнётся через 2 минуты.' WHERE `entry`=10056;
UPDATE `acore_string` SET `locale_ruRU`='Битва за Берег Древних начнётся через 1 минуту.' WHERE `entry`=10057;
UPDATE `acore_string` SET `locale_ruRU`='Битва за Берег Древних начнётся через 30 секунд. Приготовьтесь!.' WHERE `entry`=10058;
UPDATE `acore_string` SET `locale_ruRU`='Да начнётся битва за Берег Древних!' WHERE `entry`=10059;
UPDATE `acore_string` SET `locale_ruRU`='{} атакованы!' WHERE `entry`=10060;
UPDATE `acore_string` SET `locale_ruRU`='{} уничтожены!' WHERE `entry`=10061;
UPDATE `acore_string` SET `locale_ruRU`='Раунд 1 завершён!' WHERE `entry`=10062;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил портал титанов!' WHERE `entry`=10063;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила портал титанов!' WHERE `entry`=10064;
UPDATE `acore_string` SET `locale_ruRU`='Второй раунд битвы за Берег Древних начнётся через 1 минуту.' WHERE `entry`=10065;
UPDATE `acore_string` SET `locale_ruRU`='Второй раунд начнётся через 30 секунд. Приготовьтесь!' WHERE `entry`=10066;
UPDATE `acore_string` SET `locale_ruRU`='Зал прорван! Реликвия титанов уязвима!' WHERE `entry`=10067;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Южное кладбище!' WHERE `entry`=10068;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Западное кладбище!' WHERE `entry`=10069;
UPDATE `acore_string` SET `locale_ruRU`='Альянс захватил Восточное кладбище!' WHERE `entry`=10070;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Южное кладбище!' WHERE `entry`=10071;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Западное кладбище!' WHERE `entry`=10072;
UPDATE `acore_string` SET `locale_ruRU`='Орда захватила Восточное кладбище!' WHERE `entry`=10073;
UPDATE `acore_string` SET `locale_ruRU`='Халаа беззащитна!' WHERE `entry`=10074;
UPDATE `acore_string` SET `locale_ruRU`='|cffffff00[|c00077766Объявление|cffffff00]: |cFFF222FF{}|r' WHERE `entry`=11000;
UPDATE `acore_string` SET `locale_ruRU`='Вы не указали -1 или ID текущего мира.' WHERE `entry`=11001;
UPDATE `acore_string` SET `locale_ruRU`='Тип движения: {}' WHERE `entry`=11008;
UPDATE `acore_string` SET `locale_ruRU`='Flags Extra: {}' WHERE `entry`=11009;
UPDATE `acore_string` SET `locale_ruRU`='Вас не выкинуло из подземелья, хотя Player::CheckInstanceLoginValid() вернул false и режим .gm on не включён' WHERE `entry`=11010;
UPDATE `acore_string` SET `locale_ruRU`='Предупреждение VisualizeBoundary: не найдено ни одной внутренней точки границы существа — проверьте, нет ли взаимоисключающих границ!' WHERE `entry`=11011;
UPDATE `acore_string` SET `locale_ruRU`='Ошибка VisualizeBoundary: движение существа ничем не ограничено' WHERE `entry`=11012;
UPDATE `acore_string` SET `locale_ruRU`='Предупреждение VisualizeBoundary: достигнут аварийный предел заливки — проверьте, не открыта ли граница!' WHERE `entry`=11013;
UPDATE `acore_string` SET `locale_ruRU`='Вы уже привязаны к {}.' WHERE `entry`=11014;
UPDATE `acore_string` SET `locale_ruRU`='У этого существа нет активного CreatureAI.' WHERE `entry`=11015;
UPDATE `acore_string` SET `locale_ruRU`='Выберите игрока или питомца игрока.' WHERE `entry`=11016;
UPDATE `acore_string` SET `locale_ruRU`='Восстановление поиска подземелий сброшено у всех игроков.' WHERE `entry`=11019;
UPDATE `acore_string` SET `locale_ruRU`='{} захвачена: {} ' WHERE `entry`=12050;
UPDATE `acore_string` SET `locale_ruRU`='{} атакует {}' WHERE `entry`=12051;
UPDATE `acore_string` SET `locale_ruRU`='Осадная мастерская у Разрушенного храма' WHERE `entry`=12052;
UPDATE `acore_string` SET `locale_ruRU`='Осадная мастерская у Восточной Искры' WHERE `entry`=12053;
UPDATE `acore_string` SET `locale_ruRU`='Осадная мастерская у Западной Искры' WHERE `entry`=12054;
UPDATE `acore_string` SET `locale_ruRU`='Осадная мастерская у Затонувшего Кольца' WHERE `entry`=12055;
UPDATE `acore_string` SET `locale_ruRU`='Орда' WHERE `entry`=12056;
UPDATE `acore_string` SET `locale_ruRU`='Альянс' WHERE `entry`=12057;
UPDATE `acore_string` SET `locale_ruRU`='Битва за Озеро Ледяных Оков вот-вот начнётся!' WHERE `entry`=12058;
UPDATE `acore_string` SET `locale_ruRU`='Вы достигли звания 1: Капрал' WHERE `entry`=12059;
UPDATE `acore_string` SET `locale_ruRU`='Вы достигли звания 2: Лейтенант' WHERE `entry`=12060;
UPDATE `acore_string` SET `locale_ruRU`='Юго-восточная башня крепости' WHERE `entry`=12061;
UPDATE `acore_string` SET `locale_ruRU`='Северо-восточная башня крепости' WHERE `entry`=12062;
UPDATE `acore_string` SET `locale_ruRU`='Юго-западная башня крепости' WHERE `entry`=12063;
UPDATE `acore_string` SET `locale_ruRU`='Северо-западная башня крепости' WHERE `entry`=12064;
UPDATE `acore_string` SET `locale_ruRU`='{} повреждена!' WHERE `entry`=12065;
UPDATE `acore_string` SET `locale_ruRU`='{} разрушена!' WHERE `entry`=12066;
UPDATE `acore_string` SET `locale_ruRU`='Битва за Озеро Ледяных Оков началась!' WHERE `entry`=12067;
UPDATE `acore_string` SET `locale_ruRU`='{} успешно защищает крепость Озера Ледяных Оков!' WHERE `entry`=12068;
UPDATE `acore_string` SET `locale_ruRU`='Южная башня' WHERE `entry`=12069;
UPDATE `acore_string` SET `locale_ruRU`='Восточная башня' WHERE `entry`=12070;
UPDATE `acore_string` SET `locale_ruRU`='Западная башня' WHERE `entry`=12071;
UPDATE `acore_string` SET `locale_ruRU`='Крепость Озера Ледяных Оков захвачена: {}!' WHERE `entry`=12072;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня к кладбищу Крепости.' WHERE `entry`=20070;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня к кладбищу Затонувшего Кольца.' WHERE `entry`=20071;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня к кладбищу Разрушенного храма.' WHERE `entry`=20072;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня к кладбищу Западной Искры.' WHERE `entry`=20073;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня к кладбищу Восточной Искры.' WHERE `entry`=20074;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня обратно в лагерь высадки Орды.' WHERE `entry`=20075;
UPDATE `acore_string` SET `locale_ruRU`='Отведи меня обратно в лагерь высадки Альянса.' WHERE `entry`=20076;
UPDATE `acore_string` SET `locale_ruRU`='Встать в очередь на Озеро Ледяных Оков.' WHERE `entry`=20077;
UPDATE `acore_string` SET `locale_ruRU`='|cffff0000[Озеро Ледяных Оков]:|r Битва началась!|r' WHERE `entry`=20078;
UPDATE `acore_string` SET `locale_ruRU`='Эти следы, должно быть, принадлежат Шанго.' WHERE `entry`=28634;
UPDATE `acore_string` SET `locale_ruRU`='Это не следы Шанго.' WHERE `entry`=28635;
UPDATE `acore_string` SET `locale_ruRU`='Переключить мгновенный полёт' WHERE `entry`=30077;
UPDATE `acore_string` SET `locale_ruRU`='Мгновенный полёт ВКЛ' WHERE `entry`=30078;
UPDATE `acore_string` SET `locale_ruRU`='Мгновенный полёт ВЫКЛ' WHERE `entry`=30079;
UPDATE `acore_string` SET `locale_ruRU`='У {} нет itemID = {}, удалить нельзя.' WHERE `entry`=30081;
UPDATE `acore_string` SET `locale_ruRU`='У {} нет столько предметов с itemID = {}, ничего не удалено.' WHERE `entry`=30082;
UPDATE `acore_string` SET `locale_ruRU`='На поле боя нельзя делиться заданиями.' WHERE `entry`=30083;
UPDATE `acore_string` SET `locale_ruRU`='На поле боя нельзя запускать проверку готовности.' WHERE `entry`=30084;
UPDATE `acore_string` SET `locale_ruRU`='Отладка полей боя уже включена в настройках, поэтому включать/выключать её командой нельзя.' WHERE `entry`=30085;
UPDATE `acore_string` SET `locale_ruRU`='Отладка арен уже включена в настройках, поэтому включать/выключать её командой нельзя.' WHERE `entry`=30086;
UPDATE `acore_string` SET `locale_ruRU`='Поиск группы переведён в режим очереди на 1 игрока для отладки.' WHERE `entry`=30096;
UPDATE `acore_string` SET `locale_ruRU`='Поиск группы переведён в обычный режим очереди.' WHERE `entry`=30097;
UPDATE `acore_string` SET `locale_ruRU`='Отладка поиска группы уже включена в настройках, поэтому включать/выключать её командой нельзя.' WHERE `entry`=30098;
UPDATE `acore_string` SET `locale_ruRU`='¦ Игрок {} {} (guid: {})' WHERE `entry`=35400;
UPDATE `acore_string` SET `locale_ruRU`='¦ Режим ГМ активен, Фаза: -1' WHERE `entry`=35401;
UPDATE `acore_string` SET `locale_ruRU`='├─ Забанен: (Тип: {}, Причина: {}, Срок: {}, Кем: {})' WHERE `entry`=35402;
UPDATE `acore_string` SET `locale_ruRU`='├─ Мут: (Причина: {}, Срок: {}, Кем: {})' WHERE `entry`=35403;
UPDATE `acore_string` SET `locale_ruRU`='¦ Аккаунт: {} (ID: {}),\n\n Уровень ГМ: {}' WHERE `entry`=35404;
UPDATE `acore_string` SET `locale_ruRU`='¦ Последний вход: {} (Неудачных входов: {})' WHERE `entry`=35405;
UPDATE `acore_string` SET `locale_ruRU`='¦ Email регистрации: {} - Email: {}' WHERE `entry`=35406;
UPDATE `acore_string` SET `locale_ruRU`='Причина не указана.' WHERE `entry`=35407;
UPDATE `acore_string` SET `locale_ruRU`='<нет доступа>' WHERE `entry`=35408;
UPDATE `acore_string` SET `locale_ruRU`='¦ Карта: {}, Зона: {}, Область: {}' WHERE `entry`=35409;
UPDATE `acore_string` SET `locale_ruRU`='На этом сервере работает модуль |cff4CFF00IndividualXpRate |r.' WHERE `entry`=35411;
UPDATE `acore_string` SET `locale_ruRU`='[Опыт] Модуль индивидуального опыта отключён.' WHERE `entry`=35412;
UPDATE `acore_string` SET `locale_ruRU`='[Опыт] Ваш индивидуальный множитель опыта сейчас отключён. Включите его командой .xp enable.' WHERE `entry`=35413;
UPDATE `acore_string` SET `locale_ruRU`='|cffffffff[Опыт] Ваш текущий множитель опыта: {}.|r' WHERE `entry`=35414;
UPDATE `acore_string` SET `locale_ruRU`='|cffffffff[Опыт] Максимальный множитель: {}.|r' WHERE `entry`=35415;
UPDATE `acore_string` SET `locale_ruRU`='[Опыт] Минимальный множитель: 1.' WHERE `entry`=35416;
UPDATE `acore_string` SET `locale_ruRU`='[Опыт] Вы установили множитель опыта: {}.' WHERE `entry`=35417;
UPDATE `acore_string` SET `locale_ruRU`='[Опыт] Вы отключили получение опыта.' WHERE `entry`=35418;
UPDATE `acore_string` SET `locale_ruRU`='[Опыт] Вы включили получение опыта.' WHERE `entry`=35419;
UPDATE `acore_string` SET `locale_ruRU`='[Опыт] Множитель опыта возвращён к значению по умолчанию: {}.' WHERE `entry`=35420;

