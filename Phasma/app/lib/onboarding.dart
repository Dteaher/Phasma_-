part of 'main.dart';

class Onboarding extends StatefulWidget {
  final Future<void> Function(String, int, int, String) onStart;
  final Catalog catalog;
  final List<Json> album;
  final ValueChanged<int>? onStepChanged;
  const Onboarding({
    super.key,
    required this.onStart,
    required this.catalog,
    required this.album,
    this.onStepChanged,
  });
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int step = -1, pet = 0, color = 0;
  String goal = 'bike';
  final name = TextEditingController(text: 'Персик');
  @override
  void initState() {
    super.initState();
    if (widget.album.isNotEmpty) {
      step = 0;
      pet = List.generate(5, (i) => i).firstWhere(
        (i) => !widget.album.any((story) => story['pet'] == i),
        orElse: () => 0,
      );
      name.text = petNicknames[pet];
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (step == -1) {
        return LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              key: const ValueKey('welcome'),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x22291A61),
                        Color(0x00291A61),
                        Color(0xEE291A61),
                      ],
                      stops: [0, .35, 1],
                    ),
                  ),
                  child: Column(
                    children: [
                      _logo('Город', 52),
                      _logo('Хвостиков', 44),
                      const SizedBox(height: 12),
                      const Text(
                        'Большая мечта маленького друга',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: deepPurple, blurRadius: 8)],
                        ),
                      ),
                      SizedBox(
                        height: (viewport.maxHeight * .45).clamp(260, 420),
                        child: LayoutBuilder(
                          builder: (context, scene) => Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: scene.maxWidth,
                                height: scene.maxWidth,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0xBBFFF5BA),
                                      Color(0x00FFF5BA),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: sunshine,
                                      width: 3,
                                    ),
                                  ),
                                  child: const ItemArt('bike', size: 82),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 15,
                                child: PetArt(
                                  pet: 0,
                                  size: scene.maxWidth * .9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Помоги другу накопить на велосипед',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Играй, заботься и учись обращаться с деньгами.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5DFFF),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: GameButton(
                          'Начать приключение',
                          onPressed: () => setState(() => step = 0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
      return SingleChildScrollView(
        key: ValueKey('onboarding-$step'),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 60, 14, 26),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 510),
            child: Column(
              children: [
                HeaderPill(
                  step == 0 ? 'Выбери своего питомца' : 'Как назовём друга?',
                ),
                const SizedBox(height: 16),
                if (step == 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, petAccents[pet]],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44251454),
                          blurRadius: 16,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: PetArt(
                            key: ValueKey(pet),
                            pet: pet,
                            size: 195,
                          ),
                        ),
                        Text(
                          petTraits[pet],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: deepPurple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          petGreetings[pet],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.textScalerOf(context).scale(1) > 1.3
                        ? 190
                        : 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => Semantics(
                        selected: pet == i,
                        button: true,
                        child: InkWell(
                          key: ValueKey('choose-pet-$i'),
                          onTap: () => setState(() {
                            if (petNicknames.contains(name.text)) {
                              name.text = petNicknames[i];
                            }
                            pet = i;
                          }),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 94,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: pet == i ? petAccents[i] : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: pet == i ? deepPurple : Colors.white,
                                width: pet == i ? 3 : 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                PetArt(pet: i, size: 76),
                                Text(
                                  petNames[i],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (pet == i)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: deepPurple,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  panel(
                    const Text(
                      'Листай друзей в стороны. У каждого свой характер — возможности одинаковые.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: deepPurple),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: GameButton(
                      'Подружиться',
                      onPressed: () {
                        setState(() => step = 1);
                        widget.onStepChanged?.call(1);
                      },
                    ),
                  ),
                ] else ...[
                  PetScene(
                    pet: pet,
                    color: color,
                    height: 230,
                    background: false,
                  ),
                  const SizedBox(height: 15),
                  panel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Имя твоего друга',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: name,
                          maxLength: 16,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Придумай имя',
                            counterText: '',
                            suffixIcon: Icon(
                              Icons.edit_rounded,
                              color: Color(0xFFD58A13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'До 16 букв. Настоящее имя не нужно.',
                          style: TextStyle(color: ink, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  panel(
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => color = i),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEAFF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: color == i ? sunshine : Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    PetArt(pet: pet, color: i, size: 70),
                                    Text(
                                      ['Солнечный', 'Небесный', 'Сиреневый'][i],
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.album.isEmpty)
                    owl(
                      'Моя мечта — велосипед! Хочу кататься по парку с друзьями. Поможешь мне?',
                    )
                  else
                    panel(
                      Column(
                        children: [
                          const Text(
                            'Выбери историю нового друга',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              for (final item in widget.catalog.goals)
                                ChoiceChip(
                                  label: Text(item['name'] as String),
                                  selected: goal == item['id'],
                                  onSelected: (_) => setState(
                                    () => goal = item['id'] as String,
                                  ),
                                ),
                            ],
                          ),
                          Text(widget.catalog.goal(goal)['story'] as String),
                        ],
                      ),
                    ),
                  panel(
                    const Text(
                      'Нужно — забота. Хочу — приятные покупки. Коплю — шаги к мечте.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: GameButton(
                      'Начать нашу историю',
                      onPressed: () async {
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Придумай игровое имя питомцу.'),
                            ),
                          );
                          return;
                        }
                        await widget.onStart(name.text, pet, color, goal);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () {
                      setState(() => step = 0);
                      widget.onStepChanged?.call(0);
                    },
                    child: const Text('Выбрать другого питомца'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget _logo(String text, double size) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: size,
            height: 1.05,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9
              ..color = deepPurple,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: size,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: sunshine,
            shadows: const [
              Shadow(color: Color(0xFFF89825), offset: Offset(0, 3)),
            ],
          ),
        ),
      ],
    ),
  );
}
