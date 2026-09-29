import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'game.dart';

final storeProvider = ChangeNotifierProvider<Store>(
  (ref) => throw UnimplementedError(),
);

class Store extends ChangeNotifier {
  final Box box;
  final Catalog catalog;
  Game game = Game.empty();
  bool demo = false;
  bool busy = false;
  String? recovery;
  Store(this.box, this.catalog) {
    demo = box.get('activeDemo', defaultValue: false) == true;
    _load();
  }
  String get key => demo ? 'demo' : 'player';
  void _load() {
    try {
      final raw = box.get(key);
      game = raw == null ? Game.empty() : _decode(raw as String);
    } catch (_) {
      try {
        game = _decode(box.get('$key.backup') as String);
        recovery = 'Восстановлена резервная копия прогресса.';
      } catch (_) {
        game = Game.empty();
        recovery =
            'Сохранение не удалось прочитать. Можно начать новую историю.';
      }
    }
  }

  Game _decode(String raw) {
    final data = jsonDecode(raw) as Json;
    if (data['version'] != 1) {
      throw const FormatException('Unsupported save version');
    }
    final g = Game({...Game.empty().s, ...data});
    if (g.balance < 0 || g.savings < 0 || g.period < 1) {
      throw const FormatException('Invalid economy');
    }
    return g;
  }

  Future<String> act(String Function(Game g) action) async {
    if (busy) return 'Сохраняем предыдущее действие…';
    busy = true;
    notifyListeners();
    try {
      final next = game.copy();
      final message = action(next);
      final old = box.get(key);
      if (old != null) await box.put('$key.backup', old);
      await box.put(key, jsonEncode(next.s));
      await box.flush();
      game = next;
      return message;
    } catch (_) {
      return 'Не удалось сохранить действие. Попробуй ещё раз.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> toggleDemo() async {
    if (busy) return;
    demo = !demo;
    await box.put('activeDemo', demo);
    _load();
    notifyListeners();
  }

  Future<void> reset() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await box.deleteAll([key, '$key.backup']);
      await box.flush();
      game = Game.empty();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
