import 'dart:convert';
part 'mechanics.dart';

typedef Json = Map<String, dynamic>;

class Catalog {
  final Json data;
  Catalog(this.data);
  List<Json> list(String key) => (data[key] as List).cast<Json>();
  List<Json> get items => list('items');
  List<Json> get tasks => list('tasks');
  List<Json> get goals => list('goals');
  List<Json> get lessons => list('lessons');
  Json item(String id) => items.firstWhere((e) => e['id'] == id);
  Json goal(String id) => goals.firstWhere((e) => e['id'] == id);
  Json task(String id) => tasks.firstWhere((e) => e['id'] == id);
}

class Game {
  final Json s;
  Game(this.s);
  factory Game.empty() => Game({
    'version': 1,
    'name': '',
    'pet': 0,
    'color': 0,
    'goal': 'bike',
    'period': 1,
    'balance': 0,
    'savings': 0,
    'plan': null,
    'spentNeed': 0,
    'spentWant': 0,
    'saved': 0,
    'withdrawn': 0,
    'income': 0,
    'opening': 0,
    'phase': 'plan',
    'completed': false,
    'inventory': <String>[],
    'purchases': <String>[],
    'done': <String>[],
    'attempts': <String, dynamic>{},
    'history': <Json>[],
    'summaries': <Json>[],
    'album': <Json>[],
    'lessons': <String>[],
    'badges': <String>[],
    'growth': 0,
    'hat': false,
    'animations': true,
    'sound': false,
    'rescue': false,
    'eventDone': false,
    'message': '',
    'mood': 'С интересом ждёт приключений',
    'gameHour': 9,
    'gameDay': 1,
    'fedDay': 0,
    'groomedDay': 0,
    'fedPeriod': 0,
    'groomedPeriod': 0,
  });
  Game copy() => Game(jsonDecode(jsonEncode(s)) as Json);
  String get name => s['name'] as String;
  int get balance => s['balance'] as int;
  int get savings => s['savings'] as int;
  int get period => s['period'] as int;
  bool get started => name.isNotEmpty;
  bool get finished => s['completed'] == true;
  bool get planned => s['plan'] != null;
  bool get active => started && !finished && s['phase'] != 'summary';
  int get gameHour => (s['gameHour'] as int? ?? 9);
  int get gameDay => (s['gameDay'] as int? ?? 1);
  bool get isNight => gameHour < 7 || gameHour >= 20;
  String get clockLabel => '${gameHour.toString().padLeft(2, '0')}:00';
  void advanceTime() {
    final nextHour = gameHour + 2;
    s['gameHour'] = nextHour % 24;
    if (nextHour >= 24) s['gameDay'] = gameDay + 1;
  }

  bool get fedToday => s['fedDay'] == gameDay;
  String restUntilMorning() {
    if (!started || finished || !isNight) {
      return 'Отдохнём, когда наступит ночь.';
    }
    if (gameHour >= 20) s['gameDay'] = gameDay + 1;
    s['gameHour'] = 9;
    return 'Доброе утро! Новый день ждёт.';
  }

  bool get groomedToday => s['groomedDay'] == gameDay;
  bool get fedThisWeek => s['fedPeriod'] == period;
  bool get groomedThisWeek => s['groomedPeriod'] == period;
  String careForPet(String action) {
    if (!started || finished) return 'Сначала выбери питомца.';
    if (action == 'feed') {
      if (!strings('purchases').contains('food')) {
        return 'Сначала купи корм в магазине.';
      }
      if (fedThisWeek) {
        return 'Питомец уже сыт. На этой неделе можно играть дальше!';
      }
      advanceTime();
      s['fedDay'] = gameDay;
      s['fedPeriod'] = period;
      s['mood'] = 'Сыт и рад твоей заботе';
      return 'Вкусно! Питомец рад и готов играть.';
    }
    if (action == 'groom') {
      if (!strings('purchases').contains('care')) {
        return 'Сначала купи уход за шерстью.';
      }
      if (groomedThisWeek) return 'Шёрстка уже причёсана. Спасибо!';
      advanceTime();
      s['groomedDay'] = gameDay;
      s['groomedPeriod'] = period;
      s['mood'] = 'Доволен, что его причесали';
      return 'Какая мягкая шёрстка! Питомец радуется.';
    }
    return 'Выбери корм или расчёску.';
  }

