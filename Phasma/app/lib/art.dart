import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'motion.dart';

const purple = Color(0xFF5130AF);
const deepPurple = Color(0xFF251454);
const sunshine = Color(0xFFFFD62E);
const vividGreen = Color(0xFF24B33F);

class Sprite extends StatefulWidget {
  final String path;
  final int columns, rows, index;
  final double size;
  final String label;
  final EdgeInsets sourceInsets;
  const Sprite({
    super.key,
    required this.path,
    required this.columns,
    required this.rows,
    required this.index,
    this.size = 100,
    this.label = '',
    this.sourceInsets = EdgeInsets.zero,
  });
  @override
  State<Sprite> createState() => _SpriteState();
}

class _SpriteState extends State<Sprite> {
  ImageStream? stream;
  ImageInfo? info;
  late final ImageStreamListener listener = ImageStreamListener((
    image,
    synchronous,
  ) {
    if (mounted) setState(() => info = image);
  });
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    resolve();
  }

  @override
  void didUpdateWidget(covariant Sprite old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) resolve();
  }

  void resolve() {
    stream?.removeListener(listener);
    stream = AssetImage(
      widget.path,
    ).resolve(createLocalImageConfiguration(context));
    stream!.addListener(listener);
  }

  @override
  void dispose() {
    stream?.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    image: true,
    child: SizedBox(
      width: widget.size,
      height: widget.size,
      child: info == null
          ? const SizedBox()
          : CustomPaint(
              painter: _SpritePainter(
                info!.image,
                widget.columns,
                widget.rows,
                widget.index,
                widget.sourceInsets,
              ),
            ),
    ),
  );
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int columns, rows, index;
  final EdgeInsets sourceInsets;
  _SpritePainter(
    this.image,
    this.columns,
    this.rows,
    this.index,
    this.sourceInsets,
  );
  @override
  void paint(Canvas canvas, Size size) {
    final cell = Size(image.width / columns, image.height / rows);
    final src = sourceInsets.deflateRect(
      Rect.fromLTWH(
        (index % columns) * cell.width,
        (index ~/ columns) * cell.height,
        cell.width,
        cell.height,
      ),
    );
    final fit = applyBoxFit(BoxFit.contain, src.size, size);
    canvas.drawImageRect(
      image,
      src,
      Alignment.center.inscribe(fit.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.image != image ||
      old.index != index ||
      old.sourceInsets != sourceInsets;
}

class PetArt extends StatelessWidget {
  final int pet, color;
  final double size;
  const PetArt({super.key, this.pet = 0, this.color = 0, this.size = 200});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(
      end: [
        Colors.white,
        const Color(0xFFDDEEFF),
        const Color(0xFFF6DDFE),
      ][color],
    ),
    duration: MotionSettings.enabledOf(context)
        ? const Duration(milliseconds: 300)
        : Duration.zero,
    builder: (context, tint, child) => ColorFiltered(
      colorFilter: ColorFilter.mode(tint ?? Colors.white, BlendMode.modulate),
      child: child,
    ),
    child: Sprite(
      path: 'assets/art/pets-v3.png',
      columns: 3,
      rows: 2,
      index: pet,
      size: size,
      label: ['Котёнок', 'Щенок', 'Лисёнок', 'Кролик', 'Панда', 'Совёнок'][pet],
    ),
  );
}

class ItemArt extends StatelessWidget {
  final String id;
  final double size;
  const ItemArt(this.id, {super.key, this.size = 80});
  @override
  Widget build(BuildContext context) => Sprite(
    path: 'assets/art/items-v2.png',
    columns: 4,
    rows: 3,
    // The brush above the plant extends past its atlas cell. Exclude its tip.
    sourceInsets: id == 'plant'
        ? const EdgeInsets.only(top: 12)
        : EdgeInsets.zero,
    index:
        const {
          'food': 0,
          'water': 1,
          'care': 2,
          'soap': 3,
          'ball': 4,
          'hat': 5,
          'plant': 6,
          'toy': 7,
          'rocket': 7,
          'bike': 8,
          'computer': 9,
          'art': 10,
          'backpack': 11,
        }[id] ??
        10,
    size: size,
    label: id,
  );
}

class GameBackdrop extends StatelessWidget {
  final Widget child;
  final String scene;
  final double shade;
  const GameBackdrop({
    super.key,
    required this.child,
    this.scene = 'room',
    this.shade = .18,
  });
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/art/${scene == 'city' ? 'city' : 'room'}-v2.png',
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      ),
      AnimatedContainer(
        duration: MotionSettings.enabledOf(context)
            ? const Duration(milliseconds: 600)
            : Duration.zero,
        color: deepPurple.withValues(alpha: shade),
      ),
      child,
    ],
  );
}

class HeaderPill extends StatelessWidget {
  final String text;
  const HeaderPill(this.text, {super.key});
  @override
  Widget build(BuildContext context) => EnterMotion(
    pop: true,
    identity: text,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8855E4), Color(0xFF39218F)],
        ),
        border: Border.all(color: const Color(0xFFCDB6FF), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88411C73),
            offset: Offset(0, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    ),
  );
}

class GameButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool green;
  final IconData? icon;
  const GameButton(
    this.text, {
    super.key,
    required this.onPressed,
    this.green = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => PressMotion(
    enabled: onPressed != null,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: green ? const Color(0xFF0B7C29) : const Color(0xFFB77309),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: onPressed == null
                  ? const [Color(0xFFE2DEED), Color(0xFFB9B1CA)]
                  : green
                  ? const [Color(0xFF49CA99), Color(0xFF168B69)]
                  : const [Color(0xFFFFE681), Color(0xFFFFC547)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: .85),
              width: 2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: green ? Colors.white : deepPurple),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: onPressed == null
                            ? deepPurple
                            : green
                            ? Colors.white
                            : deepPurple,
                        shadows: onPressed == null
                            ? null
                            : green
                            ? const [
                                Shadow(
                                  color: Color(0x88216B2A),
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class Coin extends StatelessWidget {
  final double size;
  const Coin({super.key, this.size = 25});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF58A), Color(0xFFFFB516)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: const Color(0xFFE49C12), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55472C05),
          offset: Offset(0, 2),
          blurRadius: 2,
        ),
      ],
    ),
    child: Icon(Icons.pets, size: size * .62, color: const Color(0xFFD78A00)),
  );
}
