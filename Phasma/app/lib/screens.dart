part of 'main.dart';

extension _GameScreens on _GameRootState {
  Widget budget() => list([
    owl(
      'План — это идея, как использовать монетки. Сейчас ничего не спишется.',
    ),
    if (!g.planned) ...[
      titleText('Распределим ${g.balance} монеток'),
      const Text(
        'Мы предложили пример: 50 на заботу, 30 на желания, 40 на мечту. Поменяй числа, если хочешь. После плана отдельно выполни задание, купи нужное и пополни копилку.',
      ),
      const SizedBox(height: 16),
      Allocation(
        key: ValueKey('plan${g.period}'),
        total: g.balance,
        suggested: true,
        onSubmit: (v) async {
          await act((g) => g.setPlan(v[0], v[1], v[2]));
          if (mounted && g.planned) go('tasks');
        },
        label: 'Подтвердить мой план',
      ),
    ] else ...[
      titleText('План и факт'),
      planTable(
        g.s['plan'] as Json,
        g.s['spentNeed'] as int,
        g.s['spentWant'] as int,
        (g.s['saved'] as int) - (g.s['withdrawn'] as int),
      ),
      const Text(
        'Подтверждённый план сохраняется для сравнения. Если обстоятельства изменились, ты можешь принять другое решение.',
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => go('shop'),
        child: const Text('Перейти к покупкам'),
      ),
    ],
  ]);
  Widget planTable(Json plan, int need, int want, int save) => panel(
    Column(
      children: [
        const Row(
          children: [
            Expanded(child: Text('Категория')),
            SizedBox(width: 65, child: Text('План')),
            SizedBox(width: 65, child: Text('Факт')),
          ],
        ),
        const Divider(),
        for (final row in [
          ('Нужно', plan['need'], need),
          ('Хочу', plan['want'], want),
          ('Коплю', plan['save'], save),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(row.$1)),
                SizedBox(width: 65, child: Text('${row.$2}')),
                SizedBox(
                  width: 65,
                  child: Text(
                    '${row.$3}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  Widget shop() => shopV2();
  Widget guide() => list([
    owl(
      'Поможем питомцу накопить на мечту. Вот весь путь одной игровой недели.',
    ),
    for (final step in [
      (
        '1. Составь план',
        'Реши, сколько оставить на заботу, желания и мечту. План не списывает монетки.',
        Icons.pie_chart_rounded,
      ),
      (
        '2. Потренируйся',
        'Пройди задание совёнка. За него дают 10 игровых монеток один раз за неделю.',
        Icons.school_rounded,
      ),
      (
        '3. Позаботься',
        'Купи корм, воду и уход. Покупки списываются из кошелька.',
        Icons.pets_rounded,
      ),
      (
        '4. Пополни копилку',
        'Переведи монетки из кошелька в копилку. Только так растут накопления на мечту.',
        Icons.savings_rounded,
      ),
    ])
      panel(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(step.$3, size: 35, color: purple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.$1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(step.$2),
                ],
              ),
            ),
          ],
        ),
      ),
    panel(
      const Text(
        'В конце недели посмотри, что получилось. Питомец получит новые монетки, и путь повторится. Когда в копилке хватит на мечту, её можно исполнить. Все монетки здесь игровые.',
      ),
    ),
    GameButton('Вернуться к питомцу', onPressed: () => go('')),
  ]);
  Future<void> transfer(bool withdraw) async {
    final controller = TextEditingController(text: '10');
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(withdraw ? 'Взять из копилки' : 'Отложить на мечту'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Монеток (доступно ${withdraw ? g.savings : g.balance})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Назад'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text) ?? 0),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    if (amount == null || !mounted) return;
    if (withdraw) {
      if (amount <= 0 || amount > g.savings) {
        await act((g) => g.withdraw(amount));
        return;
      }
      if (await confirm(
        'Взять $amount монеток?',
        'В копилке останется ${g.savings - amount}. До мечты будет не хватать ${(c.goal(g.s['goal'] as String)['cost'] as int) - g.savings + amount} монеток.',
        button: 'Взять из копилки',
      )) {
        await act((g) => g.withdraw(amount));
      }
    } else {
      await act((g) => g.deposit(amount, c));
    }
  }

  Widget savings() {
    final goal = c.goal(g.s['goal'] as String), cost = goal['cost'] as int;
    return list([
      Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.all(35),
          decoration: const BoxDecoration(
            color: Color(0xFFE6EDDF),
            shape: BoxShape.circle,
          ),
          child: ItemArt(goal['id'] as String, size: 160),
        ),
      ),
      titleText('${g.name} мечтает: ${goal['name']}'),
      Text(goal['story'] as String),
      const SizedBox(height: 20),
      panel(
        Column(
          children: [
            Text(
              '${g.savings} / $cost',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: green,
              ),
            ),
            const SizedBox(height: 10),
            DreamProgress(
              value: (g.savings / cost).clamp(0, 1),
              minHeight: 14,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text('Осталось ${cost - g.savings} монеток'),
          ],
        ),
      ),
      if (g.savings >= cost && !g.finished)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              if (await confirm(
                'Исполнить мечту?',
                'Из копилки будет потрачено $cost монеток. У питомца появится ${goal['name']}.',
                button: 'Исполнить мечту',
              )) {
                await act((g) => g.fulfill(c), show: false);
                go('');
                updateView(() => tab = 0);
              }
            },
            icon: const Icon(Icons.celebration),
            label: const Text('Мечта сбывается!'),
          ),
        )
      else if (!g.finished) ...[
        money(g.balance, label: 'доступно'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in [10, 20, 30])
              FilledButton(
                onPressed: () => act((g) => g.deposit(n, c)),
                child: Text('+$n'),
              ),
            OutlinedButton(
              onPressed: () => transfer(false),
              child: const Text('Другая сумма'),
            ),
          ],
        ),
        TextButton(
          onPressed: () => transfer(true),
          child: const Text('Взять монетки из копилки'),
        ),
      ],
      const SizedBox(height: 16),
      owl(
        'Не обязательно откладывать много сразу. Выбери сумму, с которой тебе удобно продолжать неделю.',
      ),
    ]);
  }

  Widget tasks() {
    if (g.finished) return ending();
    if (g.s['phase'] == 'summary') {
      return list([
        owl('Приключение завершено. Следующее можно начать прямо сейчас!'),
        GameButton('Начать новое приключение', onPressed: () => go('journey')),
      ]);
    }
    if (!g.planned) {
      return list([
        owl(
          'Перед игрой выберем, сколько монеток оставить на заботу, желания и мечту.',
        ),
        GameButton('Выбрать план и играть', onPressed: () => go('journey')),
      ]);
    }
    return list([
      owl(
        g.strings('done').any((id) => id.startsWith('${g.period}:'))
            ? 'Задание выполнено! Теперь примени знания: купи корм, воду и уход.'
            : 'Это тренировка. Выбирай ответ, пробуй снова без штрафа. За выполненное задание получишь 10 игровых монеток.',
      ),
      if (g.strings('done').any((id) => id.startsWith('${g.period}:')))
        GameButton('К заботе о питомце', onPressed: () => go('shop')),
      if (g.hasEvent && g.s['eventDone'] != true) ...[
        titleText('Ой, рюкзак порвался!'),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ремонт стоит 20 монеток. Можно отремонтировать сейчас или пока взять запасной у совёнка.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (await confirm(
                    'Отремонтировать рюкзак?',
                    'Потратим 20 монеток на необходимое.',
                  )) {
                    await act((g) => g.event(true));
                  }
                },
                child: const Text('Ремонт за 20'),
              ),
              TextButton(
                onPressed: () => act((g) => g.event(false)),
                child: const Text('Пока взять запасной'),
              ),
            ],
          ),
        ),
      ],
      for (final task in g.availableTasks(c))
        TaskCard(
          key: ValueKey('${g.period}:${task['id']}'),
          task: task,
          done: g.strings('done').contains('${g.period}:${task['id']}'),
          onAnswer: (answer) =>
              act((g) => g.answer(task['id'] as String, answer, c)),
        ),
      if (!g.planned)
        FilledButton(
          onPressed: () => go('budget'),
          child: const Text('Сначала составить план'),
        ),
      const SizedBox(height: 12),
      GameButton(
        'Приключения и цели недели',
        onPressed: () => go('adventures'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => go('shop'),
        child: const Text('Применить знания в магазине'),
      ),
    ]);
  }

  Widget history() => list([
    if (g.s['phase'] == 'summary') ...[
      titleText('Неделя ${g.period} позади'),
      owl(g.records('summaries').last['reason'] as String),
      planTable(
        g.s['plan'] as Json,
        g.s['spentNeed'] as int,
        g.s['spentWant'] as int,
        (g.s['saved'] as int) - (g.s['withdrawn'] as int),
      ),
      FilledButton(
        onPressed: () async {
          await act((g) => g.next(), show: false);
          go('');
        },
        child: Text('Начать неделю ${g.period + 1}'),
      ),
    ],
    titleText('История монеток'),
    if (g.records('history').isEmpty)
      const Text('Здесь появятся решения и их последствия.'),
    for (final entry in g.records('history').reversed)
      panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Неделя ${entry['period']} • ${entry['kind'] == 'deposit'
                  ? 'в копилку'
                  : entry['kind'] == 'withdraw'
                  ? 'из копилки'
                  : 'операция'}',
              style: const TextStyle(fontSize: 12, color: green),
            ),
            Text(entry['text'] as String),
            if (entry['amount'] != 0)
              Text(
                '${(entry['amount'] as int) > 0 ? '+' : ''}${entry['amount']}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
          ],
        ),
      ),
  ]);
  Widget city() => cityV2();
  Widget book() => list([
    titleText('Блокнот совёнка'),
    const Text(
      'Короткие подсказки о монетках и мечтах. Возвращайся, когда захочется разобраться.',
    ),
    const SizedBox(height: 16),
    for (final lesson in c.lessons)
      panel(
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            lesson['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          leading: Icon(
            g.strings('lessons').contains(lesson['id'])
                ? Icons.bookmark
                : Icons.bookmark_outline,
            color: green,
          ),
          children: [
            Text(lesson['text'] as String),
            const SizedBox(height: 12),
            owl(lesson['example'] as String),
          ],
        ),
      ),
  ]);
  Widget album() => list([
    GameButton(
      'В дом друзей',
      icon: Icons.home_rounded,
      onPressed: () => go('friends'),
    ),
    titleText('Альбом исполненных мечт'),
    if (g.records('album').isEmpty)
      owl(
        'Первое место в альбоме ждёт вашего велосипеда. История сохранится здесь, когда мечта исполнится.',
      ),
    for (final story in g.records('album'))
      panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PetScene(
              pet: story['pet'] as int,
              color: story['color'] as int,
              dream: story['goal'] as String,
              animate: false,
              height: 140,
            ),
            const SizedBox(height: 12),
            Text(
              '${story['name']} • ${c.goal(story['goal'] as String)['name']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              '${story['periods']} недель вместе • ${story['deposits']} пополнений',
            ),
          ],
        ),
      ),
    titleText('Наши достижения'),
    for (final name in [
      'Первая копилка',
      'Планировщик',
      'Финансовый детектив',
      'Парк открыт',
      'Пять недель вместе',
      'Большая мечта',
      'Разумный покупатель',
      'Звезда заботы',
      'Хранитель мечты',
      'Мастер сдачи',
      'Разумный выбор',
      'Мастер списка',
      'Бережливый курьер',
      'Детектив чеков',
      'Верный друг',
      'Неразлучные друзья',
    ])
      panel(
        Row(
          children: [
            Icon(
              g.strings('badges').contains(name)
                  ? Icons.workspace_premium
                  : Icons.lock_outline,
              color: g.strings('badges').contains(name) ? green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name)),
          ],
        ),
      ),
  ]);
  Widget wardrobe() => list([
    titleText('Уют и маленькие радости'),
    scene(),
    const SizedBox(height: 18),
    owl(
      'Панама появляется после покупки или достижения «Планировщик». Цветок и мяч из лавки украсят комнату.',
    ),
    SwitchListTile(
      title: const Text('Надеть панаму'),
      value: g.s['hat'] == true,
      onChanged:
          g.strings('inventory').contains('hat') ||
              g.strings('badges').contains('Планировщик')
          ? (v) => act((g) {
              g.s['hat'] = v;
              return 'Новый образ сохранён.';
            }, show: false)
          : null,
    ),
    titleText('Внешность питомца'),
    Wrap(
      spacing: 10,
      children: [
        for (var i = 0; i < 3; i++)
          ChoiceChip(
            label: Text(['Персик', 'Облачко', 'Сирень'][i]),
            selected: g.s['color'] == i,
            onSelected: (_) => act((g) {
              g.s['color'] = i;
              return 'Цвет сохранён.';
            }, show: false),
          ),
      ],
    ),
    const SizedBox(height: 18),
    FilledButton(
      onPressed: () => go('shop'),
      child: const Text('Выбрать что-нибудь в лавке'),
    ),
  ]);
  Widget ending() {
    final goal = c.goal(g.s['goal'] as String);
    final last = g.records('album').last;
    return list([
      const SizedBox(height: 15),
      const Center(
        child: Icon(Icons.auto_awesome, color: Color(0xFFBA7A17), size: 40),
      ),
      titleText('Ура! Мечта сбылась'),
      scene(bike: goal['id'] == 'bike', height: 240),
      const SizedBox(height: 20),
      Text(
        goal['ending'] as String,
        style: const TextStyle(fontSize: 19, height: 1.5),
      ),
      const SizedBox(height: 20),
      owl(
        'Вы составили ${last['plans']} планов и пополнили копилку ${last['deposits']} раз. Каждый шаг помог приблизить мечту.',
      ),
      GameButton(
        'В дом друзей',
        icon: Icons.home_rounded,
        onPressed: () => go('friends'),
      ),
      TextButton(
        onPressed: () => updateView(() => tab = 3),
        child: const Text('Посмотреть альбом'),
      ),
    ]);
  }
}
