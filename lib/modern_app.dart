import 'package:flutter/material.dart';

const _green = Color(0xFF3F9B70);
const _dark = Color(0xFF17231D);
const _bg = Color(0xFFF5F7F4);
const _soft = Color(0xFFE6F1EA);
const _muted = Color(0xFF7A857E);

class ModernFitLifeApp extends StatelessWidget {
  const ModernFitLifeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitLife',
        theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: _bg, colorScheme: ColorScheme.fromSeed(seedColor: _green)),
        home: const ModernHome(),
      );
}

class ModernHome extends StatefulWidget {
  const ModernHome({super.key});
  @override
  State<ModernHome> createState() => _ModernHomeState();
}

class _ModernHomeState extends State<ModernHome> {
  int tab = 0;
  int calories = 1247;
  double protein = 126, fat = 48, carbs = 105, fiber = 21, weight = 104.2;
  final List<_Meal> meals = [
    _Meal('Завтрак', 420, const [_FoodLine('Яйца', '3 шт.', 235), _FoodLine('Ветчина из индейки', '120 г', 101), _FoodLine('Яблоко', '100 г', 52)]),
    _Meal('Обед', 610, const [_FoodLine('Куриная грудка', '250 г', 275), _FoodLine('Гречка', '70 г', 240), _FoodLine('Овощи', '150 г', 45)]),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [_today(), _diary(), _weight(), _progress(), _profile()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        height: 72, backgroundColor: Colors.white, selectedIndex: tab, indicatorColor: _soft,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Сегодня'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Питание'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight), label: 'Вес'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Прогресс'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
      floatingActionButton: tab < 2 ? FloatingActionButton.extended(backgroundColor: _green, foregroundColor: Colors.white, onPressed: _addFood, icon: const Icon(Icons.add), label: const Text('Добавить еду')) : null,
    );
  }

  Widget _header(String title, String subtitle) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _dark)), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 14))])),
      Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: IconButton(onPressed: () => setState(() => tab = 4), icon: const Icon(Icons.person_outline))),
    ]),
  );

  Widget _today() => ListView(padding: const EdgeInsets.only(bottom: 110), children: [
    _header('Сегодня', '4 сентября · пятница'), _dateStrip(), const SizedBox(height: 12), _calorieHero(), const SizedBox(height: 12), _macroCard(), const SizedBox(height: 12), _quickStats(), const SizedBox(height: 18),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Дневник питания', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _dark))),
    const SizedBox(height: 8), ...meals.map(_mealCard)
  ]);

  Widget _dateStrip() => SizedBox(height: 72, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 20), scrollDirection: Axis.horizontal, itemCount: 7, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) {
    final active = i == 3;
    return Container(width: 55, decoration: BoxDecoration(color: active ? _green : Colors.white, borderRadius: BorderRadius.circular(17)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(['ПН','ВТ','СР','ЧТ','ПТ','СБ','ВС'][i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : _muted)), Text('${1 + i}', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: active ? Colors.white : _dark))]));
  }));

  Widget _calorieHero() {
    const goal = 1900;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(28)), child: Row(children: [
      SizedBox(width: 126, height: 126, child: Stack(alignment: Alignment.center, children: [SizedBox(width: 126, height: 126, child: CircularProgressIndicator(value: calories / goal, strokeWidth: 10, backgroundColor: Colors.white12, color: const Color(0xFF74D09E))), Column(mainAxisSize: MainAxisSize.min, children: [Text('$calories', style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800)), const Text('ккал съедено', style: TextStyle(color: Colors.white60, fontSize: 11))])])),
      const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Дневная цель', style: TextStyle(color: Colors.white60, fontSize: 13)), const SizedBox(height: 3), const Text('1900 ккал', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Text('${goal - calories}', style: const TextStyle(color: Color(0xFF74D09E), fontSize: 25, fontWeight: FontWeight.w800)), const Text('осталось сегодня', style: TextStyle(color: Colors.white60, fontSize: 12))]))
    ])));
  }

  Widget _macroCard() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Баланс макросов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)), const SizedBox(height: 14), Row(children: [_macro('Белки', protein, 170, _green), _macro('Жиры', fat, 60, const Color(0xFFE6A83D)), _macro('Углеводы', carbs, 180, const Color(0xFF6E8EDB))]), const SizedBox(height: 13), Row(children: [const Icon(Icons.eco_outlined, size: 19, color: _green), const SizedBox(width: 6), Text('Клетчатка $fiber / 30 г', style: const TextStyle(color: _muted, fontWeight: FontWeight.w600))])])));
  Widget _macro(String name, double value, double goal, Color color) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: _muted, fontSize: 12)), const SizedBox(height: 5), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (value / goal).clamp(0, 1), minHeight: 7, color: color, backgroundColor: _bg)), const SizedBox(height: 4), Text('${value.round()} / ${goal.round()} г', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))])));
  Widget _quickStats() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Expanded(child: _smallStat(Icons.water_drop_outlined, 'Вода', '1.5 л')), const SizedBox(width: 10), Expanded(child: _smallStat(Icons.monitor_weight_outlined, 'Вес', '$weight кг')), const SizedBox(width: 10), Expanded(child: _smallStat(Icons.directions_walk_outlined, 'Шаги', '2 840'))]));
  Widget _smallStat(IconData icon, String title, String value) => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _green, size: 21), const SizedBox(height: 7), Text(title, style: const TextStyle(color: _muted, fontSize: 11)), Text(value, style: const TextStyle(color: _dark, fontWeight: FontWeight.w800, fontSize: 15))]));

  Widget _diary() => ListView(padding: const EdgeInsets.only(bottom: 110), children: [_header('Питание', 'Сегодня · 4 сентября'), _calorieHero(), const SizedBox(height: 14), ...meals.map(_mealCard), Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 0), child: OutlinedButton.icon(onPressed: _addFood, icon: const Icon(Icons.add), label: const Text('Добавить приём пищи')))]);

  Widget _mealCard(_Meal meal) => Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 6), child: _card(Column(children: [Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.restaurant, color: _green)), const SizedBox(width: 12), Expanded(child: Text(meal.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark))), Text('${meal.kcal} ккал', style: const TextStyle(fontWeight: FontWeight.w700, color: _green))]), const Divider(height: 24), ...meal.items.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(f.name)), Text(f.amount, style: const TextStyle(color: _muted)), const SizedBox(width: 14), Text('${f.kcal} ккал', style: const TextStyle(fontWeight: FontWeight.w600))]))) ])));

  Widget _weight() => ListView(padding: const EdgeInsets.only(bottom: 30), children: [_header('Вес', 'Путь к цели'), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$weight кг', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _dark)), const Text('−5.8 кг от старта', style: TextStyle(color: _green, fontWeight: FontWeight.w700)), const SizedBox(height: 20), SizedBox(height: 170, child: CustomPaint(painter: _LinePainter())), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('110', style: TextStyle(color: _muted)), Text('100'), Text('90'), Text('85 кг', style: TextStyle(color: _green, fontWeight: FontWeight.w700))])]))), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Записать вес')))]);
  Widget _progress() => ListView(children: [_header('Прогресс', 'Твоя динамика'), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ты движешься к цели', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 12), const LinearProgressIndicator(value: .232, minHeight: 10), const SizedBox(height: 10), const Text('23% пути пройдено · осталось 19.2 кг', style: TextStyle(color: _muted))]))), const SizedBox(height: 12), _statBlock('Среднее питание', '$calories ккал', 'сегодня'), _statBlock('Белок', '${protein.round()} г', 'из 170 г'), _statBlock('Клетчатка', '${fiber.round()} г', 'из 30 г')]);
  Widget _statBlock(String title, String value, String note) => Padding(padding: const EdgeInsets.fromLTRB(20, 5, 20, 5), child: _card(Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _muted)), Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800))])), Text(note, style: const TextStyle(color: _muted))])));
  Widget _profile() => ListView(children: [_header('Профиль', 'Настройки FitLife'), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Моя цель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 10), const Text('Снижение веса', style: TextStyle(fontSize: 16)), const SizedBox(height: 4), const Text('110 кг → 85 кг', style: TextStyle(color: _muted))])))]);
  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x09000000), blurRadius: 18, offset: Offset(0, 5))]), child: child);
  void _addFood() => setState(() { calories += 120; protein += 10; fiber += 2; meals.add(const _Meal('Перекус', 120, [_FoodLine('Новый продукт', '100 г', 120)])); });
}

class _Meal { final String name; final int kcal; final List<_FoodLine> items; const _Meal(this.name, this.kcal, this.items); }
class _FoodLine { final String name; final String amount; final int kcal; const _FoodLine(this.name, this.amount, this.kcal); }
class _LinePainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) { final grid = Paint()..color = const Color(0xFFE3E9E4)..strokeWidth = 1; final line = Paint()..color = _green..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round; for (var i = 0; i < 5; i++) { final y = i * size.height / 4; canvas.drawLine(Offset(0, y), Offset(size.width, y), grid); } final path = Path()..moveTo(0, size.height*.1)..cubicTo(size.width*.2,size.height*.18,size.width*.25,size.height*.3,size.width*.4,size.height*.34)..cubicTo(size.width*.55,size.height*.4,size.width*.62,size.height*.55,size.width*.75,size.height*.62)..cubicTo(size.width*.86,size.height*.72,size.width*.92,size.height*.78,size.width,size.height*.9); canvas.drawPath(path, line); }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
