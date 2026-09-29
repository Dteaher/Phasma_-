import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailtown/game.dart';
import 'package:tailtown/main.dart';

void main() {
  final c = Catalog(
    jsonDecode(File('assets/data/content.json').readAsStringSync()) as Json,
  );
  Game ready() => Game.empty()
    ..start('Друг', 0, 0, 'bike', c)
    ..setPlan(50, 30, 40);
  const oddPath = [0, 1, 2, 3, 7, 11, 10, 9, 8, 12];
  const evenPath = [0, 1, 2, 6, 10, 14, 15, 14, 13, 12, 8];

  test(
    'Delivery validates real path, limits steps and pays once across reload',
    () {
      final g = ready();
      for (final path in <List<int>>[
        [],
        [0, 3, 11, 12],
        [0, 1, 4, 3, 11, 12],
        [0, 16],
        [0, 1],
        [...oddPath, 8, 9, 10, 11],
      ]) {
        g.finishDelivery(path);
        expect(g.balance, 120);
        expect(g.used('delivery'), false);
      }
      g.finishDelivery(oddPath);
      expect(g.balance, 130);
      expect(g.strings('done'), contains('1:delivery'));
      final restored = Game(jsonDecode(jsonEncode(g.s)) as Json);
      restored.finishDelivery(oddPath);
      expect(restored.balance, 130);
      restored.s['period'] = 2;
      restored.finishDelivery(evenPath);
      expect(restored.balance, 140);
      expect(restored.strings('badges'), contains('Бережливый курьер'));
    },
  );
  test(
    'Receipt rotates errors, rejects wrong answer, and never charges money',
    () {
      final g = ready();
      for (var period = 1; period <= 3; period++) {
        g.s['period'] = period;
        final before = g.balance;
        g.checkReceipt((g.receiptError + 1) % 3, g.receiptTotal);
        g.checkReceipt(g.receiptError, g.receiptTotal + 5);
        expect(g.balance, before);
        g.checkReceipt(g.receiptError, g.receiptTotal);
        expect(g.balance, before + 10);
        g.checkReceipt(g.receiptError, g.receiptTotal);
        expect(g.balance, before + 10);
      }
      g.s['phase'] = 'summary';
      g.s['period'] = 4;
      final before = g.balance;
      g.finishDelivery(evenPath);
      g.checkReceipt(g.receiptError, g.receiptTotal);
      expect(g.balance, before);
    },
  );
  test(
    'Friendship is free, one heart per adventure, and badges survive new story',
    () {
      final g = ready();
      g.playWithPet(4);
      expect(g.s['friendship'], isNull);
      for (var period = 1; period <= 3; period++) {
        g.s['period'] = period;
        g.playWithPet(5);
        g.playWithPet(5);
        expect(g.s['friendship'], period);
      }
      expect(g.balance, 120);
      expect(g.strings('badges'), contains('Неразлучные друзья'));
      g.s['completed'] = true;
      g.newStory();
      expect(g.strings('badges'), contains('Неразлучные друзья'));
      expect(g.s['friendship'], isNull);
    },
  );
  testWidgets('Courier can undo and finish using adjacent cells', (
    tester,
  ) async {
    final g = ready();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeliveryGame(
            stops: g.deliveryStops,
            onFinish: (path) async => g.finishDelivery(path),
            onExit: () {},
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('route-15')));
    await tester.tap(find.byKey(const ValueKey('route-15')));
    await tester.pump();
    expect(find.text('Шагов: 12 · Доставлено: 0/3'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('route-1')));
    await tester.tap(find.byKey(const ValueKey('route-1')));
    await tester.pump();
    await tester.ensureVisible(find.text('Отменить шаг'));
    await tester.tap(find.text('Отменить шаг'));
    await tester.pump();
    for (final cell in oddPath.skip(1)) {
      final target = find.byKey(ValueKey('route-$cell'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
    }
    expect(g.balance, 130);
    expect(find.textContaining('Все посылки доставлены!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Receipt and pet play complete through actual input', (
    tester,
  ) async {
    final g = ready();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptGame(
            prices: g.receiptPrices,
            quantities: g.receiptQuantities,
            error: g.receiptError,
            onCheck: (row, total) async => g.checkReceipt(row, total),
            onExit: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(ValueKey('receipt-row-${g.receiptError}')));
    await tester.pump();
    await tester.ensureVisible(find.text('${g.receiptTotal}'));
    await tester.tap(find.text('${g.receiptTotal}'));
    await tester.pump();
    await tester.ensureVisible(find.text('Проверить чек'));
    await tester.tap(find.text('Проверить чек'));
    await tester.pump();
    expect(g.balance, 130);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BallGame(
            pet: 0,
            color: 0,
            onFinish: () async => g.playWithPet(5),
            onExit: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      final ball = find.byKey(const ValueKey('catch-ball'));
      await tester.ensureVisible(ball);
      await tester.tap(ball);
      await tester.pump(const Duration(milliseconds: 350));
    }
    expect(g.s['friendship'], 1);
    expect(g.balance, 130);
    expect(tester.takeException(), isNull);
  });
}
