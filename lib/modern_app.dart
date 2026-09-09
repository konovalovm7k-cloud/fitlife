import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const green = Color(0xFF3D9B70);
const greenDark = Color(0xFF287451);
const mint = Color(0xFFE8F5EE);
const bg = Color(0xFFF6F8F6);
const ink = Color(0xFF17231D);
const muted = Color(0xFF7A857E);
const line = Color(0xFFE5EAE6);

class ModernFitLifeApp extends StatelessWidget {
  const ModernFitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: line),
          ),
        ),
      ),
      home: const FitLifeHome(),
    );
  }
}

class FoodItem {
  final String id;
  final String name;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  const FoodItem(
    this.id,
    this.name,
    this.kcal,
    this.protein,
    this.fat,
    this.carbs,
    this.fiber,
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kcal': kcal,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        json['id'] as String,
        json['name'] as String,
        (json['kcal'] as num).toDouble(),
        (json['protein'] as num).toDouble(),
        (json['fat'] as num).toDouble(),
        (json['carbs'] as num).toDouble(),
        (json['fiber'] as num).toDouble(),
      );
}

class DiaryItem {
  final String id;
  final String meal;
  final FoodItem food;
  final double grams;
  final String time;

  DiaryItem({
    required this.id,
    required this.meal,
    required this.food,
    required this.grams,
    required this.time,
  });

  double get kcal => food.kcal * grams / 100;
  double get protein => food.protein * grams / 100;
  double get fat => food.fat * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fiber => food.fiber * grams / 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'meal': meal,
        'food': food.toJson(),
        'grams': grams,
        'time': time,
      };

  factory DiaryItem.fromJson(Map<String, dynamic> json) => DiaryItem(
        id: json['id'] as String,
        meal: json['meal'] as String,
        food: FoodItem.fromJson(
          Map<String, dynamic>.from(json['food'] as Map),
        ),
        grams: (json['grams'] as num).toDouble(),
        time: json['time'] as String,
      );
}

const builtInFoods = <FoodItem>[
  FoodItem('egg', 'Яйцо', 157, 12.7, 10.9, 0.7, 0),
  FoodItem('turkey_ham', 'Ветчина из индейки', 84, 18, 2, 2, 0),
  FoodItem('oats', 'Овсяные хлопья, сухие', 366, 12.3, 6.1, 59.5, 8.3),
  FoodItem('chicken', 'Куриная грудка, сырая', 120, 22.5, 2.6, 0, 0),
  FoodItem('buckwheat', 'Гречка, сухая', 343, 13.6, 3.4, 71.5, 10),
  FoodItem('couscous', 'Кускус, сухой', 376, 12.8, 0.6, 77.4, 5),
  FoodItem('potato', 'Картофель, отварной', 82, 2, 0.4, 17, 1.8),
  FoodItem('greek_yogurt', 'Греческий йогурт', 73, 9, 2.5, 3.8, 0),
  FoodItem('skyr', 'Skyr', 35, 6, 0, 3, 0),
  FoodItem('pepper', 'Перец красный', 31, 1, 0.3, 6, 2.1),
  FoodItem('iceberg', 'Салат айсберг', 14, 0.9, 0.1, 3, 1.2),
  FoodItem('tomato', 'Помидор', 18, 0.9, 0.2, 3.9, 1.2),
  FoodItem('cucumber', 'Огурец', 15, 0.7, 0.1, 3.6, 0.5),
  FoodItem('apple', 'Яблоко', 52, 0.3, 0.2, 13.8, 2.4),
  FoodItem('peach', 'Персик', 39, 0.9, 0.3, 9.5, 1.5),
  FoodItem('blackberry', 'Ежевика', 43, 1.4, 0.5, 9.6, 5.3),
  FoodItem('mushroom', 'Шампиньоны', 22, 3.1, 0.3, 3.3, 1),
  FoodItem('sour_cream', 'Сметана 25%', 248, 2.6, 25, 3.2, 0),
  FoodItem('ketchup', 'Кетчуп', 110, 1.2, 0.2, 25, 0.7),
];

