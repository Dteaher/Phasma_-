part of 'game.dart';

extension Adventures on Game {
  List<int> get deliveryStops => period.isOdd ? [3, 11, 12] : [2, 8, 15];
  int get receiptError => (period - 1) % 3;
  List<int> get receiptPrices => [12 + period % 3, 8, 15];
  List<int> get receiptQuantities => [2, 1, 1];
  int get receiptTotal => List.generate(
    3,
    (i) => receiptPrices[i] * receiptQuantities[i],
  ).fold(0, (a, b) => a + b);

  String finishDelivery(List<int> path) {
    if (!canExplore) {
      return 'Это тренировка. Для награды сначала выбери план приключения.';
    }
    if (used('delivery')) {
      return 'Награда за маршрут уже получена. Можно тренироваться сколько хочешь!';
    }
    if (path.isEmpty ||
        path.first != 0 ||
        path.length > 13 ||
        path.any((cell) => cell < 0 || cell > 15)) {
      return 'Начни от почты и используй не больше 12 шагов.';
    }
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1], b = path[i];
      if ((a ~/ 4 - b ~/ 4).abs() + (a % 4 - b % 4).abs() != 1) {
        return 'Можно переходить только в соседнюю клетку.';
      }
    }
    if (!deliveryStops.every(path.contains)) {
      return 'Доставь посылки во все три дома.';
    }
    mark('delivery');
    (s['done'] as List).add('$period:delivery');
    lesson('budget');
    badge('Бережливый курьер');
    credit(10, 'За доставку по спланированному маршруту');
    return 'Все посылки доставлены! +10 монеток. План маршрута помог уложиться в запас шагов.';
  }

  String checkReceipt(int row, int total) {
    if (!canExplore) {
      return 'Это тренировка. Для награды сначала выбери план приключения.';
    }
    if (used('receipt')) {
      return 'Этот чек уже проверен. Награда получена, повторять можно бесплатно.';
    }
    if (row != receiptError || total != receiptTotal) {
      return 'Проверь количество × цену в каждой строке, затем сложи правильные суммы. Монетки не теряются.';
    }
    mark('receipt');
    (s['done'] as List).add('$period:receipt');
    lesson('change');
    badge('Детектив чеков');
    credit(10, 'За проверку чека');
    return 'Ошибка найдена! +10 монеток. Проверка чека помогает не переплатить.';
  }

  String playWithPet(int catches) {
    if (!started || finished) {
      return 'Начни историю с питомцем, чтобы собирать сердечки дружбы.';
    }
    if (catches != 5) return 'Поймай мяч пять раз — без таймера и спешки.';
    if (used('ball-play')) {
      return 'Мне понравилось! Сердечко за это приключение уже получено.';
    }
    mark('ball-play');
    s['friendship'] = (s['friendship'] as int? ?? 0) + 1;
    badge('Верный друг');
    if ((s['friendship'] as int) >= 3) badge('Неразлучные друзья');
    log(
      'Игра с питомцем: +1 сердечко дружбы. Всего ${s['friendship']}.',
      0,
      'event',
    );
    return 'Ура! +1 сердечко дружбы. Веселиться вместе можно и без покупок!';
  }

  bool used(String id) =>
      (s['adventures'] as List? ?? []).contains('$period:$id');
  void mark(String id) => (s['adventures'] ??= <String>[]).add('$period:$id');
  bool get canExplore => active && planned;

  List<bool> get missionProgress => [
    ['food', 'water', 'care'].every(strings('purchases').contains),
    (s['saved'] as int) - (s['withdrawn'] as int) >= 20,
    strings('done').any((id) => id.startsWith('$period:')),
  ];
  String claimMission() {
    if (!canExplore || used('mission') || !missionProgress.every((v) => v)) {
      return 'Выполни три цели недели. Награда выдаётся один раз.';
    }
    mark('mission');
    final stars = (s['missionStars'] as int? ?? 0) + 1;
    s['missionStars'] = stars;
    badge('Звезда заботы');
    if (stars >= 3) badge('Хранитель мечты');
    log(
      'Получена звезда заботы! Всего звёзд в этой истории: $stars.',
      0,
      'event',
    );
    return '${s['message']} Три звезды откроют достижение «Хранитель мечты».';
  }

  String market(int offer, Catalog c) {
    if (!canExplore || offer < 0 || offer > 1) {
      return 'Сначала составь план недели.';
    }
    if (strings('purchases').contains('food')) {
      return 'Корм на эту неделю уже куплен.';
    }
    final price = offer == 0 ? 30 : 24;
    if (balance < price) {
      return 'Не хватает ${price - balance} монеток. Покупку можно отложить.';
    }
    // Reuse the purchase rules with a local price; the shared catalog stays intact.
    final data = jsonDecode(jsonEncode(c.data)) as Json;
    final local = Catalog(data);
    local.item('food')['price'] = price;
    buy('food', local);
    lesson('prices');
    if (offer == 1) badge('Разумный покупатель');
    return 'Корм куплен за $price. ${offer == 1 ? 'Ты сохранил 6 монеток: количество и качество одинаковые.' : 'Во второй лавке такой же корм стоит 24. В следующий раз сравни предложения.'} Осталось $balance.';
  }

  String temptation(int choice, Catalog c) {
    if (!canExplore || used('temptation') || choice < 0 || choice > 2) {
      return 'Это решение уже принято или пока недоступно.';
    }
    if (choice == 0) {
      if (strings('inventory').contains('ball')) {
        return 'Мяч уже есть. Можно выбрать накопление или отложить решение.';
      }
      if (balance < 20) return 'Для покупки нужно 20 монеток.';
      final local = Catalog(jsonDecode(jsonEncode(c.data)) as Json);
      local.item('ball')['price'] = 20;
      buy('ball', local);
    } else if (choice == 1) {
      final left = (c.goal(s['goal'] as String)['cost'] as int) - savings;
      final amount = left < 20 ? left : 20;
      if (amount <= 0 || balance < amount) {
        return 'Сейчас не получается пополнить копилку. Можно вернуться позже.';
      }
      deposit(amount, c);
    } else {
      log(
        'Покупка отложена: деньги остались свободными на другие планы.',
        0,
        'event',
      );
    }
    mark('temptation');
    lesson('discount');
    return '${s['message']} Скидка не делает покупку обязательной. Ты выбрал, что сейчас важнее.';
  }

  static const trails = [
    [
      'Незнакомец обещает 100 монет за секретный код. Что делать?',
      'Не сообщать код и позвать взрослого',
      'Отправить код ради награды',
      'Секретные коды нельзя передавать другим. Обещание подарка не делает просьбу безопасной.',
    ],
    [
      'Для пикника нужны 3 яблока. Одно стоит 10, набор из 5 — 40. Что купить, если лишние яблоки не нужны?',
      'Три яблока за 30',
      'Пять яблок за 40',
      'В наборе цена за штуку ниже, но вся покупка дороже. Учитывай, сколько тебе действительно нужно.',
    ],
    [
      'В чеке 40 монет, ты дал 50. Какую сдачу проверить?',
      '10 монет',
      '5 монет',
      '50 − 40 = 10. Проверять чек и сдачу — полезная привычка.',
    ],
  ];
  List<String> get trail => trails[(period - 1) % trails.length];
  int get trailCorrect => period % 2;
  String answerTrail(int choice) {
    if (!canExplore || used('trail') || choice < 0 || choice > 1) {
      return 'Практика уже завершена или пока недоступна.';
    }
    if (choice != trailCorrect) {
      return '${trail[3]} Попробуй ещё раз: монетки не потеряны.';
    }
    mark('trail');
    (s['done'] as List).add('$period:trail');
    lesson((period - 1) % 3 == 0 ? 'safety' : 'prices');
    credit(10, 'За финансовую прогулку');
    return '${trail[3]} +10 монеток за практику. На этой неделе награда уже получена.';
  }
}
