# Game Center

The app reports to these IDs (`Echo/App/GameCenter.swift`, `Echo/Shell/Records/Achievements.swift`). All of them are set up on the app's Game Center page in App Store Connect, each with English and Russian text and, for achievements, the art below. Development and TestFlight builds see them before review. The version page no longer has a Game Center switch: for the release, press **Add for Review** on each leaderboard and achievement so they are reviewed with version 1.0.0. IDs never change; titles and art can.

## Leaderboards

Classic leaderboards, integer score, high to low, best score kept.

| ID | English | Russian |
|---|---|---|
| `echo.rating.iphone` | Rating — iPhone | Рейтинг — iPhone |
| `echo.rating.watch` | Rating — Apple Watch | Рейтинг — Apple Watch |

The iPhone rating is Route Seals × 100 + best Deep Time depth × 250 + completed passes × 1000. The Apple Watch rating is cleared rooms × 100 + 10 per second of best times under par. Both are sent from the iPhone when they change.

## Achievements

Not hidden, earned once, 970 points in total. Art is 1024 × 1024 in `achievements/` (generated with the Codex image tool, then scaled).

| ID | Points | English title | Before | After | Russian title | До | После |
|---|---|---|---|---|---|---|---|
| `echo.ach.first_light` | 10 | First Light | Clear your first map. | The Signal is lit. | Первый свет | Пройди первую карту. | Сигнал зажжён. |
| `echo.ach.lighthouse` | 25 | Lighthouse Relit | Clear every map of the Lighthouse. | The reference station answers again. | Маяк снова светит | Пройди все карты Маяка. | Опорная станция снова отвечает. |
| `echo.ach.ashcrown` | 50 | Past Ashcrown | Clear every map of the Ashcrown Corona. | The channels held while the star died. | Мимо Эшкрауна | Пройди все карты Короны Эшкрауна. | Каналы выдержали, пока звезда умирала. |
| `echo.ach.last_dawn` | 100 | Last Dawn | Finish all 77 maps of the Fold Road. | The Road ends where it began. | Последний рассвет | Пройди все 77 карт Дороги складок. | Дорога кончается там, где началась. |
| `echo.ach.second_pass` | 100 | Second Pass | Complete two passes of the Fold Road. | The recovery runs again, harder. | Второй обход | Заверши два обхода Дороги складок. | Восстановление идёт снова — и строже. |
| `echo.ach.seals_100` | 50 | Seal Keeper | Earn 100 Route Seals. | A hundred routes confirmed. | Хранитель знаков | Получи 100 знаков маршрута. | Сто маршрутов подтверждено. |
| `echo.ach.seals_all` | 100 | Every Seal | Earn all 231 Route Seals in one pass. | Not one route left unconfirmed. | Все знаки | Получи все 231 знак маршрута за один обход. | Ни одного неподтверждённого маршрута. |
| `echo.ach.deep_10` | 50 | Deep Diver | Reach depth 10 in Deep Time. | Ten layers below the Road. | Десятая глубина | Достигни глубины 10 в Глубоком времени. | Десять слоёв под Дорогой. |
| `echo.ach.deep_25` | 100 | Below the Road | Reach depth 25 in Deep Time. | Few signals come back from this deep. | Под Дорогой | Достигни глубины 25 в Глубоком времени. | Немногие сигналы возвращаются с такой глубины. |
| `echo.ach.daily_rift` | 25 | Daily Diagnostic | Clear a Daily Rift. | Today's stop is confirmed. | Ежедневная диагностика | Пройди ежедневный разрыв. | Сегодняшний узел подтверждён. |
| `echo.ach.calibration` | 50 | Calibrated | Clear the 12 Calibration rooms on Apple Watch. | The chronometer keeps time. | Калибровка пройдена | Пройди 12 комнат калибровки на Apple Watch. | Хронометр держит время. |
| `echo.ach.regulation` | 75 | Regulated | Clear the 12 Regulation rooms on Apple Watch. | Every part of the movement is in tune. | Регулировка пройдена | Пройди 12 комнат регулировки на Apple Watch. | Каждая деталь механизма настроена. |
| `echo.ach.certification` | 100 | Certified Chronometer | Clear all 36 chronometer rooms on Apple Watch. | The observatory trial is passed. | Сертифицированный хронометр | Пройди все 36 комнат хронометра на Apple Watch. | Обсерваторское испытание пройдено. |
| `echo.ach.under_par` | 75 | Ahead of Time | Beat par in 12 chronometer rooms. | Faster than the chronometer expects. | С опережением | Пройди 12 комнат хронометра быстрее нормы. | Быстрее, чем ждёт хронометр. |
| `echo.ach.research` | 60 | Signal Matrix | Research every node of the Signal Matrix. | Every branch of the Signal answers. | Матрица Сигнала | Изучи каждый узел Матрицы Сигнала. | Каждая ветвь Сигнала отвечает. |
