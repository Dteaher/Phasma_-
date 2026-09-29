import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tailtown/game.dart';
import 'package:tailtown/main.dart';
import 'package:tailtown/store.dart';

void main() {
  testWidgets('Render real phone screens and inspect navigation', (
    tester,
  ) async {
    late Directory dir;
    late Box box;
    await tester.runAsync(() async {
      final font = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      dir = await Directory.systemTemp.createTemp('tailtown-shots');
      Hive.init(dir.path);
      box = await Hive.openBox('screenshots');
    });
    final c = Catalog(
      jsonDecode(File('assets/data/content.json').readAsStringSync()) as Json,
    );
    final store = Store(box, c);
    final key = GlobalKey();
    const storeShots = bool.fromEnvironment('RUSTORE_SHOTS');
    tester.view.physicalSize = storeShots
        ? const Size(450, 800)
        : const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWith((ref) => store)],
        child: RepaintBoundary(key: key, child: const TailtownApp()),
      ),
    );
    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        for (final art in [
          'room-v2',
          'city-v2',
          'pets-v3',
          'items-v2',
          'friends-street-v15',
        ]) {
          await precacheImage(
            AssetImage('assets/art/$art.png'),
            key.currentContext!,
          );
        }
      });
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = storeShots ? 'rustore-renders' : 'screenshots-v2';
        final file = File('output/$folder/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await shot('00-welcome');
    await tester.ensureVisible(find.text('Начать приключение'));
    await tester.tap(find.text('Начать приключение'));
    await tester.pump();
    await shot('01-choose-pet');
    for (var pet = 1; pet < 5; pet++) {
      final target = find.byKey(ValueKey('choose-pet-$pet'));
      await tester.scrollUntilVisible(
        target,
        110,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 300));
      await shot('01-pet-$pet');
    }
    await tester.drag(find.byType(ListView), const Offset(600, 0));
    await tester.pumpAndSettle();
    final kitten = find.byKey(const ValueKey('choose-pet-0'));
    await tester.tap(kitten);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Подружиться'));
    await tester.tap(find.text('Подружиться'));
    await tester.pump();
    await shot('01b-name');
    final onboardingScroll = find
        .descendant(
          of: find.byType(Onboarding),
          matching: find.byType(Scrollable),
        )
        .first;
    final scrollState = tester.state<ScrollableState>(onboardingScroll);
    expect(
      scrollState.position.pixels,
      0,
      reason: 'Naming starts at the top after scrolling the pet grid',
    );
    expect(
      tester.getTopLeft(onboardingScroll).dy,
      0,
      reason: 'Pet scrolls to the screen edge without a hidden toolbar crop',
    );
    final nameBefore = tester.getTopLeft(find.text('Имя твоего друга')).dy;
    await tester.drag(onboardingScroll, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getTopLeft(find.text('Имя твоего друга')).dy,
      lessThan(nameBefore),
    );
    await shot('01c-name-scrolled');
    await tester.runAsync(() async {
      await store.act((g) {
        g.start('Персик', 0, 0, 'bike', c);
        g.s['animations'] = false;
        return '';
      });
    });
    await shot('02-home');
    await tester.ensureVisible(find.text('Позаботиться о друге'));
    await tester.tap(find.text('Позаботиться о друге'));
    await tester.pump();
    await shot('02a-care');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.ensureVisible(find.text('Продолжить историю'));
    await tester.tap(find.text('Продолжить историю'));
    await tester.pump();
    await shot('02c-journey');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.tap(find.text('План'));
    await tester.pump();
    await tester.ensureVisible(find.text('Игры'));
    await tester.tap(find.text('Игры'));
    await tester.pump();
    await shot('02f-playground');
    for (final game in [
      ('Курьер', '02g-delivery'),
      ('Детектив чеков', '02h-receipt'),
      ('Мяч с питомцем', '02i-ball'),
    ]) {
      await tester.ensureVisible(find.text('Играть: ${game.$1}'));
      await tester.tap(find.text('Играть: ${game.$1}'));
      await tester.pump();
      await shot(game.$2);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pump();
      await tester.ensureVisible(find.text('Игры'));
      await tester.tap(find.text('Игры'));
      await tester.pump();
    }

    await tester.ensureVisible(find.text('Играть: Список покупок'));
    await tester.tap(find.text('Играть: Список покупок'));
    await tester.pump();
    await shot('02d-memory-list');
    await tester.tap(find.text('Я запомнил! В лавку'));
    await tester.pump();
    await shot('02e-memory-shop');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();

    await tester.ensureVisible(find.text('Как играть'));
    await tester.tap(find.text('Как играть'));
    await tester.pump();
    await shot('02b-guide');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.ensureVisible(find.text('Копилка'));
    await tester.tap(find.text('Копилка'));
    await tester.pump();
    await shot('03-dream');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.ensureVisible(find.text('Магазин'));
    await tester.tap(find.text('Магазин'));
    await tester.pump();
    await shot('04-shop');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.ensureVisible(find.text('Знания'));
    await tester.tap(find.text('Знания'));
    await tester.pump();
    await shot('05-knowledge');
    await tester.tap(find.text('Город'));
    await tester.pump();
    await shot('05b-city');
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -750),
    );
    await tester.pump();
    await shot('05b-friends-street');
    await tester.tap(find.text('План'));
    await tester.pump();
    await tester.ensureVisible(find.text('План монеток'));
    await tester.tap(find.text('План монеток'));
    await tester.pump();
    await shot('05c-budget');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.runAsync(() => store.act((g) => g.setPlan(50, 30, 40)));
    await tester.pump();
    await tester.ensureVisible(find.text('Задания'));
    await tester.tap(find.text('Задания'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Разложи покупки'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await shot('05h-sort-game');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.ensureVisible(find.text('Приключения'));
    await tester.tap(find.text('Приключения'));
    await tester.pump();
    await shot('05d-adventures');
    await tester.tap(find.text('Лавки'));
    await tester.pump();
    await shot('05f-market');
    await tester.tap(find.text('Выбор'));
    await tester.pump();
    await shot('05g-choice');
    await tester.tap(find.text('Прогулка'));
    await tester.pump();
    await shot('05e-trail');
    await tester.runAsync(() async {
      await tester.tap(find.text(store.game.trail[1]));
      while (store.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    await shot('05h-owl-dialog');
    await tester.tap(find.text('Понятно'));
    await tester.pump();
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.runAsync(() async {
      await store.act((g) {
        for (var week = 1; week <= 8; week++) {
          g.setPlan(50, 30, 40);
          final task = g.availableTasks(c).first;
          g.answer(task['id'] as String, switch (task['type']) {
            'allocation' => [task['minNeed'], 0, task['minSave']],
            'basket' => task['required'],
            'sort' =>
              (task['choices'] as List)
                  .cast<Json>()
                  .map((e) => e['correct'])
                  .toList(),
            'change' => [10, 5, 1],
            _ => task['correct'],
          }, c);
          g.buy('food', c);
          g.buy('water', c);
          g.buy('care', c);
          g.deposit(week == 8 ? 20 : 40, c);
          if (g.hasEvent) g.event(false);
          g.end(c);
          if (week < 8) g.next();
        }
        g.fulfill(c);
        return '';
      });
    });
    await tester.tap(find.text('Дом').last);
    await tester.pump();
    await shot('06-finale');
    await tester.ensureVisible(find.text('В дом друзей'));
    await tester.tap(find.text('В дом друзей'));
    await tester.pump();
    await shot('06b-friends-house');
    expect(find.text('Выбрать нового друга'), findsOneWidget);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();

    await tester.runAsync(
      () => store.act((g) {
        g.newStory();
        g.start('Новый друг', 1, 0, 'bike', c);
        g.setPlan(50, 30, 40);
        g.answer('sort', [0, 1, 0, 1], c);
        g.end(c);
        g.next();
        g.setPlan(50, 30, 40);
        return '';
      }),
    );
    await tester.pump();
    await tester.tap(find.text('План'));
    await tester.pump();
    await tester.ensureVisible(find.text('Задания'));
    await tester.tap(find.text('Задания'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Собери сдачу'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await shot('07-change-game');
    await tester.runAsync(
      () => store.act((g) {
        g.buy('food', c);
        g.buy('care', c);
        return '';
      }),
    );
    await tester.tap(find.text('Дом').last);
    await tester.pump();
    await tester.ensureVisible(find.text('Позаботиться о друге'));
    await tester.tap(find.text('Позаботиться о друге'));
    await tester.pump();
    await shot('08-care-ready');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    await tester.runAsync(
      () => store.act((g) {
        g.s['gameHour'] = 23;
        return '';
      }),
    );
    await shot('09-home-night');
    await tester.tap(find.text('Город'));
    await tester.pump();
    await shot('10-city-night');
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -750),
    );
    await tester.pump();
    await shot('11-friends-night');
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await box.close();
      await dir.delete(recursive: true);
    });
  });
}
