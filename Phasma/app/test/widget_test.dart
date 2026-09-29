import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tailtown/game.dart';
import 'package:tailtown/main.dart';
import 'package:tailtown/store.dart';
import 'package:tailtown/art.dart';
import 'package:tailtown/pet_scene.dart';

void main() {
  late Directory dir;
  late Box box;
  late Store store;
  final c = Catalog(
    jsonDecode(File('assets/data/content.json').readAsStringSync()) as Json,
  );
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tailtown-test');
    Hive.init(dir.path);
    box = await Hive.openBox('profile');
    store = Store(box, c);
  });
  tearDown(() async {
    await box.close();
    await dir.delete(recursive: true);
  });
  testWidgets('Every activity opens and returns with animation enabled', (
    tester,
  ) async {
    await tester.runAsync(
      () => store.act((game) {
        game.start('Тестик', 0, 0, 'bike', c);
        return game.setPlan(50, 30, 40);
      }),
    );
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWith((ref) => store)],
        child: const TailtownApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('План'));
    await tester.pump(const Duration(milliseconds: 400));
    for (final route in [
      ('План монеток', 'Планирование бюджета'),
      ('Копилка', 'Копилка и цели'),
      ('Магазин', 'Магазин'),
      ('Игры', 'Игровая площадка'),
      ('Знания', 'Блокнот совёнка'),
      ('Задания', 'Практика с совёнком'),
      ('Приключения', 'Приключения недели'),
      ('Как играть', 'Как играть'),
      ('Комната', 'Комната питомца'),
    ]) {
      await tester.ensureVisible(find.text(route.$1));
      await tester.tap(find.text(route.$1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(route.$2), findsWidgets, reason: route.$1);
      expect(tester.takeException(), isNull, reason: route.$1);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Мой план и занятия'), findsOneWidget);
    }
    await tester.tap(find.text('Город'));
    await tester.pump(const Duration(milliseconds: 400));
    final locked = find.text('Откроется после\n1-й мечты');
    await tester.ensureVisible(locked);
    await tester.tap(locked);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.textContaining('Домик откроется после первой мечты'),
      findsOneWidget,
    );
    expect(store.game.records('album'), isEmpty);
    await tester.runAsync(
      () => store.act((game) {
        game.s['savings'] = c.goal('bike')['cost'];
        return game.fulfill(c);
      }),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Выбрать питомца'), findsOneWidget);
    await tester.ensureVisible(find.text('Мечта сбылась!'));
    await tester.tap(find.text('Мечта сбылась!'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widgetList<PetScene>(find.byType(PetScene))
          .any((scene) => scene.dream == 'bike'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Onboarding at 360dp creates persistent profile and opens home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWith((ref) => store)],
        child: const TailtownApp(),
      ),
    );
    await tester.ensureVisible(find.text('Начать приключение'));
    await tester.tap(find.text('Начать приключение'));
    await tester.pump();
    expect(find.text('Котёнок'), findsOneWidget);
    await tester.ensureVisible(find.text('Подружиться'));
    await tester.tap(find.text('Подружиться'));
    await tester.pump();
    await tester.ensureVisible(find.text('Начать нашу историю'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Начать нашу историю'));
      while (store.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    expect(store.game.started, true);
    expect(store.game.balance, 120);
    expect(box.get('player'), isNotNull);
    expect(find.text('Персик'), findsWidgets);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Для взрослого'), findsOneWidget);
    await tester.ensureVisible(find.text('Продолжить историю'));
    await tester.tap(find.text('Продолжить историю'));
    await tester.pump();
    await tester.ensureVisible(find.text('40 на мечту · 30 на желания'));
    await tester.runAsync(() async {
      await tester.tap(find.text('40 на мечту · 30 на желания'));
      while (store.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    expect(store.game.planned, isTrue);
    expect(store.game.balance, 120);
    expect(find.text('Разложи покупки'), findsOneWidget);
    expect(find.byType(GameDialog), findsNothing);
    Future<void> action(Finder target) async {
      await tester.ensureVisible(target);
      await tester.runAsync(() async {
        await tester.tap(target);
        await Future<void>.delayed(const Duration(milliseconds: 25));
        while (store.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();
    }

    for (var i = 0; i < 4; i++) {
      await action(
        find
            .widgetWithText(ChoiceChip, i == 0 || i == 2 ? 'Нужно' : 'Хочу')
            .at(i),
      );
    }
    await action(find.text('Проверить выбор'));
    expect(store.game.balance, 130);
    await action(find.text('Лавка у парка · 24 монетки'));
    expect(store.game.strings('purchases'), contains('food'));
    await action(find.text('Покормить самому'));
    await tester.ensureVisible(find.text('Покормить'));
    await tester.runAsync(() async {
      await tester.dragFrom(
        tester.getCenter(find.text('Покормить')),
        tester.getCenter(find.byType(PetScene).last) -
            tester.getCenter(find.text('Покормить')),
      );
      while (store.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    expect(store.game.fedThisWeek, isTrue);
    await action(find.text('Продолжить историю'));
    await action(find.text('Дать воду · 10 монеток'));
    await action(find.text('Купить уход · 10 монеток'));
    await action(find.text('Причесать самому'));
    await tester.ensureVisible(find.text('Причесать'));
    final brushStart = tester.getCenter(find.text('Причесать'));
    final petCenter = tester.getCenter(find.byType(PetScene).last);
    await tester.runAsync(() async {
      final brushGesture = await tester.startGesture(brushStart);
      await brushGesture.moveTo(petCenter + const Offset(-45, 0));
      await tester.pump();
      for (var x = -43; x <= 45; x += 2) {
        await brushGesture.moveTo(petCenter + Offset(x.toDouble(), 0));
        await tester.pump();
      }
      for (var x = 43; x >= -45; x -= 2) {
        await brushGesture.moveTo(petCenter + Offset(x.toDouble(), 0));
        await tester.pump();
      }
      await brushGesture.up();
      while (store.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    expect(store.game.groomedThisWeek, isTrue);
    await action(find.text('Продолжить историю'));
    expect(store.game.hasNeed(c), isTrue);
    await action(find.text('Отложить 40 монеток'));
    expect(store.game.savings, 40);
    expect(store.game.balance, 46);
    await action(find.text('Завершить приключение'));
    expect(store.game.s['phase'], 'summary');
    expect(store.game.s['missionStars'], 1);
    await action(find.text('Вперёд! Новое приключение'));
    expect(store.game.period, 2);
    expect(store.game.balance, 166);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Shopping memory supports retry, hints, all rounds and replay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MemoryGame(onHome: () {})),
      ),
    );
    Future<void> tap(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }

    for (var round = 0; round < 3; round++) {
      final targets = tester
          .widgetList<ItemArt>(find.byType(ItemArt))
          .map((art) => art.id)
          .toList();
      expect(targets.length, round + 2);
      await tap('Я запомнил! В лавку');
      await tap('Проверить корзину');
      expect(find.textContaining('Есть лишнее'), findsOneWidget);
      await tap('Подсмотреть список');
      expect(
        tester
            .widgetList<ItemArt>(find.byType(ItemArt))
            .map((art) => art.id)
            .toList(),
        targets,
      );
      await tap('Я запомнил! В лавку');
      for (final id in targets) {
        final card = find.byKey(ValueKey('memory-$id'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pump();
      }
      await tap('Проверить корзину');
      expect(find.text('Все покупки по списку!'), findsOneWidget);
      await tap(round == 2 ? 'Сыграть ещё' : 'Следующий раунд');
    }
    expect(find.text('Раунд 1 из 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Map house keeps every dream and starts a new friend only after confirmation',
    (tester) async {
      await tester.runAsync(
        () => store.act((game) {
          for (final goal in ['bike', 'computer', 'art']) {
            game.start('Друг $goal', 0, 0, goal, c);
            game.s['savings'] = c.goal(goal)['cost'];
            game.fulfill(c);
            if (goal != 'art') game.newStory();
          }
          game.s['animations'] = false;
          return '';
        }),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storeProvider.overrideWith((ref) => store)],
          child: const TailtownApp(),
        ),
      );
      await tester.tap(find.text('Город'));
      await tester.pump();
      await tester.ensureVisible(find.text('Дом друзей'));
      await tester.tap(find.text('Дом друзей'));
      await tester.pump();
      expect(
        tester
            .widgetList<PetScene>(find.byType(PetScene))
            .map((scene) => scene.dream)
            .toSet(),
        {'bike', 'computer', 'art'},
      );
      await tester.ensureVisible(find.text('Выбрать нового друга'));
      await tester.runAsync(
        () => tester.tap(find.text('Выбрать нового друга')),
      );
      await tester.pumpAndSettle();
      expect(store.game.finished, isTrue);
      await tester.runAsync(() async {
        await tester.tap(find.text('Выбрать друга'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        while (store.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();
      await tester.runAsync(() async {
        for (var i = 0; i < 50 && store.game.started; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        store.game.started,
        isFalse,
        reason:
            'busy=${store.busy}, phase=${store.game.s["phase"]}, finished=${store.game.finished}',
      );
      expect(store.game.records('album').length, 3);
      expect(find.text('Подружиться'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('Save restores and demo reset never deletes player data', () async {
    await store.act((g) => g.start('Друг', 2, 1, 'bike', c));
    await store.act((g) => g.setPlan(50, 30, 40));
    await store.act((g) => g.deposit(20, c));
    final reloaded = Store(box, c);
    expect(reloaded.game.savings, 20);
    await reloaded.toggleDemo();
    expect(reloaded.game.started, false);
    await reloaded.act((g) => g.start('Демо', 0, 0, 'bike', c));
    await reloaded.reset();
    await reloaded.toggleDemo();
    expect(reloaded.game.name, 'Друг');
    expect(reloaded.game.savings, 20);
    reloaded.dispose();
  });
  testWidgets('Home, shop and knowledge work with enlarged text', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await store.act((g) => g.start('Персик', 0, 0, 'bike', c));
      await store.act((g) => g.setPlan(50, 30, 40));
    });
    store.game.s['animations'] = false;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWith((ref) => store)],
        child: const TailtownApp(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Продолжить историю'));
    await tester.tap(find.text('Продолжить историю'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Разложи покупки'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.tap(find.text('План'));
    await tester.pump();
    await tester.ensureVisible(find.text('Приключения'));
    await tester.tap(find.text('Приключения'));
    await tester.pump();
    for (final label in ['Лавки', 'Выбор', 'Прогулка', 'Цели']) {
      await tester.tap(find.text(label));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.ensureVisible(find.text('Знания'));
    await tester.tap(find.text('Знания'));
    await tester.pump();
    expect(find.text('Блокнот совёнка'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

