part of 'main.dart';

Widget adultEntry(BuildContext context) => IconButton(
  tooltip: 'Для взрослого',
  icon: const Icon(Icons.lock_outline_rounded),
  onPressed: () async {
    final allowed = await showDialog<bool>(
      context: context,
      builder: (_) => const AdultGate(),
    );
    if (allowed == true && context.mounted) {
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const AdultScreen()));
    }
  },
);

class AdultGate extends StatefulWidget {
  const AdultGate({super.key});
  @override
  State<AdultGate> createState() => _AdultGateState();
}

class _AdultGateState extends State<AdultGate> {
  final answer = TextEditingController();
  late final int left = 12 + DateTime.now().millisecond % 9;
  late final int right = 3 + DateTime.now().second % 7;
  bool incorrect = false;
  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  void check() {
    if (int.tryParse(answer.text.trim()) == left * right) {
      Navigator.pop(context, true);
    } else {
      setState(() => incorrect = true);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Для взрослого'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Попроси взрослого решить пример, чтобы открыть настройки.',
          ),
          const SizedBox(height: 16),
          Text('$left × $right = ?', key: const ValueKey('adult-question')),
          TextField(
            key: const ValueKey('adult-answer'),
            controller: answer,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => check(),
            decoration: InputDecoration(
              labelText: 'Ответ',
              errorText: incorrect ? 'Проверьте ответ' : null,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Назад'),
      ),
      FilledButton(onPressed: check, child: const Text('Открыть')),
    ],
  );
}

class AdultScreen extends ConsumerWidget {
  const AdultScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final game = store.game;
    final learned = game.strings('lessons');
    final titles = store.catalog.lessons
        .where((lesson) => learned.contains(lesson['id']))
        .map((lesson) => lesson['title'] ?? lesson['id'])
        .join(', ');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Для взрослого'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          titleText('Зачем нужна игра'),
          const Text(
            'Ребёнок учится планировать бюджет, различать нужды и желания, сравнивать цены и копить на цель. Все монеты игровые. Реальных платежей и рекламы нет.',
          ),
          titleText('Прогресс без оценок'),
          Text(
            game.started
                ? 'Игровая неделя: ${game.period}\nНакоплено: ${game.savings} монет\nИсполнено желаний: ${game.records('album').length}\nПройдено тем: ${learned.length}'
                : 'Новая история ещё не началась.',
          ),
          if (titles.isNotEmpty) Text('Изученные темы: $titles'),
          SwitchListTile(
            key: const ValueKey('animation-setting'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Анимации'),
            subtitle: const Text(
              'Можно отключить движение. Системное уменьшение движения также учитывается.',
            ),
            value: game.s['animations'] != false,
            onChanged: store.busy
                ? null
                : (value) async {
                    final result = await store.act((g) {
                      g.s['animations'] = value;
                      return 'Настройка сохранена';
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(result)));
                    }
                  },
          ),
          const Text('Звуков в этой версии нет.'),
          titleText('Проверка для эксперта'),
          const Text(
            'Демонстрационный профиль хранится отдельно. Игровые недели сменяются по действиям, ждать календарных дат не нужно.',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Демонстрационный профиль'),
            value: store.demo,
            onChanged: store.busy ? null : (_) async => store.toggleDemo(),
          ),
          titleText('Данные на устройстве'),
          Text(
            store.demo
                ? 'Сейчас открыт тестовый профиль. Сброс затронет только его.'
                : 'Сейчас открыт основной профиль. Сброс удалит его историю, питомцев и накопления, включая локальную резервную копию.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('reset-profile'),
            onPressed: store.busy
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Удалить прогресс?'),
                        content: Text(
                          store.demo
                              ? 'Тестовый профиль начнётся заново. Основная игра сохранится.'
                              : 'Все данные основного профиля будут удалены. Восстановить их не получится.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      try {
                        await store.reset();
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Не удалось удалить данные. Попробуйте ещё раз.',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
            child: Text(
              store.demo
                  ? 'Сбросить тестовый профиль'
                  : 'Удалить основной профиль',
            ),
          ),
        ],
      ),
    );
  }
}
