import 'package:flutter/material.dart';
import '../core/models/food.dart';
import '../core/nutrition/nutrition_calculator.dart';
import '../data/repositories/fitlife_storage.dart';

const _bg = Color(0xFFF7F9FB);
const _cardColor = Colors.white;
const _blue = Color(0xFF3F6F9F);
const _blueLight = Color(0xFFE8F0F7);
const _green = Color(0xFF5BAF78);
const _orange = Color(0xFFF3A33B);
const _pink = Color(0xFFD85A9B);
const _text = Color(0xFF20252A);
const _muted = Color(0xFF7B858E);

class FitLifeApp extends StatelessWidget {
  const FitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(seedColor: _blue),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _text),
          bodyMedium: TextStyle(color: _text),
          titleLarge: TextStyle(color: _text, fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(color: _text, fontWeight: FontWeight.w700),
        ),
      ),
      home: const FitLifeShell(),
    );
  }
}

class FitLifeShell extends StatefulWidget {
  const FitLifeShell({super.key});

  @override
  State<FitLifeShell> createState() => _FitLifeShellState();
}

class _FitLifeShellState extends State<FitLifeShell> {
  final FitLifeStorage storage = const FitLifeStorage();
  int tab = 0;
  DateTime selectedDay = DateTime.now();
  double weight = 92.4;
  double startWeight = 92.4;
  double goalWeight = 85;
  int age = 35;
  int height = 178;
  String sex = 'Мужской';
  double activity = 1.45;
  int water = 0;
  final List<FoodEntry> meals = [];
  final List<WeightEntry> weights = [];
  bool loaded = false;

  NutritionGoals get goals => const NutritionCalculator().calculate(
        weight: weight,
        height: height,
        age: age,
        sex: sex,
        activity: activity,
      );

  List<FoodEntry> get dayMeals => meals.where((e) => e.dateKey == _key(selectedDay)).toList();
  int get kcal => dayMeals.fold(0, (s, e) => s + e.kcal);
  double get protein => dayMeals.fold(0.0, (s, e) => s + e.protein);
  double get fat => dayMeals.fold(0.0, (s, e) => s + e.fat);
  double get carbs => dayMeals.fold(0.0, (s, e) => s + e.carbs);
  double get fiber => dayMeals.fold(0.0, (s, e) => s + e.fiber);
  double get progress {
    final total = startWeight - goalWeight;
    if (total <= 0) return 0;
    return ((startWeight - weight) / total).clamp(0.0, 1.0).toDouble();
  }

  static String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  bool get isToday => _key(selectedDay) == _key(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final savedWeight = await storage.readDouble('weight');
    final savedStart = await storage.readDouble('startWeight');
    final savedGoal = await storage.readDouble('goalWeight');
    final savedAge = await storage.readInt('age');
    final savedHeight = await storage.readInt('height');
    final savedWater = await storage.readInt('water');
    final savedSex = await storage.readString('sex');
    final foodRows = await storage.readList('meals');
    final weightRows = await storage.readList('weights');
    if (!mounted) return;
    setState(() {
      if (savedWeight != null) weight = savedWeight;
      if (savedStart != null) startWeight = savedStart;
      if (savedGoal != null) goalWeight = savedGoal;
      if (savedAge != null) age = savedAge;
      if (savedHeight != null) height = savedHeight;
      if (savedWater != null) water = savedWater;
      if (savedSex != null) sex = savedSex;
      meals..clear()..addAll(foodRows.map(FoodEntry.fromJson).whereType<FoodEntry>());
      weights..clear()..addAll(weightRows.map(WeightEntry.fromJson).whereType<WeightEntry>());
      loaded = true;
    });
  }

  Future<void> _save() async {
    await storage.writeDouble('weight', weight);
    await storage.writeDouble('startWeight', startWeight);
    await storage.writeDouble('goalWeight', goalWeight);
    await storage.writeInt('age', age);
    await storage.writeInt('height', height);
    await storage.writeInt('water', water);
    await storage.writeString('sex', sex);
    await storage.writeList('meals', meals.map((e) => e.toJson()).toList());
    await storage.writeList('weights', weights.map((e) => e.toJson()).toList());
  }

