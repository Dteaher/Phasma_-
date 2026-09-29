part of 'main.dart';

Widget gameExit(String label, VoidCallback action) => Padding(
  padding: const EdgeInsets.only(top: 14),
  child: SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: deepPurple,
        backgroundColor: Colors.white,
        side: const BorderSide(color: purple, width: 2),
      ),
      onPressed: action,
      icon: const Icon(Icons.arrow_back_rounded),
      label: Text(label),
    ),
  ),
);

extension _Playground on _GameRootState {
  Widget playground() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            panel(
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE45B88),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Дружба: ${g.s['friendship'] ?? 0} сердечек',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: deepPurple,
                      ),
                    ),
                  ),
                  const Text(
                    '4 игры',
                    style: TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (!g.canExplore)
              panel(
                Column(
                  children: [
                    const Text(
                      'Играй бесплатно. За монетками — в приключение!',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => go('journey'),
                      child: const Text('Выбрать план и получать награды'),
                    ),
                  ],
                ),
              ),
            for (final entry in [
              (
                'Курьер',
                'Доставь 3 посылки за 12 шагов',
                'backpack',
                'delivery',
                const Color(0xFFD4F1E6),
              ),
              (
                'Детектив чеков',
                'Найди ошибку в покупке',
                'care',
                'receipt',
                const Color(0xFFFFE3B6),
              ),
              (
                'Мяч с питомцем',
                'Лови мяч и собирай сердечки',
                'ball',
                'ball-play',
                const Color(0xFFFFDCE8),
              ),
              (
                'Список покупок',
                'Запоминай и собирай корзину',
                'food',
                'memory',
                const Color(0xFFE2DBFF),
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, entry.$5],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44251454),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: entry.$5,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: entry.$4 == 'receipt'
                                ? const SizedBox(
                                    width: 62,
                                    height: 62,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          color: deepPurple,
                                          size: 49,
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Icon(
                                            Icons.search_rounded,
                                            color: purple,
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ItemArt(entry.$3, size: 62),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.$1,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.$2,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  entry.$4 == 'memory'
                                      ? '3 раунда · достижение'
                                      : entry.$4 == 'ball-play'
                                      ? g.used(entry.$4)
                                            ? 'Сердечко получено'
                                            : '+1 сердечко дружбы'
                                      : g.used(entry.$4)
                                      ? 'Награда получена'
                                      : g.canExplore
                                      ? '+10 монеток'
                                      : 'Без штрафов',
                                  style: const TextStyle(
                                    color: purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: GameButton(
                          'Играть: ${entry.$1}',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => go(entry.$4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Text(
              'Без таймеров. Ошибаться можно!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: deepPurple, blurRadius: 5)],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget deliveryGame() => DeliveryGame(
    key: ValueKey('delivery-${g.period}'),
    stops: g.deliveryStops,
    onFinish: (path) => store.act((game) => game.finishDelivery(path)),
    onExit: () => go('journey'),
  );
  Widget receiptGame() => ReceiptGame(
    key: ValueKey('receipt-${g.period}'),
    prices: g.receiptPrices,
    quantities: g.receiptQuantities,
    error: g.receiptError,
    onCheck: (row, total) => store.act((game) => game.checkReceipt(row, total)),
    onExit: () => go('journey'),
  );
  Widget ballGame() => BallGame(
    pet: g.s['pet'] as int,
    color: g.s['color'] as int,
    onFinish: () => store.act((game) => game.playWithPet(5)),
    onExit: () => go('playground'),
  );
}

class DeliveryGame extends StatefulWidget {
  final List<int> stops;
  final Future<String> Function(List<int>) onFinish;
  final VoidCallback onExit;
  const DeliveryGame({
    super.key,
    required this.stops,
    required this.onFinish,
    required this.onExit,
  });
  @override
  State<DeliveryGame> createState() => _DeliveryGameState();
}

class _DeliveryGameState extends State<DeliveryGame> {
  final path = <int>[0];
  String message = '';
  bool busy = false, complete = false;
  bool adjacent(int cell) =>
      (cell ~/ 4 - path.last ~/ 4).abs() + (cell % 4 - path.last % 4).abs() ==
      1;
  Future<void> move(int cell) async {
    if (busy || complete || path.length >= 13 || !adjacent(cell)) return;
    setState(() {
      path.add(cell);
      message = '';
    });
    if (widget.stops.every(path.contains)) {
      setState(() => busy = true);
      final result = await widget.onFinish(List.of(path));
      if (mounted) {
        setState(() {
          message = result;
          complete = true;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        panel(
          Column(
            children: [
              const Text(
                'Три посылки — один маршрут',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Старт — почта. Дойди до трёх домов. Нажимай на соседнюю клетку: вверх, вниз, влево или вправо.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Шагов: ${13 - path.length} · Доставлено: ${widget.stops.where(path.contains).length}/3',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (var cell = 0; cell < 16; cell++)
              Semantics(
                label:
                    'Клетка ${cell + 1}${widget.stops.contains(cell) ? ', дом' : ''}',
                button: true,
                child: InkWell(
                  key: ValueKey('route-$cell'),
                  onTap: () => move(cell),
                  child: AnimatedContainer(
                    duration: MotionSettings.enabledOf(context)
                        ? const Duration(milliseconds: 200)
                        : Duration.zero,
                    decoration: BoxDecoration(
                      color: cell == path.last
                          ? sunshine
                          : path.contains(cell)
                          ? const Color(0xFF98D6B5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: adjacent(cell) && !complete
                            ? purple
                            : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        cell == path.last
                            ? Icons.local_shipping_rounded
                            : widget.stops.contains(cell)
                            ? path.contains(cell)
                                  ? Icons.check_circle
                                  : Icons.home_rounded
                            : cell == 0
                            ? Icons.mail_rounded
                            : Icons.circle,
                        color: deepPurple,
                        size:
                            cell == path.last ||
                                widget.stops.contains(cell) ||
                                cell == 0
                            ? 32
                            : 8,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (path.length >= 13 && !complete)
          panel(
            const Text(
              'Шаги закончились. Отмени ход или попробуй другой маршрут — монетки не потрачены.',
            ),
          ),
        if (message.isNotEmpty)
          panel(Text(message, textAlign: TextAlign.center)),
        if (!complete)
          gameExit('Отменить шаг', () {
            if (!busy && path.length > 1) setState(() => path.removeLast());
          }),
        gameExit(complete ? 'Другой маршрут' : 'Начать заново', () {
          if (!busy) {
            setState(() {
              path
                ..clear()
                ..add(0);
              complete = false;
              message = '';
            });
          }
        }),
        gameExit('Продолжить приключение', widget.onExit),
      ],
    ),
  );
}

class ReceiptGame extends StatefulWidget {
  final List<int> prices, quantities;
  final int error;
  final Future<String> Function(int, int) onCheck;
  final VoidCallback onExit;
  const ReceiptGame({
    super.key,
    required this.prices,
    required this.quantities,
    required this.error,
    required this.onCheck,
    required this.onExit,
  });
  @override
  State<ReceiptGame> createState() => _ReceiptGameState();
}

class _ReceiptGameState extends State<ReceiptGame> {
  int? selected, total;
  String message = '';
  bool busy = false, complete = false;
  int get correctTotal => List.generate(
    3,
    (i) => widget.prices[i] * widget.quantities[i],
  ).fold(0, (a, b) => a + b);
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        panel(
          const Text(
            'В одной строке продавец ошибся. Найди её, затем выбери правильный итог. Это учебный чек: покупки не списывают монетки.',
            textAlign: TextAlign.center,
          ),
        ),
        panel(
          Column(
            children: [
              const Text(
                'ЛАВКА СОВЁНКА',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const Divider(),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    key: ValueKey('receipt-row-$i'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected == i ? sunshine : Colors.white,
                      foregroundColor: deepPurple,
                    ),
                    onPressed: complete
                        ? null
                        : () => setState(() => selected = i),
                    child: Row(
                      children: [
                        ItemArt(['food', 'water', 'care'][i], size: 42),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.quantities[i]} × ${widget.prices[i]} = ${widget.quantities[i] * widget.prices[i] + (i == widget.error ? 5 : 0)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(),
              Text(
                'В чеке: ${correctTotal + 5} монеток',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        panel(
          Column(
            children: [
              const Text(
                'Сколько на самом деле?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final amount in [
                    correctTotal - 5,
                    correctTotal,
                    correctTotal + 5,
                  ])
                    ChoiceChip(
                      label: Text('$amount'),
                      selected: total == amount,
                      onSelected: complete
                          ? null
                          : (_) => setState(() => total = amount),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (message.isNotEmpty)
          panel(Text(message, textAlign: TextAlign.center)),
        GameButton(
          complete ? 'Чек проверен!' : 'Проверить чек',
          onPressed: selected == null || total == null || busy || complete
              ? null
              : () async {
                  setState(() => busy = true);
                  final result = await widget.onCheck(selected!, total!);
                  if (mounted) {
                    setState(() {
                      message = result;
                      busy = false;
                      complete =
                          selected == widget.error && total == correctTotal;
                    });
                  }
                },
        ),
        if (!complete)
          gameExit(
            'Подсказка',
            () => setState(
              () => message =
                  'Сначала умножь количество на цену. Затем сложи три правильные суммы. Одна строка завышена на 5 монеток.',
            ),
          ),
        gameExit('Продолжить приключение', widget.onExit),
      ],
    ),
  );
}

class BallGame extends StatefulWidget {
  final int pet, color;
  final Future<String> Function() onFinish;
  final VoidCallback onExit;
  const BallGame({
    super.key,
    required this.pet,
    required this.color,
    required this.onFinish,
    required this.onExit,
  });
  @override
  State<BallGame> createState() => _BallGameState();
}

class _BallGameState extends State<BallGame> {
  int catches = 0;
  bool busy = false;
  String message = '';
  final positions = [
    const Alignment(-.8, .65),
    const Alignment(.8, -.65),
    const Alignment(-.7, -.6),
    const Alignment(.8, .65),
    Alignment.center,
  ];
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        panel(
          Column(
            children: [
              const Text(
                'Лови мяч!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const Text(
                'Нажми на мяч пять раз. Он будет менять место. Не спеши — таймера нет.',
                textAlign: TextAlign.center,
              ),
              Text(
                '$catches / 5',
                style: const TextStyle(
                  fontSize: 24,
                  color: purple,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: Stack(
            children: [
              Center(
                child: EnterMotion(
                  identity: catches,
                  pop: true,
                  child: PetArt(
                    pet: widget.pet,
                    color: widget.color,
                    size: 180,
                  ),
                ),
              ),
              if (catches < 5)
                AnimatedAlign(
                  alignment: positions[catches],
                  duration: MotionSettings.enabledOf(context)
                      ? const Duration(milliseconds: 280)
                      : Duration.zero,
                  child: Semantics(
                    label: 'Поймать мяч',
                    button: true,
                    child: GestureDetector(
                      key: const ValueKey('catch-ball'),
                      behavior: HitTestBehavior.opaque,
                      onTap: busy
                          ? null
                          : () async {
                              setState(() => catches++);
                              if (catches == 5) {
                                setState(() => busy = true);
                                final result = await widget.onFinish();
                                if (mounted) {
                                  setState(() {
                                    message = result;
                                    busy = false;
                                  });
                                }
                              }
                            },
                      child: const SizedBox(
                        width: 90,
                        height: 90,
                        child: ItemArt('ball', size: 90),
                      ),
                    ),
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFF05293),
                    size: 110,
                  ),
                ),
            ],
          ),
        ),
        if (message.isNotEmpty)
          panel(Text(message, textAlign: TextAlign.center)),
        if (catches == 5 && !busy)
          GameButton(
            'Ещё поиграть',
            onPressed: () => setState(() {
              catches = 0;
              message = '';
            }),
          ),
        gameExit('На игровую площадку', widget.onExit),
      ],
    ),
  );
}
