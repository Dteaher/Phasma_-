part of 'main.dart';

extension _IllustratedScreens on _GameRootState {
  Widget homeV2() => homeV3();

  Widget shopV2() => SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            panel(
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Выбирай с умом!',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  money(g.balance, label: ''),
                ],
              ),
            ),
            if (g.hasNeed(c))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GameButton(
                  'Забота готова — к копилке',
                  onPressed: () => go('savings'),
                ),
              )
            else
              owl(
                'Сначала нужны корм, вода и уход. Они стоят 50 монеток вместе. После этого можно выбрать что-то для радости.',
              ),
            if (!g.planned)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GameButton(
                  'Сначала составим план',
                  onPressed: () => go('budget'),
                ),
              ),
            for (final category in ['need', 'want']) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 6),
                child: HeaderPill(
                  category == 'need'
                      ? 'Нужно • забота каждый день'
                      : 'Хочу • маленькие радости',
                ),
              ),
              LayoutBuilder(
                builder: (context, box) {
                  final columns =
                      MediaQuery.textScalerOf(context).scale(1) > 1.25 ? 2 : 3;
                  final w = (box.maxWidth - 8 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      for (final item in c.items.where(
                        (e) => e['category'] == category,
                      ))
                        SizedBox(
                          width: w,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => purchaseV2(item),
                              borderRadius: BorderRadius.circular(17),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(5, 7, 5, 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFFFF7D7)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66582680),
                                      offset: Offset(0, 3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    ItemArt(
                                      item['id'] as String,
                                      size: w * .86,
                                    ),
                                    Text(
                                      item['name'] as String,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    money(item['price'] as int, label: ''),
                                    if (g
                                            .strings('inventory')
                                            .contains(item['id']) ||
                                        g
                                            .strings('purchases')
                                            .contains(item['id']))
                                      const Text(
                                        'Уже куплено',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: green,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            owl(
              'Сначала проверь, хватит ли на нужное. Затем выбирай приятные вещи и монетки на мечту.',
            ),
            if (g.balance < 30 && !g.hasNeed(c))
              GameButton(
                'Помощь совёнка',
                green: true,
                onPressed: () => act((g) => g.rescue()),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> purchaseV2(Json item) async {
    final price = item['price'] as int;
    if (g.balance < price) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: panel(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HeaderPill('Недостаточно монеток'),
                PetArt(
                  pet: g.s['pet'] as int,
                  color: g.s['color'] as int,
                  size: 170,
                ),
                Text(
                  'Не хватает ${price - g.balance} монеток',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Можно выполнить доступное задание, отложить покупку или выбрать другой товар.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                GameButton(
                  'К заданиям',
                  onPressed: () {
                    Navigator.pop(ctx);
                    go('tasks');
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Другие товары'),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: panel(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HeaderPill('Покупка'),
                ItemArt(item['id'] as String, size: 170),
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                money(price),
                const SizedBox(height: 10),
                Text(
                  '${item['category'] == 'need' ? 'Нужно' : 'Хочу'} • ${item['effect']}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'После покупки: ${g.balance - price} монеток',
                  style: const TextStyle(fontSize: 13, color: purple),
                ),
                const SizedBox(height: 16),
                GameButton(
                  'Купить',
                  green: true,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (yes == true) await act((g) => g.buy(item['id'] as String, c));
  }

  Widget cityV2() => LayoutBuilder(
    builder: (context, box) {
      final h = box.maxHeight < 600 ? 650.0 : box.maxHeight;
      final neighborhoodHeight = 600.0;
      return SingleChildScrollView(
        child: SizedBox(
          height: h + neighborhoodHeight,
          width: box.maxWidth,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: h,
                child: Image.asset(
                  'assets/art/city-v2.png',
                  fit: BoxFit.fill,
                  color: g.isNight ? const Color(0xFF8588BD) : null,
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
              Positioned(
                top: 8,
                left: 30,
                right: 30,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFABCCFF),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Прокрути карту вниз:\nтам домики наших друзей!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: purple,
                    ),
                  ),
                ),
              ),
              for (final place in [
                ('Дом друзей', .07, .24, 'friends', true),
                ('Магазин', .58, .30, 'shop', true),
                (
                  'Парк',
                  .07,
                  .49,
                  'adventures',
                  g.period > 2 || g.strings('badges').contains('Парк открыт'),
                ),
                ('Школа знаний', .56, .55, 'tasks', true),
                ('Копилка', .07, .78, 'savings', true),
                (
                  'Мастерская',
                  .56,
                  .83,
                  'wardrobe',
                  g.records('album').isNotEmpty,
                ),
              ])
                Positioned(
                  left: box.maxWidth * place.$2,
                  top: h * place.$3,
                  width: box.maxWidth * .36,
                  child: Semantics(
                    button: true,
                    label: place.$1,
                    child: InkWell(
                      onTap: () {
                        if (!place.$5) {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(place.$1),
                              content: Text(
                                place.$1 == 'Парк'
                                    ? 'Парк откроется после второй недели.'
                                    : 'Мастерская откроется после первой исполненной мечты.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Понятно'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        if (place.$4.isEmpty) {
                          updateView(() => tab = 0);
                        } else {
                          go(place.$4);
                        }
                      },
                      child: Column(
                        children: [
                          if (!place.$5)
                            const Icon(
                              Icons.lock_rounded,
                              size: 39,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: deepPurple, blurRadius: 5),
                              ],
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: place.$5
                                  ? Colors.white
                                  : const Color(0xFFD9D6E9),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: place.$5
                                    ? const Color(0xFFC5F080)
                                    : Colors.white,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x88442C55),
                                  offset: Offset(0, 3),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                place.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: h,
                left: 0,
                right: 0,
                height: neighborhoodHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/art/friends-street-v15.png',
                        fit: BoxFit.fill,
                        color: g.isNight ? const Color(0xFF8588BD) : null,
                        colorBlendMode: BlendMode.modulate,
                      ),
                    ),
                    const Positioned(
                      top: 5,
                      left: 45,
                      right: 45,
                      child: HeaderPill('Улица друзей'),
                    ),
                    for (var index = 0; index < 5; index++)
                      friendMapHouse(index, box.maxWidth, neighborhoodHeight),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget friendMapHouse(int index, double width, double height) {
    final stories = g.records('album');
    final completed = index < stories.length;
    final current = index == stories.length && !g.finished;
    final unlocked = index <= stories.length;
    final story = completed ? stories[index] : null;
    final label = completed
        ? story!['name'] as String
        : current
        ? g.name
        : 'Новый друг';
    final left = [0.02, 0.54, 0.02, 0.54, 0.02][index];
    final top = [0.10, 0.10, 0.40, 0.40, 0.69][index];
    return Positioned(
      left: width * left,
      top: height * top,
      width: width * .44,
      height: height * .23,
      child: PressMotion(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (completed) {
                go('friends');
                return;
              }
              if (current) {
                updateView(() {
                  tab = 0;
                  screen = '';
                });
                return;
              }
              if (unlocked && g.finished) {
                startAnotherFriend();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Домик откроется после ${index == 1 ? 'первой' : '$index исполненных'} мечты.',
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!unlocked)
                  const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 30,
                    shadows: [Shadow(color: deepPurple, blurRadius: 6)],
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: unlocked
                        ? const Color(0xF9FFF8E5)
                        : const Color(0xF0E8E5F1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: unlocked ? sunshine : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: deepPurple,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        completed
                            ? 'Мечта сбылась!'
                            : current
                            ? 'Наш домик'
                            : unlocked
                            ? 'Выбрать питомца'
                            : 'Откроется после\n$index-й мечты',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: purple,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