  void _changed(VoidCallback action) {
    setState(action);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = <Widget>[_home(), _nutrition(), _weight(), _statistics(), _profile()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: _blueLight,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Сегодня'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Питание'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight), label: 'Вес'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Статистика'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Widget _topBar({bool back = false, String? title}) {
    return Row(children: [
      IconButton(icon: Icon(back ? Icons.arrow_back : Icons.menu), onPressed: back ? () => setState(() => tab = 0) : _openMenu),
      Expanded(child: Text(title ?? 'Сегодня', textAlign: back ? TextAlign.left : TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700))),
      IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
    ]);
  }

  Widget _home() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _topBar(),
        _dateStrip(),
        const SizedBox(height: 12),
        _summaryCard(),
        const SizedBox(height: 12),
        _checkInCard(),
        const SizedBox(height: 12),
        if (dayMeals.isEmpty) _emptyDiaryCard() else ...dayMeals.map(_mealCard),
        const SizedBox(height: 110),
      ],
    );
  }

  Widget _dateStrip() {
    final base = selectedDay.subtract(const Duration(days: 3));
    const week = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = base.add(Duration(days: i));
          final active = _key(d) == _key(selectedDay);
          return GestureDetector(
            onTap: () => setState(() => selectedDay = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: active ? _blueLight : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? _blue : const Color(0xFFE2E6EA), width: active ? 1.5 : 1)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(week[d.weekday - 1], style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? _blue : _muted)), const SizedBox(height: 3), Text('${d.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: active ? _blue : _text))]),
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard() {
    final left = (goals.calories - kcal).clamp(0, goals.calories);
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.local_fire_department, color: _orange), const SizedBox(width: 8), const Text('Калории', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: (kcal / goals.calories).clamp(0.0, 1.0), minHeight: 8, backgroundColor: _blueLight, color: _orange)),
      const SizedBox(height: 12),
      Row(children: [_metric('Еда', '$kcal', 'ккал'), _metric('Упражнение', '0', 'ккал'), _metric('Осталось', '$left', 'ккал', strong: true)]),
      const SizedBox(height: 16),
      Row(children: [const Icon(Icons.donut_small, color: _pink), const SizedBox(width: 8), const Text('Макросы', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 12),
      Row(children: [_macro('Углеводы', carbs, goals.carbs, _blue), _macro('Белки', protein, goals.protein, _green), _macro('Жиры', fat, goals.fat, _orange)]),
      const SizedBox(height: 12),
      Row(children: [const Icon(Icons.grass_outlined, size: 19, color: _green), const SizedBox(width: 7), Text('Клетчатка  ${fiber.toStringAsFixed(1)} / 30 г', style: const TextStyle(color: _muted))]),
    ]));
  }

  Widget _metric(String title, String value, String unit, {bool strong = false}) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _muted)), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: strong ? 25 : 22, fontWeight: FontWeight.w700)), Text(unit, style: const TextStyle(fontSize: 12, color: _muted))]));

  Widget _macro(String title, double value, int target, Color color) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _muted, fontSize: 13)), const SizedBox(height: 5), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (value / target).clamp(0.0, 1.0), minHeight: 6, backgroundColor: _blueLight, color: color)), const SizedBox(height: 5), Text('${value.round()} / $target г', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))])));

  Widget _checkInCard() => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.checklist), const SizedBox(width: 9), const Text('Ежедневный чек-ин', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))]),
    const SizedBox(height: 12),
    const Text('•  Посмотрите вчерашнюю аналитику и баланс калорий', style: TextStyle(fontSize: 16, height: 1.35, color: _blue)),
    const SizedBox(height: 8),
    const Text('•  Запланируйте, что вы будете есть на завтрак, обед и ужин', style: TextStyle(fontSize: 16, height: 1.35)),
    const SizedBox(height: 14),
    Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => tab = 1), icon: const Icon(Icons.restaurant_menu), label: const Text('План питания'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () => _changed(() => water += 250), icon: const Icon(Icons.water_drop_outlined), label: const Text('+250 мл')))]),
  ]));

  Widget _emptyDiaryCard() => _card(child: Column(children: [const Icon(Icons.restaurant_outlined, size: 46, color: _muted), const SizedBox(height: 8), Text(isToday ? 'Что вы сегодня съели?' : 'Записей за этот день нет', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 5), const Text('Добавляйте продукты — FitLife посчитает калории, БЖУ и клетчатку.', textAlign: TextAlign.center, style: TextStyle(color: _muted)), const SizedBox(height: 14), FilledButton.icon(onPressed: _addFood, icon: const Icon(Icons.add), label: const Text('Добавить продукт'))]));

  Widget _mealCard(FoodEntry entry) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.food.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${entry.grams.round()} г', style: const TextStyle(color: _muted)), const SizedBox(height: 12), Row(children: [_mealMetric('Калории', '${entry.kcal}'), _mealMetric('Углеводы', '${entry.carbs.round()} г'), _mealMetric('Белки', '${entry.protein.round()} г'), _mealMetric('Жиры', '${entry.fat.round()} г')]), Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(onPressed: () => _editFood(entry), icon: const Icon(Icons.edit_outlined)), IconButton(onPressed: () => _changed(() => meals.remove(entry)), icon: const Icon(Icons.delete_outline))])]));

  Widget _mealMetric(String title, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, color: _muted)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));

  Widget _nutrition() => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    _topBar(title: 'Питание'), _dateStrip(), const SizedBox(height: 12), _summaryCard(), const SizedBox(height: 12),
    Row(children: [const Text('Дневник питания', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), const Spacer(), Text('${dayMeals.length} записей', style: const TextStyle(color: _muted))]),
    const SizedBox(height: 10), if (dayMeals.isEmpty) _emptyDiaryCard() else ...dayMeals.map(_mealCard), const SizedBox(height: 12),
    FilledButton.icon(onPressed: _addFood, icon: const Icon(Icons.add), label: const Text('Добавить продукт')), const SizedBox(height: 110),
  ]);

  Future<void> _addFood() async {
    final food = await showModalBottomSheet<Food>(context: context, showDragHandle: true, isScrollControlled: true, builder: (context) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [const Text('Добавить продукт', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Text('Выберите продукт из базы FitLife', style: TextStyle(color: _muted)), const SizedBox(height: 10), ...defaultFoods.map((f) => ListTile(leading: const CircleAvatar(child: Icon(Icons.restaurant)), title: Text(f.name), subtitle: Text('${f.kcal} ккал • Б ${f.protein} г • Ж ${f.fat} г • У ${f.carbs} г'), onTap: () => Navigator.pop(context, f)))])));
    if (food == null || !mounted) return;
    final controller = TextEditingController(text: '100');
    final grams = await showDialog<double>(context: context, builder: (context) => AlertDialog(title: Text(food.name), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Количество, г')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '.'))), child: const Text('Добавить'))]));
    controller.dispose();
    if (grams == null || grams <= 0 || !mounted) return;
    _changed(() => meals.add(FoodEntry.fromFood(food, grams, _key(selectedDay))));
  }

  Future<void> _editFood(FoodEntry entry) async {
    final controller = TextEditingController(text: entry.grams.toStringAsFixed(0));
    final grams = await showDialog<double>(context: context, builder: (context) => AlertDialog(title: Text(entry.food.name), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Количество, г')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '.'))), child: const Text('Сохранить'))]));
    controller.dispose();
    if (grams == null || grams <= 0 || !mounted) return;
    _changed(() { final index = meals.indexOf(entry); if (index >= 0) meals[index] = entry.copyWith(grams: grams); });
  }

  Widget _weight() => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    _topBar(title: 'Трекер веса'),
    Row(children: [Expanded(child: _infoCard('Текущий вес', '${weight.toStringAsFixed(1)} кг', Icons.monitor_weight_outlined)), const SizedBox(width: 10), Expanded(child: _infoCard('Целевой вес', '${goalWeight.toStringAsFixed(1)} кг', Icons.flag_outlined))]),
    const SizedBox(height: 12),
    _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text('Прогресс', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), const Spacer(), Text('${(progress * 100).round()}%', style: const TextStyle(color: _blue, fontWeight: FontWeight.w700))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: _blueLight, color: _green)), const SizedBox(height: 12), Text('Осталось сбросить ${((weight - goalWeight).clamp(0.0, 999.0)).toStringAsFixed(1)} кг', style: const TextStyle(color: _muted))])),
    const SizedBox(height: 12),
    _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text('График веса', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), const Spacer(), _chartFilter('7 д.'), _chartFilter('30 д.'), _chartFilter('Всё')]), const SizedBox(height: 12), SizedBox(height: 220, child: WeightChart(entries: weights.where((e) => e.dateTime != null).toList(), goal: goalWeight))])),
    const SizedBox(height: 12),
    Row(children: [const Text('История веса', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), const Spacer(), IconButton(onPressed: _addWeight, icon: const Icon(Icons.add_circle_outline, color: _blue))]),
    if (weights.isEmpty) _card(child: const Center(child: Text('Пока нет записей. Добавьте первый вес.', style: TextStyle(color: _muted)))) else ...weights.reversed.map(_weightRow), const SizedBox(height: 110),
  ]);

  Widget _infoCard(String title, String value, IconData icon) => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _blue), const SizedBox(height: 10), Text(title, style: const TextStyle(color: _muted)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700))]));
  Widget _chartFilter(String label) => Padding(padding: const EdgeInsets.only(left: 5), child: Text(label, style: const TextStyle(fontSize: 11, color: _blue)));
  Widget _weightRow(WeightEntry e) => _card(child: Row(children: [const Icon(Icons.scale_outlined, color: _blue), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${e.weight.toStringAsFixed(1)} кг', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), Text(e.date, style: const TextStyle(color: _muted))])), if (e.weight < startWeight) const Icon(Icons.trending_down, color: _green)]));

  Future<void> _addWeight() async {
    final controller = TextEditingController(text: weight.toStringAsFixed(1));
    final value = await showDialog<double>(context: context, builder: (context) => AlertDialog(title: const Text('Записать вес'), content: TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Вес, кг')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '.'))), child: const Text('Сохранить'))]));
    controller.dispose();
    if (value == null || value <= 0 || !mounted) return;
    final now = DateTime.now();
    _changed(() { if (weights.isEmpty) startWeight = value; weight = value; weights.add(WeightEntry(value, '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}', now)); });
  }

  Widget _statistics() => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    _topBar(title: 'Статистика'),
    _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Результат', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 16), Row(children: [_statTile('Сброшено', '${(startWeight - weight).toStringAsFixed(1)} кг', _green), _statTile('До цели', '${((weight - goalWeight).clamp(0.0, 999.0)).toStringAsFixed(1)} кг', _blue)]), const SizedBox(height: 14), Row(children: [_statTile('Сегодня', '$kcal ккал', _orange), _statTile('Вода', '$water мл', _blue)])])),
    const SizedBox(height: 12),
    _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Питание сегодня', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 12), _progressLine('Калории', kcal, goals.calories, _orange), _progressLine('Белки', protein, goals.protein, _green), _progressLine('Жиры', fat, goals.fat, _orange), _progressLine('Углеводы', carbs, goals.carbs, _blue), _progressLine('Клетчатка', fiber, 30, _green)])),
    const SizedBox(height: 12),
    _card(child: Text('Записей веса: ${weights.length}', style: const TextStyle(fontSize: 16))), const SizedBox(height: 110),
  ]);

  Widget _statTile(String title, String value, Color color) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _muted)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: color))])));
  Widget _progressLine(String title, double value, num target, Color color) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(title), const Spacer(), Text('${value.round()} / ${target.round()}')]), const SizedBox(height: 5), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (value / target).clamp(0.0, 1.0), minHeight: 7, backgroundColor: _blueLight, color: color))]));

  Widget _profile() => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    _topBar(title: 'Профиль'),
    _card(child: Column(children: [const CircleAvatar(radius: 38, backgroundColor: _blueLight, child: Icon(Icons.person, size: 44, color: _blue)), const SizedBox(height: 10), const Text('Мой профиль', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 14), _profileRow('Пол', sex), _profileRow('Возраст', '$age лет'), _profileRow('Рост', '$height см'), _profileRow('Вес', '${weight.toStringAsFixed(1)} кг'), _profileRow('Цель', '${goalWeight.toStringAsFixed(1)} кг'), _profileRow('Цель калорий', '${goals.calories} ккал'), const SizedBox(height: 10), FilledButton.icon(onPressed: _editProfile, icon: const Icon(Icons.edit), label: const Text('Изменить профиль'))])),
    const SizedBox(height: 12),
    _card(child: Column(children: [ListTile(leading: const Icon(Icons.flag_outlined, color: _blue), title: const Text('Ежедневные цели'), subtitle: Text('${goals.calories} ккал • Б ${goals.protein} г • Ж ${goals.fat} г • У ${goals.carbs} г'), onTap: _showGoals), ListTile(leading: const Icon(Icons.groups_outlined, color: _blue), title: const Text('Группы'), subtitle: const Text('Совместное отслеживание'), onTap: _showGroups)])),
    const SizedBox(height: 110),
  ]);

  Widget _profileRow(String title, String value) => ListTile(title: Text(title), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)));

  Future<void> _editProfile() async {
    final ageC = TextEditingController(text: '$age');
    final heightC = TextEditingController(text: '$height');
    final weightC = TextEditingController(text: weight.toStringAsFixed(1));
    final goalC = TextEditingController(text: goalWeight.toStringAsFixed(1));
    final result = await showDialog<List<double>>(context: context, builder: (context) => AlertDialog(title: const Text('Профиль'), content: SingleChildScrollView(child: Column(children: [TextField(controller: ageC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Возраст')), TextField(controller: heightC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Рост, см')), TextField(controller: weightC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Вес, кг')), TextField(controller: goalC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Цель, кг'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, [double.tryParse(ageC.text) ?? age.toDouble(), double.tryParse(heightC.text) ?? height.toDouble(), double.tryParse(weightC.text.replaceAll(',', '.')) ?? weight, double.tryParse(goalC.text.replaceAll(',', '.')) ?? goalWeight]), child: const Text('Сохранить'))]));
    ageC.dispose(); heightC.dispose(); weightC.dispose(); goalC.dispose();
    if (result == null || !mounted) return;
    _changed(() { age = result[0].round(); height = result[1].round(); weight = result[2]; goalWeight = result[3]; });
  }

  Widget _card({required Widget child}) => Card(color: _cardColor, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE8ECF0))), child: Padding(padding: const EdgeInsets.all(17), child: child));

  void _openMenu() {
    showModalBottomSheet(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('FitLife', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)), const SizedBox(height: 10), ListTile(leading: const Icon(Icons.groups_outlined), title: const Text('Группы'), onTap: () { Navigator.pop(context); _showGroups(); }), ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Ежедневные цели'), onTap: () { Navigator.pop(context); _showGoals(); }), ListTile(leading: const Icon(Icons.monitor_weight_outlined), title: const Text('Трекер веса'), onTap: () { Navigator.pop(context); setState(() => tab = 2); }), ListTile(leading: const Icon(Icons.person_outline), title: const Text('Профиль'), onTap: () { Navigator.pop(context); setState(() => tab = 4); })]))));
  }

  void _showGroups() {
    showModalBottomSheet(context: context, showDragHandle: true, isScrollControlled: true, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.groups_outlined, size: 64, color: _blue), const SizedBox(height: 12), const Text('Вместе лучше', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)), const SizedBox(height: 10), const Text('Следите за калориями и приёмами пищи всей группой. Делитесь прогрессом и поддерживайте друг друга.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: _muted, height: 1.45)), const SizedBox(height: 20), FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Создать группу')), const SizedBox(height: 8), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.group_add), label: const Text('Присоединиться к группе'))])));
  }

  void _showGoals() {
    showModalBottomSheet(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ежедневные цели', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)), const SizedBox(height: 20), _goalRow('Калории', '${goals.calories} ккал'), _goalRow('Белки', '${goals.protein} г'), _goalRow('Жиры', '${goals.fat} г'), _goalRow('Углеводы', '${goals.carbs} г'), _goalRow('Клетчатка', '30 г'), const SizedBox(height: 15)]))));
  }

  Widget _goalRow(String title, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Text(title, style: const TextStyle(fontSize: 17)), const Spacer(), Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _blue))]));
}

