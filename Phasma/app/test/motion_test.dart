import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailtown/art.dart';
import 'package:tailtown/motion.dart';

void main() {
  testWidgets('Animated button accepts one tap during its entrance', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: EnterMotion(
              child: GameButton('Играть', onPressed: () => taps++),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Играть')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .96);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Reduced motion displays content immediately and preserves input',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: RewardMotion(
                trigger: 1,
                playOnMount: true,
                child: Center(
                  child: EnterMotion(
                    pop: true,
                    child: GameButton('Продолжить', onPressed: () => taps++),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(EnterMotion),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1);
      await tester.tap(find.text('Продолжить'));
      await tester.pump();
      expect(taps, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
