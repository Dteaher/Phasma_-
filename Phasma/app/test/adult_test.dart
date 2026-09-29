import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tailtown/game.dart';
import 'package:tailtown/main.dart';
import 'package:tailtown/store.dart';

void main() {
  testWidgets(
    'Adult gate rejects incorrect answer and accepts correct answer',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AdultGate())),
      );
      await tester.enterText(find.byKey(const ValueKey('adult-answer')), '0');
      await tester.tap(find.text('Открыть'));
      await tester.pump();
      expect(find.text('Проверьте ответ'), findsOneWidget);
      final question = tester
          .widget<Text>(find.byKey(const ValueKey('adult-question')))
          .data!;
      final numbers = RegExp(
        r'\d+',
      ).allMatches(question).map((m) => int.parse(m[0]!)).toList();
      await tester.enterText(
        find.byKey(const ValueKey('adult-answer')),
        '${numbers[0] * numbers[1]}',
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      expect(find.text('Проверьте ответ'), findsNothing);
    },
  );

  testWidgets('Adult settings persist and reset requires confirmation', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('adult-test');
    Hive.init(directory.path);
    late Box box;
    await tester.runAsync(() async {
      box = await Hive.openBox('adult');
    });
    final catalog = Catalog(
      jsonDecode(File('assets/data/content.json').readAsStringSync()) as Json,
    );
    final store = Store(box, catalog);
    await tester.runAsync(
      () => store.act((g) => g.start('Пуфик', 0, 0, 'bike', catalog)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWith((ref) => store)],
        child: const MaterialApp(home: AdultScreen()),
      ),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('animation-setting')));
    await tester.runAsync(() async {
      await tester.tap(find.byType(Switch).first);
      while (store.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(Store(box, catalog).game.s['animations'], false);
    ScaffoldMessenger.of(
      tester.element(find.byType(AdultScreen)),
    ).clearSnackBars();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('reset-profile')));
    await tester.pumpAndSettle();
    expect(store.busy, false);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('reset-profile')))
          .onPressed,
      isNotNull,
    );
    await tester.runAsync(
      () => tester.tap(find.byKey(const ValueKey('reset-profile'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(store.game.started, true);
    expect(store.busy, false);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('reset-profile')))
          .onPressed,
      isNotNull,
    );
    await tester.runAsync(
      () => tester.tap(find.byKey(const ValueKey('reset-profile'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(store.game.started, false);
    expect(box.get('player'), isNull);
    expect(box.get('player.backup'), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => box.close());
    directory.deleteSync(recursive: true);
  });

  test('Demo reset leaves main profile intact', () async {
    final dir = await Directory.systemTemp.createTemp('demo-isolation');
    Hive.init(dir.path);
    final box = await Hive.openBox('isolation');
    final catalog = Catalog(
      jsonDecode(File('assets/data/content.json').readAsStringSync()) as Json,
    );
    final store = Store(box, catalog);
    await store.act((g) => g.start('Друг', 0, 0, 'bike', catalog));
    await store.toggleDemo();
    await store.act((g) => g.start('Тест', 1, 0, 'bike', catalog));
    await store.reset();
    expect(store.game.started, false);
    await store.toggleDemo();
    expect(store.game.name, 'Друг');
    await box.close();
    await dir.delete(recursive: true);
  });
}