class FoodEntry {
  final Food food;
  final double grams;
  final String dateKey;
  const FoodEntry(this.food, this.grams, this.dateKey);

  factory FoodEntry.fromFood(Food food, double grams, String dateKey) => FoodEntry(food, grams, dateKey);

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    final rawFood = json['food'];
    if (rawFood is! Map) return FoodEntry(defaultFoods.first, 0, _todayKey());
    final f = Food.fromJson(Map<String, dynamic>.from(rawFood));
    return FoodEntry(f, (json['grams'] as num?)?.toDouble() ?? 0, json['dateKey'] as String? ?? _todayKey());
  }

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  FoodEntry copyWith({double? grams}) => FoodEntry(food, grams ?? this.grams, dateKey);
  Map<String, dynamic> toJson() => {'food': food.toJson(), 'grams': grams, 'dateKey': dateKey};
  int get kcal => (food.kcal * grams / 100).round();
  double get protein => food.protein * grams / 100;
  double get fat => food.fat * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fiber => food.fiber * grams / 100;
}

class WeightEntry {
  final double weight;
  final String date;
  final DateTime? dateTime;
  const WeightEntry(this.weight, this.date, [this.dateTime]);

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry((json['weight'] as num?)?.toDouble() ?? 0, json['date'] as String? ?? '', json['dateTime'] == null ? null : DateTime.tryParse(json['dateTime'] as String));
  Map<String, dynamic> toJson() => {'weight': weight, 'date': date, 'dateTime': dateTime?.toIso8601String()};
}

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double goal;
  const WeightChart({super.key, required this.entries, required this.goal});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _WeightPainter(entries, goal), child: const SizedBox.expand());
}

