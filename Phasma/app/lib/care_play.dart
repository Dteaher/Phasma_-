part of 'main.dart';

class CarePlay extends StatefulWidget {
  final Game game;
  final Future<String> Function(String) onAction;
  final VoidCallback onShop;
  final VoidCallback onStory;
  const CarePlay({
    super.key,
    required this.game,
    required this.onAction,
    required this.onShop,
    required this.onStory,
  });

  @override
  State<CarePlay> createState() => _CarePlayState();
}

class _CarePlayState extends State<CarePlay> {
  final targetKey = GlobalKey();
  Offset? lastBrushPoint;
  double brushed = 0;
  int reaction = 0;
  bool working = false;
  String message = 'Перетащи миску к другу или проведи расчёской по шёрстке.';

  void brushMove(DragTargetDetails<String> details) {
    if (details.data != 'groom') return;
    final box = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final point = box.globalToLocal(details.offset);
    final size = box.size;
    if (point.dx < size.width * .15 ||
        point.dx > size.width * .85 ||
        point.dy < size.height * .12 ||
        point.dy > size.height * .9) {
      lastBrushPoint = null;
      return;
    }
    final before = lastBrushPoint;
    lastBrushPoint = point;
    if (before == null) return;
    final distance = (point - before).distance;
    if (distance <= 0 || distance > 160) return;
    setState(() {
      final previous = (brushed / 45).floor();
      brushed = (brushed + distance).clamp(0, 180);
      if ((brushed / 45).floor() > previous) reaction++;
    });
  }

  Future<void> complete(String action) async {
    if (working) return;
    if (action == 'groom' && brushed < 180) {
      setState(() => message = 'Ещё немного: поводишь расчёской по спинке?');
      return;
    }
    setState(() {
      working = true;
      reaction++;
      brushed = 0;
      lastBrushPoint = null;
    });
    final result = await widget.onAction(action);
    if (mounted) {
      setState(() {
        message = result;
        working = false;
      });
    }
  }

  Widget tool(String id, String name, bool available) => Expanded(
    child: Draggable<String>(
      data: id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: available && !working ? 1 : 0,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Color(0x995130AF), blurRadius: 12),
            ],
          ),
          child: ItemArt(id == 'groom' ? 'care' : 'food', size: 72),
        ),
      ),
      childWhenDragging: const SizedBox(height: 104),
      child: Container(
        height: 104,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: available ? const Color(0xFFFFF8D9) : const Color(0xFFE8E5EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: available ? sunshine : Colors.white,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ItemArt(id == 'groom' ? 'care' : 'food', size: 48),
            Text(
              name,
              style: const TextStyle(
                color: deepPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final food = game.strings('purchases').contains('food');
    final brush = game.strings('purchases').contains('care');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              panel(
                Column(
                  children: [
                    Text(
                      '${game.name} ждёт твоей заботы!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: deepPurple,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          game.isNight
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          size: 18,
                          color: purple,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'День ${game.gameDay} • ${game.clockLabel}',
                          style: const TextStyle(
                            color: purple,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DragTarget<String>(
                key: targetKey,
                onMove: brushMove,
                onLeave: (_) {
                  lastBrushPoint = null;
                },
                onAcceptWithDetails: (details) {
                  final box =
                      targetKey.currentContext!.findRenderObject() as RenderBox;
                  final point = box.globalToLocal(details.offset);
                  if (point.dx < box.size.width * .15 ||
                      point.dx > box.size.width * .85 ||
                      point.dy < box.size.height * .12 ||
                      point.dy > box.size.height * .9) {
                    setState(
                      () => message = 'Поднеси предмет ближе к питомцу.',
                    );
                    return;
                  }
                  complete(details.data);
                },
                builder: (context, candidates, rejects) => Container(
                  height: 290,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: candidates.isNotEmpty ? sunshine : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PetScene(
                          pet: game.s['pet'] as int,
                          color: game.s['color'] as int,
                          stage: game.stage,
                          animate: game.s['animations'] == true,
                          night: game.isNight,
                          reaction: reaction,
                          height: 290,
                        ),
                      ),
                      if (candidates.contains('groom'))
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 12,
                          child: LinearProgressIndicator(
                            value: brushed / 180,
                            minHeight: 9,
                            borderRadius: BorderRadius.circular(9),
                            color: sunshine,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              panel(
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: deepPurple,
                  ),
                ),
              ),
              Row(
                children: [
                  tool('feed', food ? 'Покормить' : 'Нужен корм', food),
                  tool('groom', brush ? 'Причесать' : 'Нужна расчёска', brush),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Зажми предмет и перетащи на питомца. Расчёской поводь по шёрстке.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: deepPurple,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!food || !brush) ...[
                const SizedBox(height: 14),
                GameButton(
                  'Купить корм и уход',
                  icon: Icons.shopping_bag_rounded,
                  onPressed: widget.onShop,
                ),
              ],
              if (game.fedThisWeek || game.groomedThisWeek) ...[
                const SizedBox(height: 12),
                GameButton(
                  'Продолжить историю',
                  icon: Icons.play_arrow_rounded,
                  green: true,
                  onPressed: widget.onStory,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
