import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'game.dart';
import 'store.dart';
import 'pet_scene.dart';
import 'art.dart';
import 'motion.dart';
part 'screens.dart';
part 'widgets.dart';
part 'redesign.dart';
part 'onboarding.dart';
part 'allocation.dart';
part 'adventures.dart';
part 'home_simple.dart';
part 'journey.dart';
part 'playground.dart';
part 'friends_house.dart';
part 'care_play.dart';
part 'adult.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  final box = await Hive.openBox('tailtown_v1');
  final catalog = Catalog(
    jsonDecode(await rootBundle.loadString('assets/data/content.json')) as Json,
  );
  runApp(
    ProviderScope(
      overrides: [storeProvider.overrideWith((ref) => Store(box, catalog))],
      child: const TailtownApp(),
    ),
  );
}

class TailtownApp extends StatelessWidget {
  const TailtownApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Город Хвостиков',
    debugShowCheckedModeBanner: false,
    builder: (context, child) => Consumer(
      builder: (context, ref, _) => MotionSettings(
        enabled: ref.watch(storeProvider).game.s['animations'] != false,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.disableAnimationsOf(context) ||
                ref.watch(storeProvider).game.s['animations'] == false,
          ),
          child: child!,
        ),
      ),
    ),
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(seedColor: green, surface: cream),
      scaffoldBackgroundColor: cream,
      textTheme: ThemeData.light().textTheme
          .apply(bodyColor: ink, displayColor: ink, fontFamily: 'Nunito')
          .copyWith(
            bodyMedium: const TextStyle(fontSize: 16, height: 1.4, color: ink),
            bodyLarge: const TextStyle(fontSize: 17, height: 1.4, color: ink),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 54),
          elevation: 4,
          shadowColor: const Color(0xFF086E29),
          side: const BorderSide(color: Color(0xFFCDFFA6), width: 2),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          foregroundColor: green,
          backgroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    home: const GameRoot(),
  );
}

IconData iconFor(String id) => switch (id) {
  'bike' => Icons.pedal_bike_rounded,
  'computer' => Icons.computer_rounded,
  'art' => Icons.palette_rounded,
  'food' => Icons.rice_bowl_rounded,
  'water' => Icons.water_drop_rounded,
  'care' => Icons.brush_rounded,
  'soap' => Icons.soap_rounded,
  'ball' => Icons.sports_baseball_rounded,
  'hat' => Icons.face_retouching_natural,
  'plant' => Icons.local_florist_rounded,
  'rocket' => Icons.rocket_launch_rounded,
  _ => Icons.star_rounded,
};
Widget titleText(String text) => Padding(
  padding: const EdgeInsets.only(top: 20, bottom: 12),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      height: 1.15,
    ),
  ),
);
Widget panel(Widget child, {Color color = Colors.white}) => EnterMotion(
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          color == Colors.white ? const Color(0xFFF1ECFF) : color,
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDAD2FF), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44261151),
          offset: Offset(0, 4),
          blurRadius: 7,
        ),
      ],
    ),
    child: Material(color: Colors.transparent, child: child),
  ),
);
Widget owl(String text) => panel(
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PetArt(pet: 5, size: 62),
      const SizedBox(width: 12),
      Expanded(child: Text(text)),
    ],
  ),
  color: const Color(0xFFFFF0C9),
);
Widget money(int n, {String label = 'монеток'}) => EnterMotion(
  identity: n,
  pop: true,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Coin(),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          '$n $label',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
    ],
  ),
);

class GameDialog extends StatelessWidget {
  final String heading, message;
  final List<Widget> actions;
  const GameDialog({
    super.key,
    required this.heading,
    required this.message,
    required this.actions,
  });
  @override
  Widget build(BuildContext context) => EnterMotion(
    pop: true,
    child: Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFF0E8FF)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFC4A6FF), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x665130AF),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeaderPill(heading),
                const PetArt(pet: 5, size: 105),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                for (final action in actions)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(width: double.infinity, child: action),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class GameRoot extends ConsumerStatefulWidget {
  const GameRoot({super.key});
  @override
  ConsumerState<GameRoot> createState() => _GameRootState();
}

class _GameRootState extends ConsumerState<GameRoot> {
  int tab = 0;
  int adventureTab = 0;
  bool onboardingRoom = false;
  String screen = '';
  String journeyMessage = '';
  Future<void> journeyAct(String Function(Game) action) async {
    final message = await store.act(action);
    if (mounted) setState(() => journeyMessage = message);
  }

  Store get store => ref.read(storeProvider);
  Game get g => store.game;
  Catalog get c => store.catalog;
  void updateView(VoidCallback fn) => setState(fn);
  void go(String page) => setState(() => screen = page);
  Future<void> act(String Function(Game) f, {bool show = true}) async {
    final message = await store.act(f);
    if (!mounted) return;
    if (show) {
      await showDialog<void>(
        context: context,
        builder: (context) => GameDialog(
          heading: 'Совёнок рядом',
          message: message,
          actions: [
            GameButton('Понятно', onPressed: () => Navigator.pop(context)),
          ],
        ),
      );
    }
  }