class _WeightPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final double goal;
  _WeightPainter(this.entries, this.goal);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFE7EBEF)..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (entries.isEmpty) {
      final tp = TextPainter(text: const TextSpan(text: 'Добавьте записи веса', style: TextStyle(color: _muted, fontSize: 15)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2 - 10));
      return;
    }
    final values = entries.map((e) => e.weight).toList()..add(goal);
    var minV = values.reduce((a, b) => a < b ? a : b) - 2;
    var maxV = values.reduce((a, b) => a > b ? a : b) + 2;
    if (maxV - minV < 4) maxV = minV + 4;
    final goalPaint = Paint()..color = _green.withOpacity(.75)..strokeWidth = 2;
    final goalY = size.height - ((goal - minV) / (maxV - minV)).clamp(0.0, 1.0) * size.height;
    canvas.drawLine(Offset(0, goalY), Offset(size.width, goalY), goalPaint);
    if (entries.length == 1) {
      final x = size.width / 2;
      final y = size.height - ((entries.first.weight - minV) / (maxV - minV)).clamp(0.0, 1.0) * size.height;
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = _blue);
      return;
    }
    final line = Paint()..color = _blue..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final x = size.width * i / (entries.length - 1);
      final y = size.height - ((entries[i].weight - minV) / (maxV - minV)).clamp(0.0, 1.0) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = _blue);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _WeightPainter oldDelegate) => oldDelegate.entries != entries || oldDelegate.goal != goal;
}