class FitLifeHome extends StatefulWidget {
  const FitLifeHome({super.key});

  @override
  State<FitLifeHome> createState() => _FitLifeHomeState();
}

class _FitLifeHomeState extends State<FitLifeHome> {
  static const calorieTarget = 1900.0;
  static const proteinMin = 160.0;
  static const proteinMax = 180.0;
  static const fatTarget = 65.0;
  static const fiberTarget = 30.0;

  int tab = 0;
  double water = 1.5;
  double weight = 104.2;
  bool loading = true;
  List<DiaryItem> diary = <DiaryItem>[];
  List<FoodItem> customFoods = <FoodItem>[];

  List<FoodItem> get foods => [...builtInFoods, ...customFoods];

  double get calories => diary.fold(0, (sum, item) => sum + item.kcal);
  double get protein => diary.fold(0, (sum, item) => sum + item.protein);
  double get fat => diary.fold(0, (sum, item) => sum + item.fat);
  double get carbs => diary.fold(0, (sum, item) => sum + item.carbs);
  double get fiber => diary.fold(0, (sum, item) => sum + item.fiber);
  double get caloriesLeft => (calorieTarget - calories).clamp(0, calorieTarget);

  String get dayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDiary = prefs.getString('diary_$dayKey');
    final rawFoods = prefs.getString('custom_foods');
    if (!mounted) return;

