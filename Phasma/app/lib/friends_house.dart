part of 'main.dart';

extension _FriendsHouse on _GameRootState {
  Future<void> startAnotherFriend() async {
    if (!g.finished) return;
    if (!await confirm(
      'Познакомиться с новым другом?',
      '${g.name} останется в доме друзей со своей мечтой. У нового питомца будет отдельная история и свои монетки.',
      button: 'Выбрать друга',
    )) {
      return;
    }
    await act((game) {
      game.newStory();
      return 'Новая история ждёт!';
    }, show: false);
    if (mounted && !g.started) go('');
  }

  Widget friendsHouse() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            panel(
              Column(
                children: [
                  const Icon(Icons.home_rounded, color: purple, size: 44),
                  const Text(
                    'Здесь живут исполненные мечты',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Друзей с исполненной мечтой: ${g.records('album').length}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (!g.finished)
              panel(
                Column(
                  children: [
                    Text(
                      'Сейчас помогаем: ${g.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    PetScene(
                      pet: g.s['pet'] as int,
                      color: g.s['color'] as int,
                      height: 160,
                      animate: false,
                      background: false,
                    ),
                    Text(
                      '${c.goal(g.s['goal'] as String)['name']}: ${g.savings} из ${c.goal(g.s['goal'] as String)['cost']} монеток',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GameButton(
                      'Продолжить путь к мечте',
                      onPressed: () => go('journey'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Когда мечта сбудется, здесь можно выбрать нового друга.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            if (g.records('album').isEmpty)
              panel(
                const Text(
                  'Первое место ждёт твоего питомца. Его мечта и ваша история останутся здесь навсегда.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (g.finished) ...[
              GameButton(
                'Выбрать нового друга',
                icon: Icons.pets_rounded,
                onPressed: startAnotherFriend,
              ),
              const SizedBox(height: 18),
            ],
            for (final story in g.records('album').reversed)
              panel(
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            story['name'] as String,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PetScene(
                      pet: story['pet'] as int,
                      color: story['color'] as int,
                      dream: story['goal'] as String,
                      height: 245,
                      animate: false,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${c.goal(story['goal'] as String)['name']} — мечта сбылась!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: purple,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.goal(story['goal'] as String)['ending'] as String,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${story['periods']} приключений вместе',
                      style: const TextStyle(fontSize: 12, color: purple),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
