part of 'main.dart';

extension _AdventuresScreen on _GameRootState {
  Widget adventures() => Column(
    children: [
      Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F6FF),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: purple, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Неделя ${g.period}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                money(g.balance, label: ''),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  ChoiceChip(
                    label: Text(['Цели', 'Лавки', 'Выбор', 'Прогулка'][i]),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    selected: adventureTab == i,
                    showCheckmark: false,
                    selectedColor: purple,
                    backgroundColor: const Color(0xFFEDE6FF),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: adventureTab == i ? Colors.white : deepPurple,
                      fontWeight: FontWeight.w800,
                    ),
                    onSelected: (_) => updateView(() => adventureTab = i),
                  ),
              ],
            ),
          ],
        ),
      ),
      Expanded(
        child: KeyedSubtree(
          key: ValueKey(adventureTab),
          child: list([
            if (!g.canExplore)
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.finished
                          ? 'Мечта исполнена! Продолжим в новой истории.'
                          : 'Сначала составь план. После итогов начни новую неделю.',
                    ),
                    if (!g.planned && !g.finished)
                      TextButton.icon(
                        onPressed: () => go('budget'),
                        icon: const Icon(Icons.pie_chart_rounded),
                        label: const Text('К плану недели'),
                      ),
                  ],
                ),
              ),
            if (adventureTab == 0) ...[
              titleText('Три шага к звезде'),
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Звёзды заботы: ${g.s['missionStars'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 8,
                              top: 10,
                              bottom: 10,
                            ),
                            child: Icon(
                              Icons.stars_rounded,
                              size: 38,
                              color: (g.s['missionStars'] as int? ?? 0) > i
                                  ? gold
                                  : const Color(0xFFD9D1EA),
                            ),
                          ),
                      ],
                    ),
                    const Text('Три звезды откроют звание «Хранитель мечты».'),
                    for (var i = 0; i < 3; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        trailing: g.missionProgress[i]
                            ? null
                            : const Icon(Icons.chevron_right, color: purple),
                        onTap: g.missionProgress[i]
                            ? null
                            : () {
                                if (i == 2) {
                                  updateView(() => adventureTab = 3);
                                } else {
                                  go(i == 0 ? 'shop' : 'savings');
                                }
                              },
                        leading: Icon(
                          g.missionProgress[i]
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: g.missionProgress[i] ? green : purple,
                        ),
                        title: Text(
                          [
                            'Купить корм, воду и уход',
                            'Пополнить копилку минимум на 20 за неделю',
                            'Пройти любую финансовую практику',
                          ][i],
                        ),
                      ),
                    GameButton(
                      g.used('mission')
                          ? 'Звезда уже получена'
                          : g.missionProgress.every((v) => v)
                          ? 'Получить звезду'
                          : 'Выполнено ${g.missionProgress.where((v) => v).length} из 3',
                      green: true,
                      onPressed:
                          g.canExplore &&
                              !g.used('mission') &&
                              g.missionProgress.every((v) => v)
                          ? () => act((g) => g.claimMission())
                          : null,
                    ),
                  ],
                ),
              ),
            ],
            if (adventureTab == 1) ...[
              titleText('Две лавки — один корм'),
              panel(
                Column(
                  children: [
                    const ItemArt('food', size: 90),
                    const Text(
                      'Одинаковые 3 порции, одинаковое качество. Выбери предложение: это настоящая покупка корма на неделю.',
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < 2; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GameButton(
                          g.strings('purchases').contains('food')
                              ? 'Корм уже куплен'
                              : 'Лавка ${i == 0 ? 'А' : 'Б'} • ${i == 0 ? 30 : 24} монетки',
                          onPressed:
                              g.canExplore &&
                                  !g.strings('purchases').contains('food')
                              ? () async {
                                  if (await confirm(
                                    'Купить корм?',
                                    'Будет потрачено ${i == 0 ? 30 : 24} монеток из кошелька.',
                                    button: 'Купить',
                                  )) {
                                    await act((g) => g.market(i, c));
                                  }
                                }
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (adventureTab == 2) ...[
              titleText('Скидка или мечта?'),
              panel(
                Column(
                  children: [
                    const ItemArt('ball', size: 90),
                    Text(
                      'Мяч за 20 вместо 30. В кошельке ${g.balance}, в копилке ${g.savings}. Покупка даст игрушку, накопление приблизит мечту.',
                    ),
                    const SizedBox(height: 12),
                    if (g.used('temptation'))
                      const Text(
                        'Решение этой недели принято. Посмотреть результат можно в истории.',
                      )
                    else
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GameButton(
                            [
                              'Купить мяч • 20',
                              'В копилку • до 20',
                              'Оставить деньги свободными',
                            ][i],
                            onPressed: g.canExplore
                                ? () async {
                                    final left =
                                        (c.goal(g.s['goal'] as String)['cost']
                                            as int) -
                                        g.savings;
                                    if (await confirm(
                                      'Твоё решение',
                                      [
                                        'Потратить 20 монеток и получить мяч?',
                                        'Перевести ${left < 20 ? left : 20} монеток из кошелька в копилку?',
                                        'Закрыть предложение на эту неделю и оставить деньги в кошельке?',
                                      ][i],
                                    )) {
                                      await act((g) => g.temptation(i, c));
                                    }
                                  }
                                : null,
                          ),
                        ),
                  ],
                ),
              ),
            ],
            if (adventureTab == 3) ...[
              titleText('Финансовая прогулка'),
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.trail[0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (g.used('trail'))
                      Text('Прогулка пройдена! ${g.trail[3]}')
                    else ...[
                      const Text(
                        'За верное решение — 10 монеток один раз за неделю. Ошибку можно исправить.',
                      ),
                      for (var i = 0; i < 2; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: OutlinedButton(
                            onPressed: g.canExplore
                                ? () => act((g) => g.answerTrail(i))
                                : null,
                            child: Text(g.trail[i == g.trailCorrect ? 1 : 2]),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ]),
        ),
      ),
    ],
  );
}