const defaultFoods = <Food>[
  Food(name: 'Яйцо куриное', kcal: 143, protein: 12.6, fat: 9.5, carbs: 0.7, fiber: 0),
  Food(name: 'Куриная грудка', kcal: 165, protein: 31, fat: 3.6, carbs: 0, fiber: 0),
  Food(name: 'Овсянка', kcal: 370, protein: 13, fat: 6.5, carbs: 62, fiber: 10.1),
  Food(name: 'Творог 5%', kcal: 121, protein: 17.2, fat: 5, carbs: 1.8, fiber: 0),
  Food(name: 'Рис варёный', kcal: 130, protein: 2.7, fat: 0.3, carbs: 28.2, fiber: 0.4),
  Food(name: 'Яблоко', kcal: 52, protein: 0.3, fat: 0.2, carbs: 13.8, fiber: 2.4),
  Food(name: 'Помидор', kcal: 18, protein: 0.9, fat: 0.2, carbs: 3.9, fiber: 1.2),
  Food(name: 'Перец красный', kcal: 31, protein: 1, fat: 0.3, carbs: 6, fiber: 2.1),
  Food(name: 'Йогурт греческий', kcal: 73, protein: 9.9, fat: 2, carbs: 3.9, fiber: 0),
  Food(name: 'Ветчина из индейки', kcal: 84, protein: 18, fat: 2, carbs: 2, fiber: 0),
  Food(name: 'Картофель отварной', kcal: 87, protein: 1.9, fat: 0.1, carbs: 20.1, fiber: 1.8),
  Food(name: 'Клубника', kcal: 32, protein: 0.7, fat: 0.3, carbs: 7.7, fiber: 2),
  Food(name: 'Черника', kcal: 57, protein: 0.7, fat: 0.3, carbs: 14.5, fiber: 2.4),
  Food(name: 'Грибы шампиньоны', kcal: 22, protein: 3.1, fat: 0.3, carbs: 3.3, fiber: 1),
];
