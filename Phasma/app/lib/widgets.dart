part of 'main.dart';

class TaskCard extends StatefulWidget {
  final Json task;
  final bool done;
  final Future<void> Function(dynamic) onAnswer;
  const TaskCard({
    super.key,
    required this.task,
    required this.done,
    required this.onAnswer,
  });
  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final selected = <String>{};
  final coins = <int>[];
  final sorted = <int>[];
  Widget changeGame(Json task) {
    final target = (task['paid'] as int) - (task['price'] as int);
    final total = coins.fold<int>(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Заплатил ${task['paid']} • цена ${task['price']}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        panel(
          Column(
            children: [
              const Text(
                'Собранная сдача',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 38,
                  color: total > target ? Colors.deepOrange : purple,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                coins.isEmpty
                    ? 'Нажми на монетку ниже'
                    : 'Нажми на монетку здесь, чтобы убрать',
              ),
              if (coins.isNotEmpty)
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (var i = 0; i < coins.length; i++)
                      ActionChip(
                        label: Text('${coins[i]} ×'),
                        onPressed: () => setState(() => coins.removeAt(i)),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const Text(
          'Добавить монетку:',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in (task['coins'] as List).cast<int>())
              InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: coins.length < 30
                    ? () => setState(() => coins.add(value))
                    : null,
                child: Semantics(
                  button: true,
                  label: 'Добавить $value монеток',
                  child: Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF59A), Color(0xFFFFB928)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFE49C12),
                        width: 3,
                      ),
                    ),
                    child: Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: deepPurple,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        GameButton(
          'Проверить сдачу',
          green: true,
          onPressed: coins.isNotEmpty
              ? () => widget.onAnswer(List<int>.from(coins))
              : null,
        ),
      ],
    );
  }

  Widget sortGame(Json task) {
    final choices = (task['choices'] as List).cast<Json>();
    if (sorted.length != choices.length) {
      sorted
        ..clear()
        ..addAll(List<int>.filled(choices.length, -1));
    }
    return Column(
      children: [
        for (var i = 0; i < choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFE0D6FA), width: 2),
              ),
              child: Row(
                children: [
                  ItemArt(choices[i]['id'] as String, size: 62),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choices[i]['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (var value = 0; value < 2; value++)
                              ChoiceChip(
                                label: Text(value == 0 ? 'Нужно' : 'Хочу'),
                                selected: sorted[i] == value,
                                showCheckmark: false,
                                selectedColor: value == 0
                                    ? const Color(0xFF8CE4A3)
                                    : const Color(0xFFF7A9C5),
                                onSelected: (_) =>
                                    setState(() => sorted[i] = value),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        GameButton(
          'Проверить выбор',
          green: true,
          onPressed: sorted.every((v) => v >= 0)
              ? () => widget.onAnswer(List<int>.from(sorted))
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task['topic'] as String,
            style: const TextStyle(fontSize: 12, color: green),
          ),
          Text(
            task['title'] as String,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (widget.done)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle, color: green),
              title: Text('Практика завершена'),
              subtitle: Text('Награда уже в твоём бюджете.'),
            )
          else ...[
            Text(task['prompt'] as String),
            const SizedBox(height: 16),
            if (task['type'] == 'allocation')
              Allocation(
                total: task['budget'] as int,
                onSubmit: widget.onAnswer,
              )
            else if (task['type'] == 'change')
              changeGame(task)
            else if (task['type'] == 'sort')
              sortGame(task)
            else if (task['type'] == 'basket') ...[
              LayoutBuilder(
                builder: (context, box) {
                  final choices = (task['choices'] as List).cast<Json>();
                  final width = (box.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in choices)
                        SizedBox(
                          width: width,
                          child: InkWell(
                            onTap: () => setState(() {
                              final id = option['id'] as String;
                              if (!selected.add(id)) selected.remove(id);
                            }),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selected.contains(option['id'])
                                    ? const Color(0xFFE3F6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected.contains(option['id'])
                                      ? purple
                                      : const Color(0xFFE0D6FA),
                                  width: 3,
                                ),
                              ),
                              child: Column(
                                children: [
                                  option['id'] == 'ribbon'
                                      ? const Icon(
                                          Icons.celebration_rounded,
                                          size: 62,
                                          color: Color(0xFFEF7CA1),
                                        )
                                      : ItemArt(
                                          option['id'] as String,
                                          size: 62,
                                        ),
                                  Text(
                                    option['name'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${option['price']} монеток',
                                    style: const TextStyle(
                                      color: purple,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Icon(
                                    selected.contains(option['id'])
                                        ? Icons.check_circle
                                        : Icons.add_circle_outline,
                                    color: selected.contains(option['id'])
                                        ? vividGreen
                                        : purple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'В корзине: ${(task['choices'] as List).cast<Json>().where((e) => selected.contains(e['id'])).fold<int>(0, (a, e) => a + (e['price'] as int))} из ${task['budget']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              GameButton(
                'Проверить корзину',
                green: true,
                onPressed: selected.isNotEmpty
                    ? () => widget.onAnswer(selected.toList())
                    : null,
              ),
            ] else ...[
              for (var i = 0; i < (task['options'] as List).length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => widget.onAnswer(i),
                      child: Text((task['options'] as List)[i] as String),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
