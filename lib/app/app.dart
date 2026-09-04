import 'package:flutter/material.dart';

import '../core/models/food.dart';
import '../core/nutrition/nutrition_calculator.dart';
import '../data/repositories/fitlife_storage.dart';

const bg = Color(0xFFF7F9FB);
const blue = Color(0xFF3F6F9F);
const blueLight = Color(0xFFE8F0F7);
const green = Color(0xFF5BAF78);
const orange = Color(0xFFF3A33B);
const pink = Color(0xFFD85A9B);
const muted = Color(0xFF7B858E);

class FitLifeApp extends StatelessWidget {
  const FitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
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
  final FitLifeStorage store = const FitLifeStorage();

  int tab = 0;
  DateTime day = DateTime.now();
  bool loaded = false;

  double weight = 104.2;
  double startWeight = 110;
  double goalWeight = 85;
  int age = 36;
  int height = 175;
  int water = 0;
  String sex = 'Мужской';
  double activity = 1.2;

  final List<FoodEntry> meals = <FoodEntry>[];
  final List<WeightEntry> weights = <WeightEntry>[];

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<FoodEntry> get todayMeals =>
      meals.where((e) => e.dateKey == dateKey(day)).toList();

  int get calories => todayMeals.fold(0, (sum, e) => sum + e.kcal);
  double get protein => todayMeals.fold(0, (sum, e) => sum + e.protein);
  double get fat => todayMeals.fold(0, (sum, e) => sum + e.fat);
  double get carbs => todayMeals.fold(0, (sum, e) => sum + e.carbs);
  double get fiber => todayMeals.fold(0, (sum, e) => sum + e.fiber);

  NutritionGoals get goals => const NutritionCalculator().calculate(
        weight: weight,
        height: height,
        age: age,
        sex: sex,
        activity: activity,
      );

  double get weightProgress {
    final total = startWeight - goalWeight;
    if (total <= 0) return 0;
    return ((startWeight - weight) / total).clamp(0.0, 1.0).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final savedWeight = await store.readDouble('weight');
    final savedStart = await store.readDouble('startWeight');
    final savedGoal = await store.readDouble('goalWeight');
    final savedAge = await store.readInt('age');
    final savedHeight = await store.readInt('height');
    final savedWater = await store.readInt('water');
    final savedSex = await store.readString('sex');
    final savedMeals = await store.readList('meals');
    final savedWeights = await store.readList('weights');

    if (!mounted) return;
    setState(() {
      if (savedWeight != null) weight = savedWeight;
      if (savedStart != null) startWeight = savedStart;
      if (savedGoal != null) goalWeight = savedGoal;
      if (savedAge != null) age = savedAge;
      if (savedHeight != null) height = savedHeight;
      if (savedWater != null) water = savedWater;
      if (savedSex != null) sex = savedSex;
      meals
        ..clear()
        ..addAll(savedMeals.map(FoodEntry.fromJson));
      weights
        ..clear()
        ..addAll(savedWeights.map(WeightEntry.fromJson));
      loaded = true;
    });
  }

  Future<void> _save() async {
    await store.writeDouble('weight', weight);
    await store.writeDouble('startWeight', startWeight);
    await store.writeDouble('goalWeight', goalWeight);
    await store.writeInt('age', age);
    await store.writeInt('height', height);
    await store.writeInt('water', water);
    await store.writeString('sex', sex);
    await store.writeList('meals', meals.map((e) => e.toJson()).toList());
    await store.writeList('weights', weights.map((e) => e.toJson()).toList());
  }

  void change(VoidCallback action) {
    setState(action);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <Widget>[
      _homePage(),
      _nutritionPage(),
      _weightPage(),
      _statsPage(),
      _profilePage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        indicatorColor: blueLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Сегодня',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Питание',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Вес',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  Widget _topBar(String title) {
    return Row(
      children: [
        IconButton(
          onPressed: _openMenu,
          icon: const Icon(Icons.menu),
          tooltip: 'Меню',
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => tab = 4),
          icon: const Icon(Icons.person_outline),
          tooltip: 'Профиль',
        ),
      ],
    );
  }

