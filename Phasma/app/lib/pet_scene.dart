import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'art.dart';
import 'motion.dart';

const ink = Color(0xFF28214D);
const green = Color(0xFF149B44);
const cream = Color(0xFFF4F1FF);
const gold = Color(0xFFFFCD25);
const petNames = ['Котёнок', 'Щенок', 'Лисёнок', 'Кролик', 'Панда'];
const petNicknames = ['Персик', 'Бублик', 'Искра', 'Клевер', 'Плюша'];
const petTraits = [
  'Любопытный искатель',
  'Верный путешественник',
  'Находчивый исследователь',
  'Заботливый садовник',
  'Мечтательный художник',
];
const petGreetings = [
  'Обожаю находить новое! Давай исследуем город вместе?',
  'В дороге веселее с другом. Возьмёшь меня в команду?',
  'У меня всегда есть идея! Вместе найдём путь к мечте.',
  'Большие мечты растут из маленьких шагов. Как мой сад!',
  'Давай раскрасим этот день! Я уже придумал целую историю.',
];
const petAccents = [
  Color(0xFFFFD080),
  Color(0xFF98D2FF),
  Color(0xFFFFB9A2),
  Color(0xFFAEE6CE),
  Color(0xFFD8BEF7),
];

class PetScene extends StatefulWidget {
  final int pet, color, stage;
  final bool hat, plant, ball, bike, animate, thoughtful, background;
  final double height;
  final String? dream;
  final int reaction;
  final bool night;
  const PetScene({
    super.key,
    this.pet = 0,
    this.color = 0,
    this.stage = 1,
    this.hat = false,
    this.plant = false,
    this.ball = false,
    this.bike = false,
    this.animate = true,
    this.thoughtful = false,
    this.background = true,
    this.height = 260,
    this.dream,
    this.reaction = 0,
    this.night = false,
  });
  @override
  State<PetScene> createState() => _PetSceneState();
}

class _PetSceneState extends State<PetScene> with TickerProviderStateMixin {
  bool motionEnabled = true;
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final AnimationController celebration = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  @override
  void initState() {
    super.initState();
    if (widget.animate) animation.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    motionEnabled = MotionSettings.enabledOf(context);
    if (!motionEnabled || !widget.animate) {
      animation.stop();
      animation.value = 0;
      celebration.stop();
      celebration.value = 0;
    } else if (!animation.isAnimating) {
      animation.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PetScene old) {
    super.didUpdateWidget(old);
    if (motionEnabled && widget.animate && widget.reaction != old.reaction) {
      celebration.forward(from: 0);
    }
    if (motionEnabled && widget.animate && !animation.isAnimating) {
      animation.repeat(reverse: true);
    }
    if (!motionEnabled || !widget.animate) {
      animation.stop();
      celebration.stop();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(25),
    child: SizedBox(
      height: widget.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, box) {
          final petSize = math.min(box.maxWidth * .78, box.maxHeight * .88);
          final petAlignment = widget.bike || widget.dream != null
              ? const Alignment(-.65, .5)
              : const Alignment(-.15, .55);
          return Stack(
            children: [
              if (widget.background)
                Positioned.fill(
                  child: Image.asset(
                    'assets/art/room-v2.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, .4),
                    color: widget.night ? const Color(0xFF9192C4) : null,
                    colorBlendMode: BlendMode.modulate,
                    excludeFromSemantics: true,
                  ),
                ),
              Align(
                alignment: Alignment(petAlignment.x, 1),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Container(
                    width: petSize * .68,
                    height: petSize * .14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xAA2A1646),
                          Color(0x552A1646),
                          Color(0x002A1646),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.plant)
                const Positioned(
                  right: 6,
                  bottom: 24,
                  child: ItemArt('plant', size: 66),
                ),
              if (widget.ball)
                const Positioned(
                  left: 4,
                  bottom: 9,
                  child: ItemArt('ball', size: 48),
                ),
              Align(
                alignment: petAlignment,
                child: AnimatedBuilder(
                  animation: Listenable.merge([animation, celebration]),
                  builder: (context, child) {
                    final breathe = widget.animate
                        ? math.sin(animation.value * math.pi * 2)
                        : 0.0;
                    final hop = math.sin(celebration.value * math.pi) * 18;
                    return SizedBox(
                      width: petSize,
                      height: petSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Transform.translate(
                            offset: Offset(0, -hop + breathe * 2),
                            child: Transform.rotate(
                              angle: breathe * .012,
                              child: Transform.scale(
                                scale:
                                    1 +
                                    breathe * .012 +
                                    math.sin(celebration.value * math.pi) *
                                        .045,
                                child: child,
                              ),
                            ),
                          ),
                          if (celebration.value > 0 && celebration.value < 1)
                            for (var i = 0; i < 3; i++)
                              Positioned(
                                left: petSize * (.18 + i * .24),
                                top:
                                    petSize *
                                    (.18 -
                                        celebration.value * .25 +
                                        (i.isOdd ? .07 : 0)),
                                child: Opacity(
                                  opacity: 1 - celebration.value,
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    size: petSize * (i == 1 ? .19 : .13),
                                    color: const Color(0xFFEE599C),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    );
                  },
                  child: SizedBox(
                    width: petSize,
                    height: petSize,
                    child: Stack(
                      children: [
                        Semantics(
                          label: 'Погладить питомца',
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (motionEnabled && widget.animate) {
                                celebration.forward(from: 0);
                              }
                            },
                            child: PetArt(
                              pet: widget.pet,
                              color: widget.color,
                              size: petSize,
                            ),
                          ),
                        ),
                        if (widget.hat)
                          Positioned(
                            top: petSize * .03,
                            left: petSize * .30,
                            child: Transform.rotate(
                              angle: -.18,
                              child: ItemArt('hat', size: petSize * .43),
                            ),
                          ),
                        if (widget.stage >= 2)
                          Positioned(
                            right: petSize * .12,
                            bottom: petSize * .13,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: widget.stage == 3 ? gold : purple,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                widget.stage == 3
                                    ? Icons.workspace_premium
                                    : Icons.star,
                                color: widget.stage == 3
                                    ? deepPurple
                                    : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.bike || widget.dream != null)
                Positioned(
                  right: 0,
                  bottom: 6,
                  child: ItemArt(widget.dream ?? 'bike', size: 135),
                ),
            ],
          );
        },
      ),
    ),
  );
}