  int get stage => (s['growth'] as int) >= 9
      ? 3
      : (s['growth'] as int) >= 4
      ? 2
      : 1;
  List<String> strings(String key) => (s[key] as List).cast<String>();
  List<Json> records(String key) => (s[key] as List).cast<Json>();
  void badge(String id) {
    if (!strings('badges').contains(id)) (s['badges'] as List).add(id);
  }

  void lesson(String id) {
    if (!strings('lessons').contains(id)) (s['lessons'] as List).add(id);
  }

  void log(String text, int amount, String kind) {
    if (started) advanceTime();
    s['mood'] = switch (kind) {
      'need' => 'Доволен заботой',
      'want' => 'Рад новой вещи',
      'deposit' => 'Рад: мечта ближе',
      'withdraw' => 'Задумался о новых планах',
      'goal' => 'В восторге: мечта сбылась!',
      'learning' => 'Готов попробовать ещё раз',
      'income' => 'С интересом строит планы',
      _ => s['mood'] ?? 'Рад быть с тобой',
    };
    (s['history'] as List).add({
      'period': period,
      'text': text,
      'amount': amount,
      'kind': kind,
    });
    s['message'] = text;
  }

  void credit(int amount, String why) {
    s['balance'] = balance + amount;
    s['income'] = (s['income'] as int) + amount;
    log(why, amount, 'income');
  }

  String start(String name, int pet, int color, String goal, Catalog c) {
    if (started) return 'История уже началась.';
    if (name.trim().isEmpty ||
        name.trim().length > 16 ||
        pet < 0 ||
        pet > 4 ||
        color < 0 ||
        color > 2) {
      return 'Выбери питомца и игровое имя до 16 букв.';
    }
    c.goal(goal);
    s.addAll({'name': name.trim(), 'pet': pet, 'color': color, 'goal': goal});
    credit(120, 'Карманные монетки на первую неделю');
    s['gameHour'] = 9;
    lesson('income');
    return 'У $name есть 120 монеток. Составим план!';
  }

  String setPlan(int need, int want, int save) {
    if (!active || planned) return 'План этой недели уже подтверждён.';
    if ([need, want, save].any((v) => v < 0) || need + want + save > balance) {
      return 'Распредели не больше доступных монеток.';
    }
    s['plan'] = {'need': need, 'want': want, 'save': save};
    s['phase'] = 'play';
    lesson('budget');
    log(
      'План: нужно $need, хочу $want, коплю $save. Монетки пока не потрачены.',
      0,
      'plan',
    );
    return s['message'] as String;
  }

  bool hasNeed(Catalog c) =>
      ['food', 'water', 'care'].every(strings('purchases').contains);
  bool get hasEvent => period >= 4 && period % 3 == 1;
  String buy(String id, Catalog c) {
    if (!active || !planned) return 'Сначала составь план недели.';
    final item = c.item(id);
    final price = item['price'] as int;
    if (strings('purchases').contains(id) ||
        (item['durable'] == true && strings('inventory').contains(id))) {
      return 'Эта вещь уже куплена.';
    }
    if (balance < price) {
      return 'Не хватает ${price - balance} монеток. Можно отложить покупку или выполнить доступное задание.';
    }
    s['balance'] = balance - price;
    final key = item['category'] == 'need' ? 'spentNeed' : 'spentWant';
    s[key] = (s[key] as int) + price;
    (s['purchases'] as List).add(id);
    if (item['durable'] == true) (s['inventory'] as List).add(id);
    lesson('needs');
    log(
      '${item['name']}: ${item['effect']}',
      -price,
      item['category'] as String,
    );
    return '${item['name']} у питомца! ${item['effect']} Осталось $balance монеток.';
  }

  String deposit(int amount, Catalog c) {
    if (!active || !planned) return 'Сначала составь план недели.';
    if (amount <= 0 || amount > balance) {
      return 'Выбери сумму от 1 до $balance.';
    }
    final left = (c.goal(s['goal'] as String)['cost'] as int) - savings;
    if (amount > left) return 'На эту мечту осталось отложить $left монеток.';
    s['balance'] = balance - amount;
    s['savings'] = savings + amount;
    s['saved'] = (s['saved'] as int) + amount;
    badge('Первая копилка');
    lesson('savings');
    log('В копилку отложено $amount. Мечта стала ближе!', amount, 'deposit');
    return s['message'] as String;
  }

