import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailtown/game.dart';

void main() {
  final c = Catalog(
    jsonDecode(File('assets/data/content.json').readAsStringSync()) as Json,
  );
  Game ready() => Game.empty()
    ..start('Пуфик', 0, 0, 'bike', c)
    ..setPlan(50, 30, 40);
  test(
    'Market uses actual price and prevents duplicate purchases across shops',
    () {
      final g = ready()..market(1, c);
      expect(g.balance, 96);
      expect(g.s['spentNeed'], 24);
      expect(c.item('food')['price'], 30);
      g.buy('food', c);
      g.market(0, c);
      expect(g.balance, 96);
      g.buy('water', c);
      g.buy('care', c);
      expect(g.hasNeed(c), isTrue);
    },
  );
  test('Temptation transfers money once and persists in a snapshot', () {
    final g = ready()..temptation(1, c);
    expect(g.balance, 100);
    expect(g.savings, 20);
    final saved = g.copy()..temptation(0, c);
    expect(saved.balance, 100);
    expect(saved.strings('inventory'), isEmpty);
    final buyer = ready()..temptation(0, c);
    expect(buyer.balance, 100);
    expect(buyer.s['spentWant'], 20);
    expect(buyer.strings('inventory'), contains('ball'));
  });
  test('Trail permits retry, gives one reward and renews next game week', () {
    final g = ready();
    g.answerTrail(1 - g.trailCorrect);
    expect(g.balance, 120);
    g.answerTrail(g.trailCorrect);
    expect(g.balance, 130);
    g.answerTrail(g.trailCorrect);
    expect(g.balance, 130);
    g.end(c);
    g.next();
    g.setPlan(50, 30, 40);
    expect(g.used('trail'), isFalse);
    g.answerTrail(g.trailCorrect);
    expect(g.balance, 260);
  });
  test(
    'Stars require all missions, cannot be claimed twice, survive reload',
    () {
      final g = ready()..claimMission();
      expect(g.s['missionStars'], isNull);
      g.market(1, c);
      g.buy('water', c);
      g.buy('care', c);
      g.deposit(20, c);
      g.answerTrail(g.trailCorrect);
      g.withdraw(1);
      g.claimMission();
      expect(g.s['missionStars'], isNull);
      g.deposit(1, c);
      g.claimMission();
      g.claimMission();
      expect(g.copy().s['missionStars'], 1);
      expect(g.strings('badges'), contains('Звезда заботы'));
    },
  );
  test('Insufficient funds and inactive profiles cannot mutate adventures', () {
    final g = ready();
    g.s['balance'] = 0;
    g.market(1, c);
    g.temptation(0, c);
    g.temptation(1, c);
    expect(g.used('temptation'), isFalse);
    expect(g.balance, 0);
    g.s['completed'] = true;
    g.answerTrail(g.trailCorrect);
    g.temptation(2, c);
    expect(g.used('trail'), isFalse);
    expect(g.used('temptation'), isFalse);
  });
}
