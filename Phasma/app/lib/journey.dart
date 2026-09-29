part of 'main.dart';

extension _Journey on _GameRootState {
  Widget journey() {
    if (g.finished) return ending();
    final practiced = g
        .strings('done')
        .any((id) => id.startsWith('${g.period}:'));
    final remaining =
        (c.goal(g.s['goal'] as String)['cost'] as int) - g.savings;
    final purchased = g.strings('purchases');
    final feedPending = purchased.contains('food') && !g.fedThisWeek;
    final groomPending = purchased.contains('care') && !g.groomedThisWeek;
    final needs = [
      'food',
      'water',
      'care',
    ].where((id) => !purchased.contains(id)).toList();
    final saved = (g.s['saved'] as int) - (g.s['withdrawn'] as int) > 0;
    final stage = !g.planned
        ? 0
        : !practiced
        ? 1
        : needs.isNotEmpty || feedPending || groomPending
        ? 2
        : !saved && remaining > 0
        ? 3
        : 4;
    final summary = g.s['phase'] == 'summary';
    Widget choice(String label, String Function(Game) action) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: GameButton(label, onPressed: () => journeyAct(action)),
      ),
    );
    return SingleChildScrollView(
      key: ValueKey(
        'journey-${g.period}-$stage-$summary-${needs.join()}-${g.s['eventDone']}',
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Column(
            children: [
              panel(
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Приключение ${g.period}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    money(g.balance, label: ''),
                  ],
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Expanded(
                      child: Container(
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= stage ? sunshine : Colors.white54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              PetScene(
                pet: g.s['pet'] as int,
                color: g.s['color'] as int,
                height: 145,
                background: false,
                animate: g.s['animations'] == true,
              ),
              if (journeyMessage.isNotEmpty)
                panel(
                  Text(
                    journeyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  color: const Color(0xFFFFF1C9),
                ),
              if (remaining <= 0) ...[
                panel(
                  const Text(
                    'Получилось! На мечту уже хватает. Давай исполним её!',
                    textAlign: TextAlign.center,
                  ),
                ),
                choice('Исполнить мечту!', (game) => game.fulfill(c)),
              ] else if (summary) ...[
                const Icon(Icons.stars_rounded, color: sunshine, size: 70),
                panel(
                  Text(
                    'Мы справились! В копилке ${g.savings} монеток.\nДо мечты осталось $remaining.',
                    textAlign: TextAlign.center,
                  ),
                ),
                choice('Вперёд! Новое приключение', (game) => game.next()),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: deepPurple,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => go('history'),
                  child: const Text('Посмотреть план и результат'),
                ),
              ] else if (stage == 0) ...[
                panel(
                  Text(
                    '${g.name}: «Сначала оставим 50 монеток на корм, воду и уход. А сколько запланируем на мечту?»',
                    textAlign: TextAlign.center,
                  ),
                ),
                for (final amount in [20, 40, 60])
                  if (g.balance >= 50 + amount)
                    choice(
                      '$amount на мечту · ${g.balance - 50 - amount} на желания',
                      (game) =>
                          game.setPlan(50, game.balance - 50 - amount, amount),
                    ),
                const SizedBox(height: 8),
                panel(
                  const Text(
                    'Это только план. Монетки пока остаются у тебя.',
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: deepPurple,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => go('budget'),
                  child: const Text('Распределить по-своему'),
                ),
              ] else if (stage == 1) ...[
                panel(
                  const Text(
                    'Совёнок приготовил игру. Попробуем? За решение получим 10 монеток!',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (g.period % 3 == 2) ...[
                  const Icon(
                    Icons.local_shipping_rounded,
                    size: 70,
                    color: sunshine,
                  ),
                  GameButton(
                    'Доставить посылки',
                    onPressed: () => go('delivery'),
                  ),
                ] else if (g.period % 3 == 0) ...[
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 70,
                    color: sunshine,
                  ),
                  GameButton(
                    'Найти ошибку в чеке',
                    onPressed: () => go('receipt'),
                  ),
                ] else
                  TaskCard(
                    key: ValueKey(
                      '${g.period}:${g.availableTasks(c).first['id']}',
                    ),
                    task: g.availableTasks(c).first,
                    done: false,
                    onAnswer: (answer) => journeyAct(
                      (game) => game.answer(
                        g.availableTasks(c).first['id'] as String,
                        answer,
                        c,
                      ),
                    ),
                  ),
                gameExit('Выбрать другую игру', () => go('playground')),
              ] else if (stage == 2) ...[
                if (feedPending || groomPending) ...[
                  panel(
                    Text(
                      feedPending
                          ? 'Корм куплен. Теперь покорми ${g.name} сам: перетащи миску к питомцу.'
                          : 'Уход куплен. Проведи расчёской по шёрстке ${g.name}.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ItemArt(feedPending ? 'food' : 'care', size: 110),
                  GameButton(
                    feedPending ? 'Покормить самому' : 'Причесать самому',
                    icon: Icons.favorite_rounded,
                    onPressed: () => go('care-play'),
                  ),
                ] else if (needs.first == 'food') ...[
                  panel(
                    const Text(
                      'Я проголодался! В двух лавках одинаковый корм. Где купим?',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const ItemArt('food', size: 110),
                  choice(
                    'Лавка у дома · 30 монеток',
                    (game) => game.market(0, c),
                  ),
                  choice(
                    'Лавка у парка · 24 монетки',
                    (game) => game.market(1, c),
                  ),
                ] else ...[
                  panel(
                    Text(
                      needs.first == 'water'
                          ? 'Спасибо за корм! Теперь попить бы воды.'
                          : 'Нужна расчёска — потом причешем шёрстку сами!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ItemArt(needs.first, size: 110),
                  choice(
                    '${needs.first == 'water' ? 'Дать воду' : 'Купить уход'} · ${c.item(needs.first)['price']} монеток',
                    (game) => game.buy(needs.first, c),
                  ),
                ],
                if (needs.isNotEmpty &&
                    g.balance < (c.item(needs.first)['price'] as int))
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: deepPurple,
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => go('savings'),
                    child: const Text('Открыть копилку'),
                  ),
              ] else if (g.hasEvent && g.s['eventDone'] != true) ...[
                panel(
                  const Text(
                    'Ой, порвался рюкзак! Починим или возьмём запасной у совёнка?',
                    textAlign: TextAlign.center,
                  ),
                ),
                const ItemArt('backpack', size: 110),
                choice('Починить · 20 монеток', (game) => game.event(true)),
                choice(
                  'Взять запасной · бесплатно',
                  (game) => game.event(false),
                ),
              ] else if (stage == 3) ...[
                panel(
                  Text(
                    'Теперь приблизим мечту! У нас ${g.balance} монеток. Сколько положим в копилку?',
                    textAlign: TextAlign.center,
                  ),
                ),
                ItemArt(g.s['goal'] as String, size: 110),
                for (final amount in {
                  10,
                  20,
                  40,
                  if (remaining < 40) remaining,
                })
                  if (amount > 0 && amount <= g.balance && amount <= remaining)
                    choice(
                      'Отложить $amount монеток',
                      (game) => game.deposit(amount, c),
                    ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: deepPurple,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => go('savings'),
                  child: const Text('Выбрать другую сумму'),
                ),
              ] else ...[
                panel(
                  Text(
                    'Я сыт, причёсан, а мечта стала ближе!\nВ копилке ${g.savings} монеток.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const Icon(Icons.auto_awesome, color: sunshine, size: 64),
                choice('Завершить приключение', (game) {
                  if (game.missionProgress.every((done) => done) &&
                      !game.used('mission')) {
                    game.claimMission();
                  }
                  return game.end(c);
                }),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: deepPurple,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => go('memory'),
                  child: const Text('Ещё сыграть в список покупок'),
                ),
              ],
              if (g.balance < 30 && g.active && g.planned)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: deepPurple,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => go('tasks'),
                  child: const Text('Другие задания с наградой'),
                ),
              if (stage == 3 && g.balance == 0)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: deepPurple,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: _finishWeek,
                  child: const Text('В этот раз закончим без накоплений'),
                ),
              if (g.balance < 30 &&
                  g.active &&
                  g.planned &&
                  g.s['rescue'] != true)
                choice('Помощь совёнка · 30 монеток', (game) => game.rescue()),
              if (g.finished)
                GameButton('Посмотреть финал', onPressed: () => go('')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Untimed practice: remember a list, then buy only what was planned.
class MemoryGame extends StatefulWidget {
  final VoidCallback onHome;
  final VoidCallback? onComplete;
  const MemoryGame({super.key, required this.onHome, this.onComplete});
  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  static const goods = ['food', 'water', 'care', 'ball', 'hat', 'plant'];
  int round = 0;
  bool shopping = false, won = false;
  String feedback = '';
  late List<String> targets;
  late List<String> shelf;
  final selected = <String>{};
  @override
  void initState() {
    super.initState();
    prepare();
  }

  void prepare() {
    shelf = [...goods]..shuffle();
    targets = shelf.take(round + 2).toList();
    shelf.shuffle();
    selected.clear();
    shopping = false;
    won = false;
    feedback = '';
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        panel(
          Column(
            children: [
              Text(
                'Раунд ${round + 1} из 3',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: purple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                won
                    ? 'Все покупки по списку!'
                    : shopping
                    ? 'Что было в списке?'
                    : 'Запомни покупки для прогулки',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                won
                    ? 'Список помогает не покупать лишнее.'
                    : shopping
                    ? 'Нажми на нужные товары. Повторное нажатие убирает товар.'
                    : 'Не торопись. Когда запомнишь, открой лавку.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (!shopping) ...[
          panel(
            Wrap(
              alignment: WrapAlignment.center,
              children: [for (final id in targets) ItemArt(id, size: 95)],
            ),
          ),
          GameButton(
            'Я запомнил! В лавку',
            onPressed: () => setState(() => shopping = true),
          ),
        ] else if (!won) ...[
          GridView.count(
            crossAxisCount: MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 2
                : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final id in shelf)
                Semantics(
                  label: id,
                  selected: selected.contains(id),
                  button: true,
                  child: InkWell(
                    key: ValueKey('memory-$id'),
                    onTap: () => setState(() {
                      if (!selected.add(id)) selected.remove(id);
                    }),
                    child: AnimatedContainer(
                      duration: MotionSettings.enabledOf(context)
                          ? const Duration(milliseconds: 180)
                          : Duration.zero,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected.contains(id)
                              ? sunshine
                              : Colors.white,
                          width: 5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(9),
                            child: ItemArt(id, size: 105),
                          ),
                          if (selected.contains(id))
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(Icons.check_circle, color: green),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (feedback.isNotEmpty)
            panel(Text(feedback, textAlign: TextAlign.center)),
          GameButton(
            'Проверить корзину',
            onPressed: () => setState(() {
              won =
                  selected.length == targets.length &&
                  targets.every(selected.contains);
              if (won && round == 2) widget.onComplete?.call();
              feedback = won
                  ? ''
                  : 'Есть лишнее или чего-то не хватает. Можно подсмотреть список и попробовать ещё!';
            }),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: deepPurple,
              backgroundColor: Colors.white,
            ),
            onPressed: () => setState(() => shopping = false),
            child: const Text('Подсмотреть список'),
          ),
        ] else ...[
          const EnterMotion(
            pop: true,
            child: Icon(Icons.emoji_events_rounded, size: 95, color: sunshine),
          ),
          panel(
            Text(
              round == 2
                  ? 'Три звезды! Ты собрал всё нужное и ничего лишнего. Достижение: «Мастер списка».'
                  : 'Звезда твоя! Следующий список будет чуть длиннее.',
              textAlign: TextAlign.center,
            ),
          ),
          GameButton(
            round == 2 ? 'Сыграть ещё' : 'Следующий раунд',
            onPressed: () => setState(() {
              round = round == 2 ? 0 : round + 1;
              prepare();
            }),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onHome,
            style: OutlinedButton.styleFrom(
              foregroundColor: deepPurple,
              backgroundColor: Colors.white,
              side: const BorderSide(color: purple, width: 2),
              minimumSize: const Size(48, 54),
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            icon: const Icon(Icons.pets_rounded),
            label: const Text('Вернуться к питомцу'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Тренировка бесплатная: игровые монетки не тратятся.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            shadows: [Shadow(color: deepPurple, blurRadius: 5)],
          ),
        ),
      ],
    ),
  );
}
