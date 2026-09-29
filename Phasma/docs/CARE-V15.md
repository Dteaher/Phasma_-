# Версия 0.15 — забота, домики и игровое время

На главном экране оставлены питомец, небольшая полоска мечты и кнопки заботы и истории. План, копилка, магазин, игры, знания, задания и оформление комнаты доступны во вкладке «План».

После покупки корма миску можно перетащить к питомцу. Для ухода нужно взять расчёску и провести ею по питомцу: движение заполняет полоску, вызывает сердечки и короткие прыжки. Предмет, отпущенный в стороне, не засчитывается. Уход связан с основным приключением. Повтор не списывает деньги, не добавляет награду и не ускоряет часы.

Внизу карты добавлена иллюстрированная улица с пятью домиками. Первый принадлежит текущему питомцу, следующие открываются после 1–4 исполненных мечт. Завершённый домик ведёт к сохранённым друзьям и их мечтам, открытый новый — к выбору питомца.

Игровые часы начинаются в 09:00. Финансовые действия и первый уход за неделю продвигают часы на два часа; с 20:00 до 07:00 включается ночное освещение. Кнопка «Спать до утра» переводит часы на 09:00 без изменения денег, наград и недельного бюджета. Реальное ожидание не требуется. Дни — визуальный ритм; бюджет по-прежнему составляется на игровые недели.

Сохранения совместимы с предыдущей версией: отсутствующие поля часов и ухода получают начальные значения при загрузке.

Проверено: 29 автоматических проверок, включая перетаскивание корма и расчёски в основном сценарии, повторные действия, сохранение, переход через полночь и рендеры экранов. Снимки: `output/screenshots-v2/`.

## Новая графика

Файл: `assets/art/friends-street-v15.png`. Создан встроенным imagegen, затем скопирован в проект. Сначала сгенерирована улица в стиле существующей карты, затем убраны изображения животных с фасадов, чтобы в каждом домике мог жить любой питомец.

Промпт генерации:

> Create a NEW portrait-format illustrated fantasy village map background for a Russian children's mobile game, to be used below the existing city map. Use the attached city illustration only as a style and palette reference: luminous polished 3D storybook art, sunny green trees, cobblestone winding path, tiny gardens, flowers, blue stream, colorful roofs. Show five clearly DISTINCT small cozy animal cottages in a readable two-column staggered layout: two in the upper third, two in the middle third, one lower left. Each cottage should be fully visible and separated by grass/path so clickable labels can be overlaid later. Leave a little clear space above and below. Orthographic/isometric map viewpoint matching reference. No interface, no cards, no locks, no labels, no text, no characters, no logos, no border. High detail but clean composition suitable as mobile map background.

Промпт финальной правки:

> Edit the supplied village map image. Preserve the exact five-cottage layout, cobblestone paths, gardens, river, trees, painterly game style, colors, camera angle, and portrait composition. Change only the animal-shaped roofs/facades (rabbit ears, bear face, fox ears/face, owl eyes/beak, cat ears/whiskers) into five ordinary but distinct whimsical cottage designs with colorful roofs and windows. These homes must be neutral so any pet species can live in any one. No characters, text, labels, cards, UI, or locks.
