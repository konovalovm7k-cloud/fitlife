import 'package:flutter/material.dart';

const _green = Color(0xFF3D9B70);
const _greenDark = Color(0xFF287451);
const _mint = Color(0xFFE8F5EE);
const _bg = Color(0xFFF6F8F6);
const _ink = Color(0xFF17231D);
const _muted = Color(0xFF7A857E);
const _line = Color(0xFFE5EAE6);

class ModernFitLifeApp extends StatelessWidget {
  const ModernFitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
        fontFamily: 'sans',
        appBarTheme: const AppBarTheme(backgroundColor: _bg, elevation: 0),
      ),
      home: const ModernHome(),
    );
  }
}

class ModernHome extends StatefulWidget {
  const ModernHome({super.key});
  @override
  State<ModernHome> createState() => _ModernHomeState();
}

class _ModernHomeState extends State<ModernHome> {
  int tab = 0;
  int calories = 1247;
  double protein = 126;
  double fat = 48;
  double carbs = 105;
  double fiber = 21;
  double water = 1.5;
  double weight = 104.2;

  final List<_Meal> meals = [
    _Meal('Завтрак', '08:30', 420, const [
      _FoodLine('Яйца', '3 шт.', 235),
      _FoodLine('Ветчина из индейки', '120 г', 101),
      _FoodLine('Яблоко', '100 г', 52),
    ]),
    _Meal('Обед', '13:10', 610, const [
      _FoodLine('Куриная грудка', '250 г', 275),
      _FoodLine('Гречка', '70 г', 240),
      _FoodLine('Овощи', '150 г', 45),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [_today(), _diary(), _weight(), _progress(), _profile()];
    return Scaffold(
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: pages[tab])),
      bottomNavigationBar: NavigationBar(
        height: 74,
        backgroundColor: Colors.white,
        elevation: 2,
        selectedIndex: tab,
        indicatorColor: _mint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
              color: states.contains(WidgetState.selected) ? _greenDark : _muted,
            )),
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Сегодня'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'Питание'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight_rounded), label: 'Вес'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Прогресс'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
      floatingActionButton: tab == 0 || tab == 1
          ? FloatingActionButton.extended(
              elevation: 3,
              backgroundColor: _green,
              foregroundColor: Colors.white,
              onPressed: _showAddFood,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Добавить еду', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }

  Widget _today() => ListView(
        key: const ValueKey('today'),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _header('Сегодня', '4 сентября · пятница'),
          _dateStrip(),
          const SizedBox(height: 14),
          _calorieHero(),
          const SizedBox(height: 14),
          _macroCard(),
          const SizedBox(height: 12),
          _quickStats(),
          const SizedBox(height: 20),
          _sectionTitle('Дневник питания', 'Все приёмы'),
          ...meals.map(_mealCard),
        ],
      );

  Widget _diary() => ListView(
        key: const ValueKey('diary'),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _header('Питание', 'Сегодня · 4 сентября'),
          _dailySummary(),
          const SizedBox(height: 10),
          ...meals.map(_mealCard),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                backgroundColor: Colors.white,
              ),
              onPressed: _showAddFood,
              icon: const Icon(Icons.add_rounded, color: _green),
              label: const Text('Добавить приём пищи', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            ),
          ),
          const SizedBox(height: 12),
          _tipCard(),
        ],
      );

  Widget _header(String title, String subtitle) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 30, height: 1.05, fontWeight: FontWeight.w900, color: _ink)),
                const SizedBox(height: 5),
                Text(subtitle, style: const TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => tab = 4),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
                child: const Icon(Icons.person_outline_rounded, color: _ink),
              ),
            ),
          ],
        ),
      );

  Widget _dateStrip() => SizedBox(
        height: 70,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: 7,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == 3;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54,
              decoration: BoxDecoration(
                color: active ? _green : Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: active ? _green : _line),
                boxShadow: active ? const [BoxShadow(color: Color(0x183D9B70), blurRadius: 10, offset: Offset(0, 4))] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'][i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: active ? Colors.white70 : _muted)),
                const SizedBox(height: 2),
                Text('${1 + i}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: active ? Colors.white : _ink)),
              ]),
            );
          },
        ),
      );

  Widget _calorieHero() {
    const goal = 1900;
    final remaining = goal - calories;
    final progress = (calories / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_ink, Color(0xFF24382D)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Row(children: [
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 128, height: 128, child: CircularProgressIndicator(value: progress, strokeWidth: 10, backgroundColor: Colors.white12, color: const Color(0xFF7BE0A8))),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$calories', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const Text('ккал', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Дневная цель', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            const Text('1 900 ккал', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('$remaining', style: const TextStyle(color: Color(0xFF7BE0A8), fontSize: 27, fontWeight: FontWeight.w900)),
            const Text('осталось сегодня', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
    );
  }

  Widget _dailySummary() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _card(Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Сегодня', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
            Text('$calories / 1 900 ккал', style: const TextStyle(color: _greenDark, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: calories / 1900, minHeight: 9, color: _green, backgroundColor: _mint)),
          const SizedBox(height: 14),
          Row(children: [
            _summaryMetric('Белок', '${protein.round()} г'),
            _summaryMetric('Жиры', '${fat.round()} г'),
            _summaryMetric('Углеводы', '${carbs.round()} г'),
            _summaryMetric('Клетчатка', '${fiber.round()} г'),
          ]),
        ]),
      );

  Widget _summaryMetric(String label, String value) => Expanded(child: Column(children: [Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w600))]));

  Widget _macroCard() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Баланс макросов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
          const SizedBox(height: 15),
          Row(children: [
            _macro('Белки', protein, 170, _green),
            _macro('Жиры', fat, 60, const Color(0xFFE2A53D)),
            _macro('Углеводы', carbs, 180, const Color(0xFF718DDA)),
          ]),
          const SizedBox(height: 14),
          Row(children: [const Icon(Icons.eco_outlined, size: 19, color: _green), const SizedBox(width: 7), const Text('Клетчатка', style: TextStyle(color: _muted, fontWeight: FontWeight.w700)), const Spacer(), Text('$fiber / 30 г', style: const TextStyle(color: _ink, fontWeight: FontWeight.w900))]),
        ]),
      );

  Widget _macro(String name, double value, double goal, Color color) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (value / goal).clamp(0, 1), minHeight: 7, color: color, backgroundColor: _line)), const SizedBox(height: 5), Text('${value.round()} / ${goal.round()} г', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink))])));

  Widget _quickStats() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Expanded(child: _smallStat(Icons.water_drop_outlined, 'Вода', '${water.toStringAsFixed(1)} л', () => setState(() => water = (water + .25).clamp(0, 3)))), const SizedBox(width: 9), Expanded(child: _smallStat(Icons.monitor_weight_outlined, 'Вес', '$weight кг', null)), const SizedBox(width: 9), Expanded(child: _smallStat(Icons.directions_walk_outlined, 'Шаги', '2 840', null))]));

  Widget _smallStat(IconData icon, String title, String value, VoidCallback? onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _green, size: 21), const SizedBox(height: 8), Text(title, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700)), Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 15))])));

  Widget _sectionTitle(String title, String action) => Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 3), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _ink))), Text(action, style: const TextStyle(color: _greenDark, fontSize: 12, fontWeight: FontWeight.w800))]));

  Widget _mealCard(_Meal meal) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 7, 20, 7),
        child: _card(Column(children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(14)), child: Icon(_mealIcon(meal.name), color: _greenDark)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(meal.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 2), Text(meal.time, style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600))])),
            Text('${meal.kcal} ккал', style: const TextStyle(fontWeight: FontWeight.w900, color: _greenDark)),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 6),
          ...meal.items.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(f.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink))), Text(f.amount, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(width: 14), Text('${f.kcal}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink))]))),
        ])),
      );

  IconData _mealIcon(String name) => name == 'Завтрак' ? Icons.wb_sunny_outlined : name == 'Обед' ? Icons.lunch_dining_outlined : name == 'Ужин' ? Icons.nightlight_outlined : Icons.local_cafe_outlined;

  Widget _tipCard() => Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(20)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome_rounded, color: _greenDark), SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Совет FitLife', style: TextStyle(fontWeight: FontWeight.w900, color: _greenDark)), SizedBox(height: 4), Text('До белковой цели осталось около 44 г. На ужин отлично подойдут курица, рыба или творог.', style: TextStyle(fontSize: 12, height: 1.35, color: _ink, fontWeight: FontWeight.w600))]))])));

  Widget _weight() => ListView(key: const ValueKey('weight'), padding: const EdgeInsets.only(bottom: 30), children: [_header('Вес', 'Путь к цели'), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$weight кг', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 4), const Text('−5.8 кг от старта', style: TextStyle(color: _greenDark, fontWeight: FontWeight.w800)), const SizedBox(height: 20), SizedBox(height: 180, child: CustomPaint(painter: _LinePainter())), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('110', style: TextStyle(color: _muted)), Text('100'), Text('90'), Text('85 кг', style: TextStyle(color: _greenDark, fontWeight: FontWeight.w800))])]))), const SizedBox(height: 14), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))), onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Записать вес', style: TextStyle(fontWeight: FontWeight.w800))))]);

  Widget _progress() => ListView(key: const ValueKey('progress'), padding: const EdgeInsets.only(bottom: 30), children: [_header('Прогресс', 'Твоя динамика'), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ты движешься к цели', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 13), ClipRRect(borderRadius: BorderRadius.circular(10), child: const LinearProgressIndicator(value: .232, minHeight: 10, color: _green, backgroundColor: _mint)), const SizedBox(height: 10), const Text('23% пути пройдено · осталось 19.2 кг', style: TextStyle(color: _muted, fontWeight: FontWeight.w700))]))), const SizedBox(height: 12), _statBlock('Среднее питание', '$calories ккал', 'сегодня'), _statBlock('Белок', '${protein.round()} г', 'из 170 г'), _statBlock('Клетчатка', '${fiber.round()} г', 'из 30 г')]);

  Widget _statBlock(String title, String value, String note) => Padding(padding: const EdgeInsets.fromLTRB(20, 5, 20, 5), child: _card(Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: _ink))])), Text(note, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))])));

  Widget _profile() => ListView(key: const ValueKey('profile'), padding: const EdgeInsets.only(bottom: 30), children: [_header('Профиль', 'Настройки FitLife'), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Моя цель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 10), const Text('Снижение веса', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 4), const Text('110 кг → 85 кг', style: TextStyle(color: _muted, fontWeight: FontWeight.w600))]))), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _card(const Column(children: [ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.notifications_none_rounded, color: _greenDark), title: Text('Напоминания', style: TextStyle(fontWeight: FontWeight.w800)), trailing: Icon(Icons.chevron_right_rounded)), Divider(color: _line), ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.palette_outlined, color: _greenDark), title: Text('Тема приложения', style: TextStyle(fontWeight: FontWeight.w800)), trailing: Text('Светлая', style: TextStyle(color: _muted, fontWeight: FontWeight.w700))])))]);

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 5))]), child: child);

  Future<void> _showAddFood() async {
    final controller = TextEditingController();
    final grams = TextEditingController(text: '100');
    final added = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: Container(padding: const EdgeInsets.fromLTRB(20, 10, 20, 24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(5)))), const SizedBox(height: 18), const Text('Добавить еду', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 14), TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: 'Название продукта', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))), const SizedBox(height: 10), TextField(controller: grams, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Количество, г', prefixIcon: const Icon(Icons.scale_outlined), filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))), const SizedBox(height: 14), SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Добавить в дневник', style: TextStyle(fontWeight: FontWeight.w900))))]))));
    controller.dispose();
    grams.dispose();
    if (added == true && mounted) {
      setState(() {
        calories += 120;
        protein += 10;
        fiber += 2;
        meals.add(const _Meal('Перекус', 'сейчас', 120, [_FoodLine('Новый продукт', '100 г', 120)]));
      });
    }
  }
}

class _Meal {
  final String name;
  final String time;
  final int kcal;
  final List<_FoodLine> items;
  const _Meal(this.name, this.time, this.kcal, this.items);
}

class _FoodLine {
  final String name;
  final String amount;
  final int kcal;
  const _FoodLine(this.name, this.amount, this.kcal);
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = _line..strokeWidth = 1;
    final line = Paint()..color = _green..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = i * size.height / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()
      ..moveTo(0, size.height * .08)
      ..cubicTo(size.width * .18, size.height * .14, size.width * .28, size.height * .28, size.width * .40, size.height * .34)
      ..cubicTo(size.width * .55, size.height * .41, size.width * .64, size.height * .55, size.width * .76, size.height * .65)
      ..cubicTo(size.width * .86, size.height * .73, size.width * .92, size.height * .81, size.width, size.height * .90);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
