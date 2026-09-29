part of 'main.dart';

class Allocation extends StatefulWidget {
  final int total;
  final String label;
  final bool suggested;
  final Future<void> Function(List<int>) onSubmit;
  const Allocation({
    super.key,
    required this.total,
    required this.onSubmit,
    this.label = 'Проверить мой план',
    this.suggested = false,
  });
  @override
  State<Allocation> createState() => _AllocationState();
}

class _AllocationState extends State<Allocation> {
  late final values = widget.suggested && widget.total >= 120
      ? [50, 30, 40]
      : [0, 0, 0];
  final colors = const [
    Color(0xFF7773ED),
    Color(0xFFEF7CA1),
    Color(0xFF3AC76C),
  ];
  final names = const ['Нужно', 'Хочу', 'Коплю'];
  Future<void> editAmount(int index) async {
    final controller = TextEditingController(text: '${values[index]}');
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(names[index]),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'От 0 до ${widget.total} монеток',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Назад'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
    if (n != null && mounted) {
      setState(() => values[index] = n.clamp(0, widget.total));
    }
  }

  Widget jar(int i, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(top: 7, bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, colors[i].withValues(alpha: .16)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33402B78),
            offset: Offset(0, 3),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 4),
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors[i],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              names[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            height: 110,
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, colors[i].withValues(alpha: .50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: colors[i].withValues(alpha: .70),
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 7,
                  top: 12,
                  bottom: 12,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                i == 2
                    ? const Icon(
                        Icons.savings_rounded,
                        size: 49,
                        color: Color(0xFFF58BB0),
                      )
                    : ItemArt(i == 0 ? 'food' : 'ball', size: width * .65),
              ],
            ),
          ),
          InkWell(
            onTap: () => editAmount(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                '${values[i]}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 48,
                child: IconButton(
                  onPressed: values[i] > 0
                      ? () => setState(
                          () => values[i] = (values[i] - 10).clamp(
                            0,
                            widget.total,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.remove_circle),
                  color: const Color(0xFF159CE1),
                  tooltip: 'Уменьшить ${names[i]}',
                ),
              ),
              SizedBox(
                width: 46,
                height: 48,
                child: IconButton(
                  onPressed: values[i] < widget.total
                      ? () => setState(
                          () => values[i] = (values[i] + 10).clamp(
                            0,
                            widget.total,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.add_circle),
                  color: vividGreen,
                  tooltip: 'Увеличить ${names[i]}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sum = values.reduce((a, b) => a + b);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final horizontal =
                box.maxWidth >= 298 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.3;
            return horizontal
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        jar(i, (box.maxWidth - 10) / 3),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              jar(i, 110),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Slider(
                                  value: values[i].toDouble(),
                                  max: widget.total > 0
                                      ? widget.total.toDouble()
                                      : 1,
                                  label: '${values[i]}',
                                  divisions: widget.total > 0
                                      ? widget.total
                                      : null,
                                  onChanged: widget.total > 0
                                      ? (v) => setState(
                                          () => values[i] = v.round(),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            sum <= widget.total
                ? 'Осталось распределить: ${widget.total - sum}'
                : 'Не хватает ${sum - widget.total} монеток',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: sum <= widget.total
                  ? const Color(0xFF25833A)
                  : Colors.deepOrange.shade800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: GameButton(
            widget.label,
            green: true,
            onPressed: sum <= widget.total
                ? () => widget.onSubmit(List<int>.from(values))
                : null,
          ),
        ),
      ],
    );
  }
}