    setState(() {
      water = prefs.getDouble('water') ?? 1.5;
      weight = prefs.getDouble('weight') ?? 104.2;
      diary = rawDiary == null
          ? <DiaryItem>[]
          : (jsonDecode(rawDiary) as List)
              .map((item) => DiaryItem.fromJson(Map<String, dynamic>.from(item)))
              .toList();
      customFoods = rawFoods == null
          ? <FoodItem>[]
          : (jsonDecode(rawFoods) as List)
              .map((item) => FoodItem.fromJson(Map<String, dynamic>.from(item)))
              .toList();
      loading = false;
    });
  }

  Future<void> _saveDiary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'diary_$dayKey',
      jsonEncode(diary.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveFoods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'custom_foods',
      jsonEncode(customFoods.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveNumber(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: green)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: <Widget>[
            _todayPage(),
            _diaryPage(),
            _weightPage(),
            _progressPage(),
            _profilePage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        backgroundColor: Colors.white,
        indicatorColor: mint,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Сегодня',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Питание',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight_rounded),
            label: 'Вес',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Прогресс',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
      ),
      floatingActionButton: tab <= 1
          ? FloatingActionButton.extended(
              onPressed: _addFood,
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Добавить еду'),
            )
          : null,
    );
  }

  Widget _todayPage() {
    final meals = _groupedMeals();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: <Widget>[
        _header('Сегодня', _dateLabel()),
        const SizedBox(height: 14),
        _petCard(),
        const SizedBox(height: 14),
        _calorieCard(),
        const SizedBox(height: 12),
        _macroCard(),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            _smallStat('Вода', '${water.toStringAsFixed(1)} л', Icons.water_drop_outlined, _addWater),
            const SizedBox(width: 8),
            _smallStat('Вес', '${weight.toStringAsFixed(1)} кг', Icons.monitor_weight_outlined, _addWeight),
            const SizedBox(width: 8),
            _smallStat('Приёмов', '${meals.length}', Icons.restaurant_outlined, null),
          ],
        ),
        const SizedBox(height: 18),
        _nextAction(),
        const SizedBox(height: 18),
        const Text('Дневник питания', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
        const SizedBox(height: 8),
        if (diary.isEmpty)
          _emptyCard()
        else
          ...meals.entries.map((entry) => _mealCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _diaryPage() {
    final meals = _groupedMeals();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: <Widget>[
        _header('Питание', 'Точный расчёт по граммам'),
        const SizedBox(height: 14),
        _summaryCard(),
        const SizedBox(height: 14),
        if (diary.isEmpty)
          _emptyCard()
        else
          ...meals.entries.map((entry) => _mealCard(entry.key, entry.value)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addCustomFood,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.white,
            side: const BorderSide(color: line),
          ),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Создать свой продукт'),
        ),
      ],
    );
  }

  Widget _weightPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: <Widget>[
        _header('Вес', 'Отслеживаем тренд, а не скачки'),
        const SizedBox(height: 14),
        _surfaceCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Текущий вес', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${weight.toStringAsFixed(1)} кг', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 8),
              const Text('Цель: 85 кг', style: TextStyle(color: greenDark, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _addWeight,
                icon: const Icon(Icons.add),
                label: const Text('Внести сегодняшний вес'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: green),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: <Widget>[
        _header('Прогресс', 'Главное — устойчивость'),
        const SizedBox(height: 14),
        _surfaceCard(
          Column(
            children: <Widget>[
              ProgressLine(label: 'Калории', value: calories / calorieTarget, text: '${calories.round()} / 1900'),
              ProgressLine(label: 'Белок', value: protein / proteinMax, text: '${protein.round()} / 180 г'),
              ProgressLine(label: 'Жиры', value: fat / fatTarget, text: '${fat.round()} / 65 г'),
              ProgressLine(label: 'Клетчатка', value: fiber / fiberTarget, text: '${fiber.round()} / 30 г'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _surfaceCard(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Подход FitLife', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
              SizedBox(height: 8),
              Text('Без штрафов за лишнюю еду. Возвращаемся к обычному режиму со следующего приёма пищи.', style: TextStyle(color: muted, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: <Widget>[
        _header('Профиль', 'Настройки целей'),
        const SizedBox(height: 14),
        _surfaceCard(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Цели на день', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
              SizedBox(height: 12),
              Text('1900 ккал', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              SizedBox(height: 4),
              Text('Белок 160–180 г · Жиры до 65 г · Клетчатка 30 г', style: TextStyle(color: muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _settingTile(Icons.restaurant_outlined, 'База продуктов', '${foods.length} продуктов доступно'),
        _settingTile(Icons.save_outlined, 'Локальное хранение', 'Дневник сохраняется на устройстве'),
      ],
    );
  }

  Widget _header(String title, String subtitle) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => tab = 4),
          icon: const Icon(Icons.person_outline_rounded, color: ink),
        ),
      ],
    );
  }

  Widget _petCard() {
    return _surfaceCard(
      Row(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
            child: const Center(child: Text('🐼', style: TextStyle(fontSize: 42))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Твой помощник', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                const Text('Панда на хорошем ходу 💚', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
                const SizedBox(height: 7),
                Text(
                  diary.isEmpty ? 'Начинаем день' : 'Дневник заполнен на ${(calories / calorieTarget * 100).clamp(0, 100).round()}%',
                  style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calorieCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF203129),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  value: (calories / calorieTarget).clamp(0, 1),
                  strokeWidth: 10,
                  color: const Color(0xFF7BE0A8),
                  backgroundColor: const Color(0x334A5A50),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('${caloriesLeft.round()}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)),
                    const Text('осталось', style: TextStyle(color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Дневная цель', style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 4),
                Text('${calories.round()} из 1 900 ккал', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 7),
                Text('Белок ${protein.round()} г · клетчатка ${fiber.round()} г', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard() {
    return _surfaceCard(
      Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Макросы', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
              Text('Б ${protein.round()} · Ж ${fat.round()} · У ${carbs.round()}', style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Expanded(child: _macroBar('Белок', protein, proteinMax)),
              const SizedBox(width: 10),
              Expanded(child: _macroBar('Жиры', fat, fatTarget)),
              const SizedBox(width: 10),
              Expanded(child: _macroBar('Углеводы', carbs, 180)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroBar(String label, double value, double target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (value / target).clamp(0, 1),
            minHeight: 7,
            color: green,
            backgroundColor: mint,
          ),
        ),
      ],
    );
  }

  Widget _smallStat(String label, String value, IconData icon, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: _surfaceCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: greenDark),
              const SizedBox(height: 7),
              Text(label, style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextAction() {
    String title;
    String subtitle;
    if (diary.isEmpty) {
      title = 'Следующее действие';
      subtitle = 'Добавь первый приём пищи';
    } else if (protein < proteinMin) {
      title = 'Следующее действие';
      subtitle = 'Добавь белковый продукт';
    } else if (fiber < fiberTarget) {
      title = 'Следующее действие';
      subtitle = 'Добавь овощи, ягоды или крупу';
    } else {
      title = 'Отличный ход';
      subtitle = 'Продолжай без компенсаций и крайностей';
    }

    return _surfaceCard(
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(backgroundColor: mint, child: Icon(Icons.flag_outlined, color: greenDark)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
        subtitle: Text(subtitle, style: const TextStyle(color: muted)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _addFood,
      ),
    );
  }

  Widget _summaryCard() {
    return _surfaceCard(
      Row(
        children: <Widget>[
          Metric(label: 'Ккал', value: '${calories.round()} / 1900'),
          Metric(label: 'Белок', value: '${protein.round()} г'),
          Metric(label: 'Жиры', value: '${fat.round()} г'),
          Metric(label: 'Клетчатка', value: '${fiber.round()} г'),
        ],
      ),
    );
  }

  Widget _mealCard(String meal, List<DiaryItem> items) {
    final totalKcal = items.fold(0.0, (sum, item) => sum + item.kcal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _surfaceCard(
        Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(meal, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
                Text('${totalKcal.round()} ккал', style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ...items.map(
              (item) => Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  setState(() => diary.removeWhere((entry) => entry.id == item.id));
                  _saveDiary();
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.food.name, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                  subtitle: Text('${item.grams.round()} г · ${item.time}'),
                  trailing: Text('${item.kcal.round()} ккал'),
                  onTap: () => _editDiaryItem(item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return _surfaceCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Дневник пока пуст', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 6),
          const Text('Добавь еду — калории, БЖУ и клетчатка посчитаются автоматически.', style: TextStyle(color: muted, height: 1.35)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _addFood,
            icon: const Icon(Icons.add),
            label: const Text('Добавить продукт'),
            style: FilledButton.styleFrom(backgroundColor: green),
          ),
        ],
      ),
    );
  }

  Widget _surfaceCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: child,
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _surfaceCard(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: mint, child: Icon(icon, color: greenDark)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
          subtitle: Text(subtitle, style: const TextStyle(color: muted)),
        ),
      ),
    );
  }

  Future<void> _addFood() async {
    FoodItem? selected;
    String query = '';
    String meal = 'Ужин';
    final gramsController = TextEditingController(text: '100');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = foods
                .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
                .take(25)
                .toList();
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Добавить продукт', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: ink)),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск продукта'),
                    onChanged: (value) => setSheetState(() => query = value),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 210,
                    child: ListView(
                      children: filtered.map((food) {
                        return ListTile(
                          selected: selected?.id == food.id,
                          selectedTileColor: mint,
                          title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${food.kcal.round()} ккал · Б ${food.protein} г · К ${food.fiber} г / 100 г'),
                          onTap: () => setSheetState(() => selected = food),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: gramsController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Граммы'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: meal,
                          decoration: const InputDecoration(labelText: 'Приём'),
                          items: const <String>['Завтрак', 'Обед', 'Ужин', 'Перекус']
                              .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                              .toList(),
                          onChanged: (value) => setSheetState(() => meal = value ?? meal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: selected == null
                          ? null
                          : () {
                              final grams = double.tryParse(gramsController.text.replaceAll(',', '.'));
                              if (grams == null || grams <= 0) return;
                              setState(() {
                                diary.add(
                                  DiaryItem(
                                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                                    meal: meal,
                                    food: selected!,
                                    grams: grams,
                                    time: TimeOfDay.now().format(context),
                                  ),
                                );
                              });
                              _saveDiary();
                              Navigator.pop(sheetContext);
                            },
                      icon: const Icon(Icons.check),
                      label: const Text('Добавить в дневник'),
                      style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(52)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editDiaryItem(DiaryItem item) async {
    final controller = TextEditingController(text: item.grams.toStringAsFixed(0));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(item.food.name),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Граммы'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() => diary.removeWhere((entry) => entry.id == item.id));
                _saveDiary();
                Navigator.pop(dialogContext);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
            FilledButton(
              onPressed: () {
                final grams = double.tryParse(controller.text.replaceAll(',', '.'));
                if (grams == null || grams <= 0) return;
                final index = diary.indexWhere((entry) => entry.id == item.id);
                if (index >= 0) {
                  setState(() {
                    diary[index] = DiaryItem(
                      id: item.id,
                      meal: item.meal,
                      food: item.food,
                      grams: grams,
                      time: item.time,
                    );
                  });
                  _saveDiary();
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCustomFood() async {
    final name = TextEditingController();
    final kcal = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();
    final carbsController = TextEditingController();
    final fiberController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Свой продукт'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _numField(name, 'Название', text: true),
                const SizedBox(height: 8),
                _numField(kcal, 'Ккал / 100 г'),
                const SizedBox(height: 8),
                _numField(proteinController, 'Белок / 100 г'),
                const SizedBox(height: 8),
                _numField(fatController, 'Жиры / 100 г'),
                const SizedBox(height: 8),
                _numField(carbsController, 'Углеводы / 100 г'),
                const SizedBox(height: 8),
                _numField(fiberController, 'Клетчатка / 100 г'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Сохранить')),
          ],
        );
      },
    );

    if (ok != true || name.text.trim().isEmpty) return;
    final food = FoodItem(
      'custom_${DateTime.now().microsecondsSinceEpoch}',
      name.text.trim(),
      double.tryParse(kcal.text.replaceAll(',', '.')) ?? 0,
      double.tryParse(proteinController.text.replaceAll(',', '.')) ?? 0,
      double.tryParse(fatController.text.replaceAll(',', '.')) ?? 0,
      double.tryParse(carbsController.text.replaceAll(',', '.')) ?? 0,
      double.tryParse(fiberController.text.replaceAll(',', '.')) ?? 0,
    );
    setState(() => customFoods.add(food));
    await _saveFoods();
  }

  Widget _numField(TextEditingController controller, String label, {bool text = false}) {
    return TextField(
      controller: controller,
      keyboardType: text ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _addWater() async {
    final value = (water + 0.25).clamp(0, 5).toDouble();
    setState(() => water = value);
    await _saveNumber('water', water);
  }

  Future<void> _addWeight() async {
    final controller = TextEditingController(text: weight.toStringAsFixed(1));
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Добавить вес'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(suffixText: 'кг'),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Сохранить')),
          ],
        );
      },
    );
    if (ok != true) return;
    final value = double.tryParse(controller.text.replaceAll(',', '.'));
    if (value == null || value < 30 || value > 300) return;
    setState(() => weight = value);
    await _saveNumber('weight', value);
  }

  String _dateLabel() {
    const days = <String>['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];
    final now = DateTime.now();
    return '${now.day}.${now.month}.${now.year} · ${days[now.weekday - 1]}';
  }

  Map<String, List<DiaryItem>> _groupedMeals() {
    const order = <String>['Завтрак', 'Обед', 'Ужин', 'Перекус'];
    final result = <String, List<DiaryItem>>{};
    for (final meal in order) {
      final items = diary.where((item) => item.meal == meal).toList();
      if (items.isNotEmpty) result[meal] = items;
    }
    return result;
  }
}

class Metric extends StatelessWidget {
  final String label;
  final String value;

  const Metric({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: ink, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  final String label;
  final double value;
  final String text;

  const ProgressLine({super.key, required this.label, required this.value, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
              Text(text, style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 8,
              color: green,
              backgroundColor: mint,
            ),
          ),
        ],
      ),
    );
  }
}