  String withdraw(int amount) {
    if (!active || !planned || amount <= 0 || amount > savings) {
      return 'Такую сумму снять нельзя.';
    }
    s['savings'] = savings - amount;
    s['balance'] = balance + amount;
    s['withdrawn'] = (s['withdrawn'] as int) + amount;
    log(
      'Из копилки взято $amount. На мечту осталось $savings монеток.',
      -amount,
      'withdraw',
    );
    return s['message'] as String;
  }

  List<Json> availableTasks(Catalog c) {
    return c.tasks
        .where(
          (task) =>
              (task['weeks'] as List? ?? []).contains(period) ||
              (task['repeatFrom'] != null &&
                  period >= (task['repeatFrom'] as int)),
        )
        .toList();
  }

  String answer(String id, dynamic answer, Catalog c) {
    if (!started) return 'Сначала выбери питомца, которому хочешь помочь.';
    if (finished) {
      return 'Мечта исполнена! Можно начать историю с другим питомцем.';
    }
    if (s['phase'] == 'summary') {
      return 'Это приключение завершено. Начни новое — ждать не нужно.';
    }
    if (!planned) {
      return 'Сначала выбери план: сколько оставить на заботу, желания и мечту.';
    }
    if (!availableTasks(c).any((t) => t['id'] == id)) {
      return 'Эта игра появится в другом приключении. Выбери одну из доступных сейчас.';
    }
    final key = '$period:$id';
    if (strings('done').contains(key)) {
      return 'Это задание уже завершено. Повторной награды нет.';
    }
    final task = c.task(id);
    bool success;
    if (task['type'] == 'allocation') {
      final values = (answer as List).cast<int>();
      success =
          values.length == 3 &&
          values.every((v) => v >= 0) &&
          values.fold<int>(0, (a, b) => a + b) <= (task['budget'] as int) &&
          values[0] >= (task['minNeed'] as int) &&
          values[2] >= (task['minSave'] as int);
    } else if (task['type'] == 'basket') {
      final ids = (answer as List).cast<String>().toSet();
      final choices = (task['choices'] as List).cast<Json>();
      final selected = choices.where((e) => ids.contains(e['id'])).toList();
      success =
          selected.length == ids.length &&
          selected.fold<int>(0, (a, e) => a + (e['price'] as int)) <=
              (task['budget'] as int) &&
          (task['required'] as List).every(ids.contains);
    } else if (task['type'] == 'change') {
      final coins = (answer as List).cast<int>();
      final allowed = (task['coins'] as List).cast<int>();
      success =
          coins.isNotEmpty &&
          coins.length <= 30 &&
          coins.every(allowed.contains) &&
          coins.fold<int>(0, (a, b) => a + b) ==
              (task['paid'] as int) - (task['price'] as int);
    } else if (task['type'] == 'sort') {
      final values = (answer as List).cast<int>();
      final expected = (task['choices'] as List).cast<Json>();
      success =
          values.length == expected.length &&
          List.generate(
            expected.length,
            (i) => i,
          ).every((i) => values[i] == expected[i]['correct']);
    } else {
      success = answer == task['correct'];
    }
    final attempts = s['attempts'] as Json;
    attempts[key] = (attempts[key] as int? ?? 0) + 1;
    lesson(task['lesson'] as String);
    if (!success && task['type'] != 'choice') {
      log(task['retry'] as String, 0, 'learning');
      return task['retry'] as String;
    }
    (s['done'] as List).add(key);
    if (id == 'compare' && success) badge('Финансовый детектив');
    if (id == 'change') badge('Мастер сдачи');
    if (id == 'sort') badge('Разумный выбор');
    credit(10, 'За практику: ${task['title']}');
    final explanation = task['type'] == 'choice'
        ? (task['outcomes'] as List)[answer as int] as String
        : task['success'] as String;
    s['message'] =
        '$explanation +10 монеток за практику. Продолжай путь к мечте!';
    return s['message'] as String;
  }

  String event(bool repair) {
    if (!active || !planned || !hasEvent || s['eventDone'] == true) {
      return 'Событие уже решено или ещё не наступило.';
    }
    if (repair) {
      if (balance < 20) {
        return 'На ремонт нужно 20 монеток. Можно использовать копилку или временно взять запасной рюкзак.';
      }
      s['balance'] = balance - 20;
      s['spentNeed'] = (s['spentNeed'] as int) + 20;
      log('Рюкзак отремонтирован. Он снова удобный!', -20, 'need');
    } else {
      log(
        'Пока возьмём запасной рюкзак у совёнка. Монетки сохранены, старый рюкзак ещё ждёт ремонта.',
        0,
        'event',
      );
    }
    s['eventDone'] = true;
    lesson('reserve');
    return s['message'] as String;
  }