  Widget _days() {
    final base = day.subtract(const Duration(days: 3));
    const names = <String>['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = base.add(Duration(days: index));
          final active = dateKey(date) == dateKey(day);
          return GestureDetector(
            onTap: () => setState(() => day = date),
            child: Container(
              width: 58,
              decoration: BoxDecoration(
                color: active ? blueLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? blue : const Color(0xFFE2E6EA),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    names[date.weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? blue : muted,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: active ? blue : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _summary() {
    final left = (goals.calories - calories).clamp(0, goals.calories);
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: orange),
              SizedBox(width: 8),
              Text(
                'Калории',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (calories / goals.calories).clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            backgroundColor: blueLight,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric('Еда', '$calories'),
              _metric('Упражнение', '0'),
              _metric('Осталось', '$left', strong: true),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.donut_small, color: pink),
              SizedBox(width: 8),
              Text(
                'Макросы',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _macro('Углеводы', carbs, goals.carbs),
              _macro('Белки', protein, goals.protein),
              _macro('Жиры', fat, goals.fat),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '🌿  Клетчатка  ${fiber.toStringAsFixed(1)} / 30 г',
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, {bool strong = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 25 : 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text('ккал', style: TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    );
  }

  Widget _macro(String label, double value, int target) {
    final progress = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: muted)),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 6,
              backgroundColor: blueLight,
            ),
            Text(
              '${value.round()} / $target г',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkIn() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist),
              SizedBox(width: 8),
              Text(
                'Ежедневный чек-ин',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '• Посмотрите вчерашнюю аналитику и баланс калорий',
            style: TextStyle(color: blue, fontSize: 15),
          ),
          const SizedBox(height: 7),
          const Text(
            '• Запланируйте завтрак, обед и ужин',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => tab = 1),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('План питания'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => change(() => water += 250),
                  icon: const Icon(Icons.water_drop_outlined),
                  label: const Text('+250 мл'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyDiary() {
    final isToday = dateKey(day) == dateKey(DateTime.now());
    return _card(
      Column(
        children: [
          const Icon(Icons.restaurant_outlined, size: 44, color: muted),
          const SizedBox(height: 7),
          Text(
            isToday ? 'Что вы сегодня съели?' : 'Записей за этот день нет',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          const Text(
            'Добавляйте продукты — FitLife посчитает калории, БЖУ и клетчатку.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _addFood,
            icon: const Icon(Icons.add),
            label: const Text('Добавить продукт'),
          ),
        ],
      ),
    );
  }

  Widget _mealCard(FoodEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.food.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              '${entry.grams.round()} г',
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _mealMetric('Ккал', '${entry.kcal}'),
                _mealMetric('У', '${entry.carbs.round()} г'),
                _mealMetric('Б', '${entry.protein.round()} г'),
                _mealMetric('Ж', '${entry.fat.round()} г'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _editFood(entry),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Изменить',
                ),
                IconButton(
                  onPressed: () => change(() => meals.remove(entry)),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Удалить',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _homePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _topBar('Сегодня'),
        _days(),
        const SizedBox(height: 12),
        _summary(),
        const SizedBox(height: 12),
        _checkIn(),
        const SizedBox(height: 14),
        const Text(
          'Дневник питания',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (todayMeals.isEmpty) _emptyDiary() else ...todayMeals.map(_mealCard),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _nutritionPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _topBar('Питание'),
        _days(),
        const SizedBox(height: 12),
        _summary(),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Дневник питания',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '${todayMeals.length} записей',
              style: const TextStyle(color: muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (todayMeals.isEmpty) _emptyDiary() else ...todayMeals.map(_mealCard),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _addFood,
          icon: const Icon(Icons.add),
          label: const Text('Добавить продукт'),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _addFood() async {
    final food = await showModalBottomSheet<Food>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Добавить продукт',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...defaultFoods.map(
                (item) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.kcal} ккал • Б ${item.protein} • Ж ${item.fat} • У ${item.carbs}',
                  ),
                  onTap: () => Navigator.pop(sheetContext, item),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (food == null || !mounted) return;
    final controller = TextEditingController(text: '100');
    final grams = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(food.name),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Количество, г'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                double.tryParse(controller.text.replaceAll(',', '.')),
              ),
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (grams == null || grams <= 0 || !mounted) return;
    change(() => meals.add(FoodEntry.fromFood(food, grams, dateKey(day))));
  }

  Future<void> _editFood(FoodEntry entry) async {
    final controller = TextEditingController(text: entry.grams.toStringAsFixed(0));
    final grams = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(entry.food.name),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Количество, г'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                double.tryParse(controller.text.replaceAll(',', '.')),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (grams == null || grams <= 0 || !mounted) return;
    change(() {
      final index = meals.indexOf(entry);
      if (index >= 0) meals[index] = entry.copyWith(grams: grams);
    });
  }

  Widget _weightPage() {
    final chartData = List<WeightEntry>.from(weights);
    if (chartData.isEmpty) {
      chartData.add(WeightEntry(startWeight, 'Старт', DateTime.now()));
      if (weight != startWeight) {
        chartData.add(WeightEntry(weight, 'Сейчас', DateTime.now()));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _topBar('Трекер веса'),
        Row(
          children: [
            Expanded(child: _infoCard('Текущий вес', '${weight.toStringAsFixed(1)} кг')),
            const SizedBox(width: 10),
            Expanded(child: _infoCard('Целевой вес', '${goalWeight.toStringAsFixed(1)} кг')),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Прогресс',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${(weightProgress * 100).round()}%',
                    style: const TextStyle(color: blue, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: weightProgress,
                minHeight: 10,
                backgroundColor: blueLight,
              ),
              const SizedBox(height: 10),
              Text(
                'Осталось сбросить ${((weight - goalWeight).clamp(0.0, 999.0)).toStringAsFixed(1)} кг',
                style: const TextStyle(color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'График веса',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 230,
                child: WeightChart(entries: chartData, goal: goalWeight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'История веса',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              onPressed: _addWeight,
              icon: const Icon(Icons.add_circle_outline, color: blue),
              tooltip: 'Добавить вес',
            ),
          ],
        ),
        if (weights.isEmpty)
          _card(const Text('Пока нет записей. Добавьте первый вес.'))
        else
          ...weights.reversed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _card(
                Row(
                  children: [
                    const Icon(Icons.scale_outlined, color: blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.weight.toStringAsFixed(1)} кг',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            entry.date,
                            style: const TextStyle(color: muted),
                          ),
                        ],
                      ),
                    ),
                    if (entry.weight < startWeight)
                      const Icon(Icons.trending_down, color: green),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _infoCard(String title, String value) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.monitor_weight_outlined, color: blue),
          Text(title, style: const TextStyle(color: muted)),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<void> _addWeight() async {
    final controller = TextEditingController(text: weight.toStringAsFixed(1));
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Записать вес'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Вес, кг'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                double.tryParse(controller.text.replaceAll(',', '.')),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (value == null || value <= 0 || !mounted) return;
    change(() {
      weight = value;
      weights.add(WeightEntry(value, 'Запись', DateTime.now()));
    });
  }

  Widget _statsPage() {
    final loss = startWeight - weight;
    final averageCalories = meals.isEmpty ? 0 : calories;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _topBar('Статистика'),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Прогресс похудения',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _statValue('Сброшено', '${loss.toStringAsFixed(1)} кг'),
                  _statValue('До цели', '${(weight - goalWeight).toStringAsFixed(1)} кг'),
                  _statValue('Вес', '${weight.toStringAsFixed(1)} кг'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Сегодня',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _statRow('Калории', '$averageCalories / ${goals.calories} ккал'),
              _statRow('Белки', '${protein.round()} / ${goals.protein} г'),
              _statRow('Жиры', '${fat.round()} / ${goals.fat} г'),
              _statRow('Углеводы', '${carbs.round()} / ${goals.carbs} г'),
              _statRow('Клетчатка', '${fiber.toStringAsFixed(1)} / 30 г'),
              _statRow('Вода', '$water мл'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Записей',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text('Продуктов записано: ${meals.length}'),
              Text('Измерений веса: ${weights.length}'),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _statValue(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _statRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _topBar('Профиль'),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Мои данные',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _profileRow('Возраст', '$age лет'),
              _profileRow('Рост', '$height см'),
              _profileRow('Текущий вес', '${weight.toStringAsFixed(1)} кг'),
              _profileRow('Стартовый вес', '${startWeight.toStringAsFixed(1)} кг'),
              _profileRow('Цель', '${goalWeight.toStringAsFixed(1)} кг'),
              _profileRow('Пол', sex),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Изменить данные'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Дневная цель',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text('${goals.calories} ккал'),
              Text('Белки: ${goals.protein} г'),
              Text('Жиры: ${goals.fat} г'),
              Text('Углеводы: ${goals.carbs} г'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Row(
            children: [
              const Icon(Icons.water_drop_outlined, color: blue),
              const SizedBox(width: 10),
              Expanded(child: Text('Вода сегодня: $water мл')),
              IconButton(
                onPressed: () => change(() => water += 250),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _profileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _editProfile() async {
    final ageController = TextEditingController(text: '$age');
    final heightController = TextEditingController(text: '$height');
    final weightController = TextEditingController(text: weight.toStringAsFixed(1));
    final startController = TextEditingController(text: startWeight.toStringAsFixed(1));
    final goalController = TextEditingController(text: goalWeight.toStringAsFixed(1));
    String selectedSex = sex;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Мои данные'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Возраст'),
                    ),
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Рост, см'),
                    ),
                    TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Текущий вес, кг'),
                    ),
                    TextField(
                      controller: startController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Стартовый вес, кг'),
                    ),
                    TextField(
                      controller: goalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Целевой вес, кг'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSex,
                      decoration: const InputDecoration(labelText: 'Пол'),
                      items: const [
                        DropdownMenuItem(value: 'Мужской', child: Text('Мужской')),
                        DropdownMenuItem(value: 'Женский', child: Text('Женский')),
                      ],
                      onChanged: (value) {
                        if (value != null) dialogSetState(() => selectedSex = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsedAge = int.tryParse(ageController.text);
                    final parsedHeight = int.tryParse(heightController.text);
                    final parsedWeight = double.tryParse(weightController.text.replaceAll(',', '.'));
                    final parsedStart = double.tryParse(startController.text.replaceAll(',', '.'));
                    final parsedGoal = double.tryParse(goalController.text.replaceAll(',', '.'));
                    if (parsedAge == null ||
                        parsedHeight == null ||
                        parsedWeight == null ||
                        parsedStart == null ||
                        parsedGoal == null ||
                        parsedAge <= 0 ||
                        parsedHeight <= 0 ||
                        parsedWeight <= 0 ||
                        parsedStart <= 0 ||
                        parsedGoal <= 0) {
                      return;
                    }
                    change(() {
                      age = parsedAge;
                      height = parsedHeight;
                      weight = parsedWeight;
                      startWeight = parsedStart;
                      goalWeight = parsedGoal;
                      sex = selectedSex;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    startController.dispose();
    goalController.dispose();
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restaurant_outlined),
                title: const Text('Дневник питания'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => tab = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: const Text('Трекер веса'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => tab = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Статистика'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => tab = 3);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class FoodEntry {
  final Food food;
  final double grams;
  final String dateKey;

  const FoodEntry({
    required this.food,
    required this.grams,
    required this.dateKey,
  });

  int get kcal => (food.kcal * grams / 100).round();
  double get protein => food.protein * grams / 100;
  double get fat => food.fat * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fiber => food.fiber * grams / 100;

  factory FoodEntry.fromFood(Food food, double grams, String dateKey) {
    return FoodEntry(food: food, grams: grams, dateKey: dateKey);
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    final rawFood = json['food'];
    if (rawFood is Map) {
      return FoodEntry(
        food: Food.fromJson(Map<String, dynamic>.from(rawFood)),
        grams: (json['grams'] as num?)?.toDouble() ?? 100,
        dateKey: json['dateKey'] as String? ?? '',
      );
    }
    return FoodEntry(
      food: Food(
        name: json['name'] as String? ?? 'Продукт',
        kcal: (json['kcal'] as num?)?.round() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      ),
      grams: (json['grams'] as num?)?.toDouble() ?? 100,
      dateKey: json['dateKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'food': food.toJson(),
        'grams': grams,
        'dateKey': dateKey,
      };

  FoodEntry copyWith({double? grams}) => FoodEntry(
        food: food,
        grams: grams ?? this.grams,
        dateKey: dateKey,
      );
}

class WeightEntry {
  final double weight;
  final String label;
  final DateTime createdAt;

  const WeightEntry(this.weight, this.label, this.createdAt);

  String get date {
    const months = <String>[
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}, ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      (json['weight'] as num?)?.toDouble() ?? 0,
      json['label'] as String? ?? 'Запись',
      DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
      };
}

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double goal;

  const WeightChart({super.key, required this.entries, required this.goal});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('Добавьте измерение веса'));
    }
    return CustomPaint(
      painter: _WeightChartPainter(entries: entries, goal: goal),
      child: const SizedBox.expand(),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final double goal;

  const _WeightChartPainter({required this.entries, required this.goal});

  @override
  void paint(Canvas canvas, Size size) {
    final left = 42.0;
    final right = size.width - 12;
    final top = 18.0;
    final bottom = size.height - 28;
    final chartWidth = right - left;
    final chartHeight = bottom - top;

    final values = entries.map((e) => e.weight).toList();
    final minValue = [values.reduce((a, b) => a < b ? a : b), goal].reduce((a, b) => a < b ? a : b) - 2;
    final maxValue = [values.reduce((a, b) => a > b ? a : b), goal].reduce((a, b) => a > b ? a : b) + 2;
    final range = (maxValue - minValue).abs() < 1 ? 1.0 : maxValue - minValue;

    final gridPaint = Paint()
      ..color = const Color(0xFFE1E6EA)
      ..strokeWidth = 1;
    final goalPaint = Paint()
      ..color = green
      ..strokeWidth = 2;
    final linePaint = Paint()
      ..color = blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = blue;

    for (var i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      final value = maxValue - range * i / 4;
      final text = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: const TextStyle(fontSize: 10, color: muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(0, y - text.height / 2));
    }

    final goalY = bottom - ((goal - minValue) / range) * chartHeight;
    canvas.drawLine(Offset(left, goalY), Offset(right, goalY), goalPaint);

    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final x = entries.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * i / (entries.length - 1);
      final y = bottom - ((entries[i].weight - minValue) / range) * chartHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
    canvas.drawPath(path, linePaint);

    final goalText = TextPainter(
      text: const TextSpan(
        text: 'Цель',
        style: TextStyle(fontSize: 10, color: green),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    goalText.paint(canvas, Offset(right - goalText.width, goalY - goalText.height - 2));
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.goal != goal || oldDelegate.entries != entries;
  }
}

const defaultFoods = <Food>[
  Food(name: 'Куриная грудка', kcal: 110, protein: 23, fat: 1.9, carbs: 0, fiber: 0),
  Food(name: 'Яйцо куриное', kcal: 157, protein: 12.7, fat: 10.9, carbs: 0.7, fiber: 0),
  Food(name: 'Ветчина из индейки', kcal: 84, protein: 18, fat: 2, carbs: 2, fiber: 0),
  Food(name: 'Овсянка сухая', kcal: 366, protein: 12.3, fat: 6.1, carbs: 59.5, fiber: 8),
  Food(name: 'Рис сухой', kcal: 344, protein: 6.7, fat: 0.7, carbs: 78.9, fiber: 9.7),
  Food(name: 'Гречка сухая', kcal: 343, protein: 13.6, fat: 3.3, carbs: 71.5, fiber: 10),
  Food(name: 'Картофель отварной', kcal: 82, protein: 2, fat: 0.4, carbs: 16.7, fiber: 1.8),
  Food(name: 'Помидор', kcal: 18, protein: 0.9, fat: 0.2, carbs: 3.9, fiber: 1.2),
  Food(name: 'Перец красный', kcal: 31, protein: 1, fat: 0.3, carbs: 6, fiber: 2.1),
  Food(name: 'Айсберг', kcal: 14, protein: 0.9, fat: 0.1, carbs: 3, fiber: 1.2),
  Food(name: 'Яблоко', kcal: 52, protein: 0.3, fat: 0.2, carbs: 13.8, fiber: 2.4),
  Food(name: 'Йогурт греческий', kcal: 73, protein: 10, fat: 2, carbs: 3.6, fiber: 0),
  Food(name: 'Ежевика', kcal: 43, protein: 1.4, fat: 0.5, carbs: 9.6, fiber: 5.3),
];