  Future<bool> confirm(
    String title,
    String text, {
    String button = 'Подтвердить',
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => GameDialog(
          heading: title,
          message: text,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Назад'),
            ),
            GameButton(button, onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeProvider);
    final game = state.game;
    if (!game.started) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(actions: [adultEntry(context)]),
        body: GameBackdrop(
          scene: onboardingRoom ? 'room' : 'city',
          shade: .15,
          child: SafeArea(
            top: false,
            child: Onboarding(
              onStepChanged: (step) =>
                  setState(() => onboardingRoom = step == 1),
              onStart: (name, pet, color, goal) async {
                await act(
                  (g) => g.start(name, pet, color, goal, c),
                  show: false,
                );
                if (mounted) {
                  setState(() {
                    screen = '';
                    onboardingRoom = false;
                    tab = 0;
                  });
                }
              },
              catalog: c,
              album: game.records('album'),
            ),
          ),
        ),
      );
    }
    final content = screen.isNotEmpty
        ? switch (screen) {
            'budget' => budget(),
            'shop' => shop(),
            'savings' => savings(),
            'tasks' => tasks(),
            'adventures' => adventures(),
            'guide' => guide(),
            'lessons' => book(),
            'history' => history(),
            'journey' => journey(),
            'friends' => friendsHouse(),
            'playground' => playground(),
            'care-play' => CarePlay(
              game: g,
              onAction: (action) =>
                  store.act((game) => game.careForPet(action)),
              onShop: () => go('shop'),
              onStory: () => go('journey'),
            ),
            'delivery' => deliveryGame(),
            'receipt' => receiptGame(),
            'ball-play' => ballGame(),
            'memory' => MemoryGame(
              onHome: () => go(''),
              onComplete: () {
                act((game) {
                  game.badge('Мастер списка');
                  game.lesson('needs');
                  return 'Достижение получено!';
                }, show: false);
              },
            ),
            'wardrobe' => wardrobe(),
            _ => home(),
          }
        : switch (tab) {
            1 => city(),
            2 => planHub(),
            3 => album(),
            _ => game.finished ? ending() : home(),
          };
    final heading = screen.isNotEmpty
        ? ({
                'budget': 'Планирование бюджета',
                'shop': 'Магазин',
                'savings': 'Копилка и цели',
                'tasks': 'Практика с совёнком',
                'adventures': 'Приключения недели',
                'guide': 'Как играть',
                'lessons': 'Знания',
                'history': 'Наш путь',
                'journey': 'Вместе к мечте',
                'friends': 'Дом друзей',
                'playground': 'Игровая площадка',
                'care-play': 'Забота о друге',
                'delivery': 'Курьер',
                'receipt': 'Детектив чеков',
                'ball-play': 'Игра с питомцем',
                'memory': 'Список покупок',
                'wardrobe': 'Комната питомца',
              }[screen] ??
              'Город Хвостиков')
        : [
            'Главный экран',
            'Карта города',
            'План и игры',
            'Истории и награды',
          ][tab];
    return PopScope(
      canPop: screen.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) go('');
      },
      child: Scaffold(
        extendBodyBehindAppBar: !(tab == 1 && screen.isEmpty),
        appBar: AppBar(
          backgroundColor: tab == 1 && screen.isEmpty
              ? purple
              : Colors.transparent,
          leading: screen.isNotEmpty
              ? IconButton(
                  onPressed: () => go(''),
                  icon: const Icon(Icons.arrow_circle_left_rounded),
                  tooltip: 'Назад',
                )
              : null,
          title: screen.isEmpty && tab == 0
              ? null
              : HeaderPill(state.demo ? 'Демо • $heading' : heading),
          actions: screen.isEmpty && (tab == 0 || tab == 1)
              ? [
                  adultEntry(context),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xDDFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              game.isNight
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded,
                              size: 17,
                              color: game.isNight
                                  ? purple
                                  : const Color(0xFFDF8C00),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              game.clockLabel,
                              style: const TextStyle(
                                color: deepPurple,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]
              : [adultEntry(context)],
        ),
        body: GameBackdrop(
          scene: tab == 1 ? 'city' : 'room',
          shade: screen.isEmpty && tab == 0 ? (game.isNight ? .38 : 0) : .18,
          child: SafeArea(
            child: AbsorbPointer(
              absorbing: state.busy,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RewardMotion(
                      trigger:
                          '${game.records('album').length}:${game.strings('badges').length}',
                      playOnMount: game.finished,
                      child: EnterMotion(
                        identity: '$tab:$screen:${game.finished}',
                        child: KeyedSubtree(
                          key: ValueKey('$tab:$screen'),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                  if (state.busy) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: states.contains(WidgetState.selected)
                      ? sunshine
                      : Colors.white,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  color: states.contains(WidgetState.selected)
                      ? deepPurple
                      : Colors.white,
                ),
              ),
            ),
          ),
          child: NavigationBar(
            height: 65,
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() {
              tab = i;
              screen = '';
            }),
            backgroundColor: purple,
            indicatorColor: sunshine,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_rounded),
                label: 'Дом',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_rounded),
                label: 'Город',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_rounded),
                label: 'План',
              ),
              NavigationDestination(
                icon: Icon(Icons.collections_bookmark_rounded),
                label: 'Истории',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget list(List<Widget> children) => SingleChildScrollView(
    key: ValueKey('$screen:$tab:${g.finished}'),
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD6BFFF), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ),
  );
  PetScene scene({bool bike = false, double height = 210}) => PetScene(
    pet: g.s['pet'] as int,
    color: g.s['color'] as int,
    hat: g.s['hat'] == true,
    plant: g.strings('inventory').contains('plant'),
    ball: g.strings('inventory').contains('ball'),
    bike: bike,
    dream: g.finished ? g.s['goal'] as String : null,
    animate: g.s['animations'] == true,
    night: g.isNight,
    height: height,
    stage: g.stage,
    thoughtful: (g.s['mood'] as String? ?? '').startsWith('Задумался'),
  );
  Widget home() => homeV2();
}