  String rescue() {
    if (!active || !planned || s['rescue'] == true || balance >= 30) {
      return 'Помощь доступна один раз в неделю, когда осталось меньше 30 монеток.';
    }
    s['rescue'] = true;
    credit(
      30,
      'Поддержка совёнка: 30 монеток на необходимое. В следующем плане оставим запас.',
    );
    lesson('reserve');
    return s['message'] as String;
  }

  String end(Catalog c) {
    if (!active || !planned) return 'Сначала составь план.';
    if (!strings('done').any((id) => id.startsWith('$period:'))) {
      return 'Пройди хотя бы одно задание недели.';
    }
    if (hasEvent && s['eventDone'] != true) {
      return 'Сначала реши, что делать с рюкзаком.';
    }
    final plan = s['plan'] as Json;
    final need = hasNeed(c);
    final within =
        (s['spentNeed'] as int) <= (plan['need'] as int) &&
        (s['spentWant'] as int) <= (plan['want'] as int);
    final netSaved = (s['saved'] as int) - (s['withdrawn'] as int);
    final points = (need ? 1 : 0) + (within ? 1 : 0) + (netSaved > 0 ? 1 : 0);
    final before = stage;
    s['growth'] = (s['growth'] as int) + points;
    final summary = {
      'period': period,
      'plan': Map<String, dynamic>.from(plan),
      'need': s['spentNeed'],
      'want': s['spentWant'],
      'save': netSaved,
      'points': points,
      'stage': stage,
      'reason':
          '${need ? 'Необходимое куплено.' : 'Необходимое пока не куплено. На новой неделе начнём с него.'} ${within ? 'Покупки уложились в план.' : 'Покупки вышли за план. В следующий раз изменим распределение.'} ${netSaved > 0 ? 'Копилка пополнилась на $netSaved.' : 'Копилка не увеличилась. Можно выбрать посильную сумму в следующий раз.'} ${stage > before ? 'Питомец вырос благодаря решениям за несколько недель!' : ''}',
    };
    (s['summaries'] as List).add(summary);
    s['phase'] = 'summary';
    if (within && need) badge('Планировщик');
    if (period >= 5) badge('Пять недель вместе');
    if (period >= 2) badge('Парк открыт');
    log(summary['reason'] as String, 0, 'summary');
    return summary['reason'] as String;
  }

  String next() {
    if (finished || s['phase'] != 'summary') {
      return 'Сначала подведи итоги недели.';
    }
    s['period'] = period + 1;
    s.addAll({
      'opening': balance,
      'spentNeed': 0,
      'spentWant': 0,
      'saved': 0,
      'withdrawn': 0,
      'income': 0,
      'plan': null,
      'phase': 'plan',
      'purchases': <String>[],
      'rescue': false,
      'eventDone': false,
    });
    credit(120, 'Карманные монетки на неделю $period');
    return s['message'] as String;
  }

  String fulfill(Catalog c) {
    if (finished || !started) return 'Эта мечта уже исполнена.';
    final goal = c.goal(s['goal'] as String);
    final cost = goal['cost'] as int;
    if (savings < cost) return 'Осталось накопить ${cost - savings} монеток.';
    s['savings'] = savings - cost;
    s['completed'] = true;
    badge('Большая мечта');
    (s['album'] as List).add({
      'name': name,
      'pet': s['pet'],
      'color': s['color'],
      'goal': s['goal'],
      'periods': period,
      'plans':
          records('summaries').length +
          (planned && s['phase'] != 'summary' ? 1 : 0),
      'deposits': records(
        'history',
      ).where((e) => e['kind'] == 'deposit').length,
    });
    log('Мечта исполнена: ${goal['name']}!', -cost, 'goal');
    return s['message'] as String;
  }

  void newStory() {
    if (!finished) return;
    final keep = {
      'album': s['album'],
      'lessons': s['lessons'],
      'badges': s['badges'],
      'animations': s['animations'],
      'sound': s['sound'],
    };
    s
      ..clear()
      ..addAll(Game.empty().s)
      ..addAll(keep);
  }
}
