part of 'main.dart';

extension _SimpleHome on _GameRootState {
  Future<void> _finishWeek() async {
    if (await confirm(
      'Закончить неделю?',
      'Посмотрим, как получился план и что изменилось.',
      button: 'Подвести итог',
    )) {
      await act((game) => game.end(c));
      if (g.s['phase'] == 'summary') go('history');
    }
  }

  Widget homeV3() {
    final goal = c.goal(g.s['goal'] as String);
    final cost = goal['cost'] as int;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        key: const ValueKey('home-v3'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .95),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE8D6FF),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              g.isNight
                                  ? 'Тихая ночь дома'
                                  : 'Твой друг ждёт тебя',
                              style: const TextStyle(
                                fontSize: 12,
                                color: purple,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      money(g.balance, label: ''),
                    ],
                  ),
                ),
                SizedBox(
                  height: (box.maxHeight * .44).clamp(255, 355),
                  child: PetScene(
                    pet: g.s['pet'] as int,
                    color: g.s['color'] as int,
                    stage: g.stage,
                    hat: g.s['hat'] == true,
                    ball: g.strings('inventory').contains('ball'),
                    plant: g.strings('inventory').contains('plant'),
                    animate: g.s['animations'] == true,
                    reaction:
                        g.savings * 10 +
                        g.period * 10000 +
                        g.strings('purchases').length,
                    background: false,
                    height: 355,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xF9FFF8E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sunshine, width: 2),
                  ),
                  child: Row(
                    children: [
                      ItemArt(goal['id'] as String, size: 54),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Мечта — ${goal['name']}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            DreamProgress(
                              value: (g.savings / cost).clamp(0, 1),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(10),
                              backgroundColor: const Color(0xFFDCD8E9),
                              color: vividGreen,
                            ),
                            Text(
                              '${g.savings} из $cost монеток',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: GameButton(
                    'Позаботиться о друге',
                    icon: Icons.favorite_rounded,
                    onPressed: () => go('care-play'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GameButton(
                    g.s['phase'] == 'summary'
                        ? 'Новое приключение'
                        : 'Продолжить историю',
                    icon: Icons.play_arrow_rounded,
                    green: true,
                    onPressed: () => go('journey'),
                  ),
                ),
                if (store.recovery != null) owl(store.recovery!),
                if (g.isNight)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: GameButton(
                      'Спать до утра',
                      icon: Icons.nightlight_round,
                      onPressed: () =>
                          act((game) => game.restUntilMorning(), show: false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget planHub() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            panel(
              Column(
                children: [
                  const Text(
                    'Мой план и занятия',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: deepPurple,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'День ${g.gameDay} • ${g.clockLabel} • ${g.planned ? 'план готов' : 'составим план'}',
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Игровые часы идут после действий. Ждать не нужно.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: purple),
                  ),
                ],
              ),
            ),
            for (final item in [
              (
                'План монеток',
                'Реши, сколько оставить на нужное и мечту',
                Icons.pie_chart_rounded,
                'budget',
              ),
              (
                'Копилка',
                'Посмотри, как растёт мечта',
                Icons.savings_rounded,
                'savings',
              ),
              (
                'Магазин',
                'Корм, уход и маленькие радости',
                Icons.shopping_bag_rounded,
                'shop',
              ),
              (
                'Игры',
                'Зарабатывай и тренируйся выбирать',
                Icons.extension_rounded,
                'playground',
              ),
              (
                'Знания',
                'Подсказки совёнка о деньгах',
                Icons.auto_stories_rounded,
                'lessons',
              ),
              (
                'Задания',
                'Практика и новые монетки',
                Icons.assignment_rounded,
                'tasks',
              ),
              (
                'Приключения',
                'Лавки, выборы и прогулки',
                Icons.explore_rounded,
                'adventures',
              ),
              (
                'Как играть',
                'Правила и первые шаги',
                Icons.help_outline_rounded,
                'guide',
              ),
              ('Комната', 'Укрась дом питомца', Icons.bed_rounded, 'wardrobe'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white.withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(19),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () =>
                        item.$4 == 'lessons' ? go('lessons') : go(item.$4),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: const Color(0xFFDAD2FF),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFFFE178),
                            child: Icon(item.$3, color: deepPurple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$1,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  item.$2,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: purple,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
