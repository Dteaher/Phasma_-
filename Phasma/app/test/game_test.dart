import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailtown/game.dart';

void main() {
  final c = Catalog(
    jsonDecode(File('assets/data/content.json').readAsStringSync()) as Json,
  );
  Game ready() => Game.empty()
    ..start('Персик', 0, 0, 'bike', c)
    ..setPlan(50, 30, 40);
  test(
    'Care requires supplies, survives saving and never duplicates spending',
    () {
      final g = ready();
      final initialHour = g.gameHour;
      g.careForPet('feed');
      expect(g.fedThisWeek, isFalse);
      expect(g.gameHour, initialHour);
      g.buy('food', c);
      g.buy('care', c);
      final balance = g.balance;
      g.careForPet('feed');
      g.careForPet('groom');
      expect(g.fedThisWeek && g.groomedThisWeek, isTrue);
      final saved = g.copy();
      final hour = saved.gameHour;
      saved.careForPet('feed');
      saved.careForPet('groom');
      expect(saved.balance, balance);
      expect(saved.gameHour, hour);
      saved.s['gameHour'] = 23;
      final day = saved.gameDay;
      saved.deposit(10, c);
      expect(saved.gameHour, 1);
      expect(saved.gameDay, day + 1);
      expect(saved.isNight, isTrue);
      final beforeRest = saved.balance;
      saved.restUntilMorning();
      expect(saved.clockLabel, '09:00');
      expect(saved.isNight, isFalse);
      expect(saved.balance, beforeRest);
    },
  );
  void practice(Game g) {
    final t = g.availableTasks(c).first;
    final dynamic answer = switch (t['type']) {
      'allocation' => [t['minNeed'], 0, t['minSave']],
      'basket' => t['required'],
      'sort' =>
        (t['choices'] as List).cast<Json>().map((e) => e['correct']).toList(),
      'change' => [10, 5, 1],
      _ => t['correct'],
    };
    g.answer(t['id'] as String, answer, c);
  }

  test(
    'Task gating explains the actual missing step without changing progress',
    () {
      final g = Game.empty()..start('Друг', 0, 0, 'bike', c);
      expect(
        g.answer('sort', [0, 1, 0, 1], c),
        contains('Сначала выбери план'),
      );
      expect(g.balance, 120);
      expect(g.strings('done'), isEmpty);
      g.setPlan(50, 30, 40);
      expect(g.answer('change', [10, 5, 1], c), contains('другом приключении'));
      practice(g);
      g.end(c);
      final balance = g.balance;
      expect(g.answer('sort', [0, 1, 0, 1], c), contains('ждать не нужно'));
      expect(g.balance, balance);
    },
  );

  test('Catalog meets contest minimum and uses supported task types', () {
    expect(c.items.length, greaterThanOrEqualTo(8));
    expect(c.tasks.length, greaterThanOrEqualTo(6));
    expect(c.goals.length, greaterThanOrEqualTo(3));
    expect(c.tasks.map((t) => t['topic']).toSet().length, 3);
    for (final t in c.tasks) {
      expect([
        'choice',
        'basket',
        'allocation',
        'change',
        'sort',
      ], contains(t['type']));
    }
  });
  test('Planning reserves nothing and cannot exceed wallet', () {
    final g = Game.empty()..start('Друг', 1, 1, 'bike', c);
    g.setPlan(100, 50, 40);
    expect(g.planned, false);
    expect(g.balance, 120);
    g.setPlan(50, 30, 40);
    expect(g.balance, 120);
    expect(g.savings, 0);
    g.setPlan(0, 0, 120);
    expect((g.s['plan'] as Json)['need'], 50);
  });
  test(
    'Purchases and savings conserve money; no overdraft or duplicate purchase',
    () {
      final g = ready();
      g.buy('food', c);
      expect(g.balance, 90);
      g.buy('food', c);
      expect(g.balance, 90);
      g.deposit(40, c);
      expect(g.balance, 50);
      expect(g.savings, 40);
      g.buy('toy', c);
      expect(g.balance, 50);
      expect(g.strings('inventory'), isEmpty);
      g.withdraw(10);
      expect(g.balance, 60);
      expect(g.savings, 30);
      g.withdraw(31);
      g.deposit(-1, c);
      g.deposit(100, c);
      expect(g.balance + g.savings, 90);
    },
  );
  test('Wrong allocation is recoverable; rewards cannot be repeated', () {
    final g = ready();
    g.answer('budget', [0, 100, 0], c);
    expect(g.balance, 120);
    expect(g.strings('done'), isEmpty);
    g.answer('budget', [40, 40, 20], c);
    expect(g.balance, 130);
    g.answer('budget', [40, 40, 20], c);
    expect(g.balance, 130);
    expect((g.s['attempts'] as Json)['1:budget'], 2);
  });
  test(
    'Full eight-period route grows pet and fulfills dream; album survives next story',
    () {
      final g = ready();
      for (var n = 1; n <= 8; n++) {
        expect(g.period, n);
        practice(g);
        g.buy('food', c);
        g.buy('water', c);
        g.buy('care', c);
        if (n == 1) g.buy('ball', c);
        if (g.hasEvent) g.event(false);
        g.deposit(n == 8 ? 20 : 40, c);
        g.end(c);
        if (n < 8) {
          g.next();
          g.setPlan(50, 30, 40);
        }
      }
      expect(g.stage, 3);
      expect(g.savings, 300);
      expect(g.records('summaries').length, 8);
      final loaded = Game(jsonDecode(jsonEncode(g.s)) as Json);
      expect(loaded.s, g.s);
      g.fulfill(c);
      expect(g.finished, true);
      expect(g.savings, 0);
      expect(g.records('album').length, 1);
      g.fulfill(c);
      expect(g.records('album').length, 1);
      g.newStory();
      expect(g.started, false);
      expect(g.records('album').length, 1);
      expect(g.balance, 0);
      expect(g.strings('inventory'), isEmpty);
      expect(g.strings('lessons'), isNotEmpty);
    },
  );
  test('Periods continue after five without automatically finishing', () {
    final g = ready();
    for (var n = 1; n <= 8; n++) {
      practice(g);
      if (g.hasEvent) g.event(false);
      g.end(c);
      g.next();
      g.setPlan(50, 30, 40);
    }
    expect(g.period, 9);
    expect(g.finished, false);
  });
  test('Events, period income and summaries are idempotent', () {
    final g = ready();
    for (var n = 1; n < 4; n++) {
      practice(g);
      g.end(c);
      g.next();
      g.setPlan(50, 30, 40);
    }
    final b = g.balance;
    g.event(true);
    g.event(true);
    expect(g.balance, b - 20);
    practice(g);
    g.end(c);
    g.end(c);
    expect(g.records('summaries').length, 4);
    final after = g.balance;
    g.next();
    g.next();
    expect(g.balance, after + 120);
  });
  test(
    'Emergency support is bounded and all transfers reject invalid amounts',
    () {
      final g = ready();
      g.deposit(120, c);
      g.rescue();
      g.rescue();
      expect(g.balance, 30);
      g.deposit(1000, c);
      g.withdraw(-50);
      expect(g.balance, 30);
      expect(g.savings, 120);
    },
  );
  test('Completed story cannot receive income, tasks or purchases', () {
    final g = ready();
    g.deposit(120, c);
    practice(g);
    g.end(c);
    g.next();
    g.setPlan(0, 0, 80);
    g.deposit(80, c);
    practice(g);
    g.end(c);
    g.next();
    g.setPlan(0, 0, 100);
    g.deposit(100, c);
    g.fulfill(c);
    final b = g.balance;
    g.buy('food', c);
    g.deposit(10, c);
    g.next();
    g.answer('basket', ['food', 'water'], c);
    expect(g.balance, b);
    expect(g.savings, 0);
  });
}
