import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailtown/game.dart';

void main() {
  final catalog = Catalog(
    jsonDecode(File('assets/data/content.json').readAsStringSync()) as Json,
  );
  Game started() => Game.empty()
    ..start('Пуфик', 0, 0, 'bike', catalog)
    ..setPlan(50, 30, 40);

  test('Sorting teaches needs and wants; retry is free and reward is once', () {
    final game = started();
    expect(game.availableTasks(catalog).any((t) => t['id'] == 'sort'), isTrue);
    final before = game.balance;
    game.answer('sort', [1, 0, 0, 1], catalog);
    expect(game.balance, before);
    expect(game.strings('done'), isNot(contains('1:sort')));
    game.answer('sort', [0, 1, 0, 1], catalog);
    expect(game.balance, before + 10);
    expect(game.strings('badges'), contains('Разумный выбор'));
    game.answer('sort', [0, 1, 0, 1], catalog);
    expect(game.balance, before + 10);
  });

  test(
    'Change game checks exact sum with valid coins and grants one reward',
    () {
      final game = started();
      expect(
        game.availableTasks(catalog).any((t) => t['id'] == 'change'),
        isFalse,
      );
      game.answer('sort', [0, 1, 0, 1], catalog);
      game.end(catalog);
      game.next();
      game.setPlan(50, 30, 40);
      final before = game.balance;
      game.answer('change', [10, 5], catalog);
      game.answer('change', [16], catalog);
      expect(game.balance, before);
      game.answer('change', [10, 5, 1], catalog);
      expect(game.balance, before + 10);
      expect(game.strings('badges'), contains('Мастер сдачи'));
      game.answer('change', [10, 5, 1], catalog);
      expect(game.balance, before + 10);
    },
  );
}
