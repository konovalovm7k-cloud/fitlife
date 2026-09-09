import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      ),
      home: const FitLifeHome(),
    );
  }
}

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
  });

  final String id;
  final String name;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kcal': kcal,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      kcal: (json['kcal'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
    );
  }
}

class DiaryItem {
  const DiaryItem({
    required this.id,
    required this.meal,
    required this.food,
    required this.grams,
    required this.time,
  });

  final String id;
  final String meal;
  final FoodItem food;
  final double grams;
  final String time;

  double get kcal => food.kcal * grams / 100;
  double get protein => food.protein * grams / 100;
  double get fat => food.fat * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fiber => food.fiber * grams / 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal': meal,
      'food': food.toJson(),
      'grams': grams,
      'time': time,
    };
  }

  factory DiaryItem.fromJson(Map<String, dynamic> json) {
    return DiaryItem(
      id: json['id'] as String,
      meal: json['meal'] as String,
      food: FoodItem.fromJson(
        Map<String, dynamic>.from(json['food'] as Map),
      ),
      grams: (json['grams'] as num).toDouble(),
      time: json['time'] as String,
    );
  }
}

const builtInFoods = <FoodItem>[
  FoodItem(id: 'egg', name: 'Яйцо', kcal: 157, protein: 12.7, fat: 10.9, carbs: 0.7, fiber: 0),
  FoodItem(id: 'chicken', name: 'Куриная грудка', kcal: 120, protein: 22.5, fat: 2.6, carbs: 0, fiber: 0),
  FoodItem(id: 'turkey', name: 'Индейка', kcal: 114, protein: 23.7, fat: 1.5, carbs: 0, fiber: 0),
  FoodItem(id: 'turkey_ham', name: 'Ветчина из индейки', kcal: 84, protein: 18, fat: 2, carbs: 2, fiber: 0),
  FoodItem(id: 'beef', name: 'Говядина постная', kcal: 158, protein: 26, fat: 6, carbs: 0, fiber: 0),
  FoodItem(id: 'salmon', name: 'Лосось', kcal: 208, protein: 20, fat: 13, carbs: 0, fiber: 0),
  FoodItem(id: 'tuna', name: 'Тунец', kcal: 116, protein: 26, fat: 0.8, carbs: 0, fiber: 0),
  FoodItem(id: 'cottage', name: 'Творог 5%', kcal: 121, protein: 17, fat: 5, carbs: 1.8, fiber: 0),
  FoodItem(id: 'yogurt', name: 'Греческий йогурт', kcal: 73, protein: 9, fat: 2.5, carbs: 3.8, fiber: 0),
  FoodItem(id: 'skyr', name: 'Skyr', kcal: 35, protein: 6, fat: 0, carbs: 3, fiber: 0),
  FoodItem(id: 'oats', name: 'Овсянка', kcal: 366, protein: 12.3, fat: 6.1, carbs: 59.5, fiber: 8.3),
  FoodItem(id: 'buckwheat', name: 'Гречка', kcal: 343, protein: 13.6, fat: 3.4, carbs: 71.5, fiber: 10),
  FoodItem(id: 'rice', name: 'Рис', kcal: 344, protein: 7, fat: 0.7, carbs: 78, fiber: 2.4),
  FoodItem(id: 'couscous', name: 'Кускус', kcal: 376, protein: 12.8, fat: 0.6, carbs: 77.4, fiber: 5),
  FoodItem(id: 'pasta', name: 'Макароны', kcal: 350, protein: 12, fat: 1.5, carbs: 70, fiber: 3),
  FoodItem(id: 'potato', name: 'Картофель', kcal: 82, protein: 2, fat: 0.4, carbs: 17, fiber: 1.8),
  FoodItem(id: 'bread', name: 'Хлеб цельнозерновой', kcal: 247, protein: 13, fat: 4.2, carbs: 41, fiber: 7),
  FoodItem(id: 'pepper', name: 'Перец', kcal: 31, protein: 1, fat: 0.3, carbs: 6, fiber: 2.1),
  FoodItem(id: 'iceberg', name: 'Айсберг', kcal: 14, protein: 0.9, fat: 0.1, carbs: 3, fiber: 1.2),
  FoodItem(id: 'tomato', name: 'Помидор', kcal: 18, protein: 0.9, fat: 0.2, carbs: 3.9, fiber: 1.2),
  FoodItem(id: 'cucumber', name: 'Огурец', kcal: 15, protein: 0.7, fat: 0.1, carbs: 3.6, fiber: 0.5),
  FoodItem(id: 'broccoli', name: 'Брокколи', kcal: 34, protein: 2.8, fat: 0.4, carbs: 6.6, fiber: 2.6),
  FoodItem(id: 'cauliflower', name: 'Цветная капуста', kcal: 25, protein: 1.9, fat: 0.3, carbs: 5, fiber: 2),
  FoodItem(id: 'carrot', name: 'Морковь', kcal: 41, protein: 0.9, fat: 0.2, carbs: 9.6, fiber: 2.8),
  FoodItem(id: 'mushroom', name: 'Шампиньоны', kcal: 22, protein: 3.1, fat: 0.3, carbs: 3.3, fiber: 1),
  FoodItem(id: 'apple', name: 'Яблоко', kcal: 52, protein: 0.3, fat: 0.2, carbs: 13.8, fiber: 2.4),
  FoodItem(id: 'banana', name: 'Банан', kcal: 89, protein: 1.1, fat: 0.3, carbs: 22.8, fiber: 2.6),
  FoodItem(id: 'orange', name: 'Апельсин', kcal: 47, protein: 0.9, fat: 0.1, carbs: 11.8, fiber: 2.4),
  FoodItem(id: 'peach', name: 'Персик', kcal: 39, protein: 0.9, fat: 0.3, carbs: 9.5, fiber: 1.5),
  FoodItem(id: 'blackberry', name: 'Ежевика', kcal: 43, protein: 1.4, fat: 0.5, carbs: 9.6, fiber: 5.3),
  FoodItem(id: 'blueberry', name: 'Черника', kcal: 57, protein: 0.7, fat: 0.3, carbs: 14.5, fiber: 2.4),
  FoodItem(id: 'avocado', name: 'Авокадо', kcal: 160, protein: 2, fat: 14.7, carbs: 8.5, fiber: 6.7),
  FoodItem(id: 'almonds', name: 'Миндаль', kcal: 579, protein: 21.2, fat: 49.9, carbs: 21.6, fiber: 12.5),
  FoodItem(id: 'walnut', name: 'Грецкий орех', kcal: 654, protein: 15.2, fat: 65.2, carbs: 13.7, fiber: 6.7),
  FoodItem(id: 'oil', name: 'Оливковое масло', kcal: 884, protein: 0, fat: 100, carbs: 0, fiber: 0),
  FoodItem(id: 'sour_cream', name: 'Сметана 25%', kcal: 248, protein: 2.6, fat: 25, carbs: 3.2, fiber: 0),
  FoodItem(id: 'ketchup', name: 'Кетчуп', kcal: 110, protein: 1.2, fat: 0.2, carbs: 25, fiber: 0.7),
];

class FitLifeHome extends StatefulWidget {
  const FitLifeHome({super.key});

  @override
  State<FitLifeHome> createState() => _FitLifeHomeState();
}

class _FitLifeHomeState extends State<FitLifeHome> {
  static const double kcalTarget = 1900;
  static const double proteinTarget = 180;
  static const double fatTarget = 65;
  static const double fiberTarget = 30;

  final ImagePicker picker = ImagePicker();

  int tab = 0;
  double water = 1.5;
  double weight = 104.2;
  bool loading = true;
  File? photo;

  List<DiaryItem> diary = [];
  List<FoodItem> customFoods = [];
  List<String> favorites = [];
  List<String> recent = [];

  List<FoodItem> get foods => [...builtInFoods, ...customFoods];

  double get calories {
    return diary.fold(0, (sum, item) => sum + item.kcal);
  }

  double get protein {
    return diary.fold(0, (sum, item) => sum + item.protein);
  }

  double get fat {
    return diary.fold(0, (sum, item) => sum + item.fat);
  }

  double get carbs {
    return diary.fold(0, (sum, item) => sum + item.carbs);
  }

  double get fiber {
    return diary.fold(0, (sum, item) => sum + item.fiber);
  }

  double get caloriesLeft {
    final value = kcalTarget - calories;
    return value.clamp(0, kcalTarget).toDouble();
  }

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
    final diaryJson = prefs.getString('diary_$dayKey');
    final foodsJson = prefs.getString('custom_foods');

    if (!mounted) {
      return;
    }

    setState(() {
      water = prefs.getDouble('water') ?? 1.5;
      weight = prefs.getDouble('weight') ?? 104.2;
      favorites = prefs.getStringList('favorites') ?? [];
      recent = prefs.getStringList('recent') ?? [];
      diary = diaryJson == null
          ? []
          : (jsonDecode(diaryJson) as List)
              .map((item) => DiaryItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
      customFoods = foodsJson == null
          ? []
          : (jsonDecode(foodsJson) as List)
              .map((item) => FoodItem.fromJson(Map<String, dynamic>.from(item as Map)))
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

  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites);
    await prefs.setStringList('recent', recent);
  }

  Future<void> _saveFoods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'custom_foods',
      jsonEncode(customFoods.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _setNumber(String key, double value) async {
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

    final pages = <Widget>[
      _todayPage(),
      _foodPage(),
      _cameraPage(),
      _progressPage(),
      _profilePage(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        backgroundColor: Colors.white,
        indicatorColor: mint,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Сегодня'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Питание'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Камера'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Прогресс'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
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

  Widget _header(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ink)),
        Text(subtitle, style: const TextStyle(color: muted)),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: child,
    );
  }

  Widget _darkCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }

  Widget _todayPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        _header('Сегодня', _dateLabel()),
        const SizedBox(height: 14),
        _card(
          Row(
            children: [
              const Text('🐼', style: TextStyle(fontSize: 50)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Твой помощник', style: TextStyle(color: muted)),
                    Text(
                      diary.isEmpty ? 'Панда ждёт первый приём пищи 💚' : 'Панда поддерживает твой ритм 💚',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _darkCard(
          Row(
            children: [
              SizedBox(
                width: 105,
                height: 105,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (calories / kcalTarget).clamp(0, 1).toDouble(),
                      color: const Color(0xFF7BE0A8),
                      backgroundColor: const Color(0x334A5A50),
                      strokeWidth: 10,
                    ),
                    Text(
                      '${caloriesLeft.round()}',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Дневная цель', style: TextStyle(color: Colors.white60)),
                    Text(
                      '${calories.round()} / ${kcalTarget.round()} ккал',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Белок ${protein.round()} г · Клетчатка ${fiber.round()} г',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Макросы', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
                  Text('Б ${protein.round()} · Ж ${fat.round()} · У ${carbs.round()}', style: const TextStyle(color: muted)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metricBar('Белок', protein, proteinTarget),
                  const SizedBox(width: 8),
                  _metricBar('Жиры', fat, fatTarget),
                  const SizedBox(width: 8),
                  _metricBar('Клетчатка', fiber, fiberTarget),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard('Вода', '${water.toStringAsFixed(1)} л', Icons.water_drop_outlined, _addWater),
            const SizedBox(width: 8),
            _statCard('Вес', '${weight.toStringAsFixed(1)} кг', Icons.monitor_weight_outlined, _addWeight),
            const SizedBox(width: 8),
            _statCard('Приёмов', '${diary.length}', Icons.restaurant_outlined, null),
          ],
        ),
        const SizedBox(height: 18),
        _nextAction(),
        const SizedBox(height: 18),
        const Text('Дневник', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
        const SizedBox(height: 8),
        if (diary.isEmpty) _emptyCard() else ..._mealCards(),
      ],
    );
  }

  Widget _foodPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        _header('Питание', 'Поиск, избранное и последние продукты'),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${calories.round()} ккал', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: ink)),
              Text(
                'Осталось ${caloriesLeft.round()} ккал · Б ${protein.round()} г · Ж ${fat.round()} г · Кл ${fiber.round()} г',
                style: const TextStyle(color: muted),
              ),
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          _sectionTitle('Последние'),
          _foodChips(recent),
        ],
        if (favorites.isNotEmpty) ...[
          _sectionTitle('Избранное'),
          _foodChips(favorites),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addCustomFood,
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Создать свой продукт'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addFood,
          icon: const Icon(Icons.search),
          label: const Text('Поиск продукта'),
        ),
        const SizedBox(height: 14),
        if (diary.isNotEmpty) ..._mealCards(),
      ],
    );
  }

  Widget _cameraPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        _header('Камера', 'Фото блюда → подтверждение'),
        const SizedBox(height: 14),
        _card(
          Column(
            children: [
              if (photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(photo!, height: 240, width: double.infinity, fit: BoxFit.cover),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Icon(Icons.photo_camera_back_outlined, size: 80, color: greenDark),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Камера'),
                      style: FilledButton.styleFrom(backgroundColor: green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Галерея'),
                    ),
                  ),
                ],
              ),
              if (photo != null) ...[
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Следующий шаг', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Фото уже можно использовать для ручного подтверждения. Облачное AI-распознавание подключается отдельным модулем.',
                    style: TextStyle(color: muted),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _addFood,
                  icon: const Icon(Icons.check),
                  label: const Text('Подтвердить и выбрать продукты'),
                  style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(50)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        _header('Прогресс', 'Устойчивость важнее идеального дня'),
        const SizedBox(height: 14),
        _card(
          Column(
            children: [
              _progressLine('Калории', calories / kcalTarget, '${calories.round()} / ${kcalTarget.round()} ккал'),
              const SizedBox(height: 14),
              _progressLine('Белок', protein / proteinTarget, '${protein.round()} / ${proteinTarget.round()} г'),
              const SizedBox(height: 14),
              _progressLine('Жиры', fat / fatTarget, '${fat.round()} / ${fatTarget.round()} г'),
              const SizedBox(height: 14),
              _progressLine('Клетчатка', fiber / fiberTarget, '${fiber.round()} / ${fiberTarget.round()} г'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Row(
            children: [
              const Text('🐼', style: TextStyle(fontSize: 46)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Панда растёт вместе с привычками', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: ink)),
                    SizedBox(height: 4),
                    Text('Сейчас важнее регулярность, чем идеальный результат за один день.', style: TextStyle(color: muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        _header('Профиль', 'Твои базовые параметры'),
        const SizedBox(height: 14),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Текущие настройки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 12),
              _profileRow('Вес', '${weight.toStringAsFixed(1)} кг'),
              _profileRow('Цель по калориям', '${kcalTarget.round()} ккал'),
              _profileRow('Белок', '${proteinTarget.round()} г'),
              _profileRow('Жиры', '${fatTarget.round()} г'),
              _profileRow('Клетчатка', '${fiberTarget.round()} г'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          const Text(
            'Медицинские данные и AI-анализ лабораторных PDF/фото будут добавлены отдельным безопасным модулем. Приложение не ставит диагнозы и не заменяет врача.',
            style: TextStyle(color: muted),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
        ],
      ),
    );
  }

  Widget _progressLine(String title, double value, String label) {
    final safeValue = value.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
            Text(label, style: const TextStyle(color: muted)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: safeValue, minHeight: 8, borderRadius: BorderRadius.circular(8)),
      ],
    );
  }

  Widget _metricBar(String title, double value, double target) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (value / target).clamp(0, 1).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: _card(
          Column(
            children: [
              Icon(icon, color: greenDark),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
              Text(title, style: const TextStyle(fontSize: 12, color: muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextAction() {
    final String text;
    if (diary.isEmpty) {
      text = 'Следующее действие: добавь первый приём пищи';
    } else if (protein < proteinTarget * 0.7) {
      text = 'Следующее действие: добавь белковый продукт';
    } else if (fiber < fiberTarget * 0.6) {
      text = 'Следующее действие: добавь овощи или ягоды';
    } else {
      text = 'Следующее действие: продолжай обычный ритм';
    }

    return _card(
      Row(
        children: [
          const Icon(Icons.flag_outlined, color: greenDark),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: ink))),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return _card(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Здесь появятся продукты и приёмы пищи.', style: TextStyle(color: muted)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
    );
  }

  Widget _foodChips(List<String> ids) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ids.map((id) {
        final food = _foodById(id);
        if (food == null) {
          return const SizedBox.shrink();
        }
        return ActionChip(
          label: Text(food.name),
          onPressed: () => _addFood(preselected: food),
        );
      }).toList(),
    );
  }

  List<Widget> _mealCards() {
    final grouped = <String, List<DiaryItem>>{};
    for (final item in diary) {
      grouped.putIfAbsent(item.meal, () => []).add(item);
    }

    const order = ['Завтрак', 'Обед', 'Ужин', 'Перекус'];
    final result = <Widget>[];
    for (final meal in order) {
      final items = grouped[meal];
      if (items == null || items.isEmpty) {
        continue;
      }
      result.add(_mealCard(meal, items));
    }
    return result;
  }

  Widget _mealCard(String meal, List<DiaryItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
            const SizedBox(height: 8),
            ...items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.food.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${item.grams.round()} г · ${item.kcal.round()} ккал · Б ${item.protein.round()} г · Кл ${item.fiber.round()} г'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editDiaryItem(item),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  FoodItem? _foodById(String id) {
    for (final food in foods) {
      if (food.id == id) {
        return food;
      }
    }
    return null;
  }

  String _dateLabel() {
    final now = DateTime.now();
    return '${now.day}.${now.month}.${now.year}';
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final result = await picker.pickImage(source: source, imageQuality: 88);
    if (result != null) {
      setState(() => photo = File(result.path));
    }
  }

  Future<void> _addFood({FoodItem? preselected}) async {
    FoodItem? selected = preselected;
    String meal = 'Ужин';
    String query = '';
    final gramsController = TextEditingController(text: '100');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            final filtered = foods
                .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
                .take(60)
                .toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 42, height: 4, color: line),
                  const SizedBox(height: 12),
                  const Text('Добавить продукт', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: ink)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск продукта'),
                    onChanged: (value) => updateSheet(() => query = value),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final food = filtered[index];
                        return ListTile(
                          selected: selected?.id == food.id,
                          selectedTileColor: mint,
                          title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${food.kcal.round()} ккал · Б ${food.protein} · Кл ${food.fiber} / 100 г'),
                          trailing: IconButton(
                            icon: Icon(favorites.contains(food.id) ? Icons.star : Icons.star_border),
                            onPressed: () {
                              setState(() {
                                if (favorites.contains(food.id)) {
                                  favorites.remove(food.id);
                                } else {
                                  favorites.add(food.id);
                                }
                              });
                              _saveLists();
                              updateSheet(() {});
                            },
                          ),
                          onTap: () => updateSheet(() => selected = food),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gramsController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Граммы'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: meal,
                          items: const ['Завтрак', 'Обед', 'Ужин', 'Перекус']
                              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                              .toList(),
                          onChanged: (value) => updateSheet(() => meal = value ?? meal),
                          decoration: const InputDecoration(labelText: 'Приём'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: selected == null
                        ? null
                        : () {
                            final grams = double.tryParse(gramsController.text.replaceAll(',', '.')) ?? 100;
                            if (grams <= 0) {
                              return;
                            }
                            final food = selected!;
                            setState(() {
                              diary.add(
                                DiaryItem(
                                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                                  meal: meal,
                                  food: food,
                                  grams: grams,
                                  time: TimeOfDay.now().format(context),
                                ),
                              );
                              recent = [food.id, ...recent.where((id) => id != food.id)].take(10).toList();
                            });
                            _saveDiary();
                            _saveLists();
                            Navigator.pop(sheetContext);
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Добавить'),
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    gramsController.dispose();
  }

  Future<void> _editDiaryItem(DiaryItem item) async {
    final controller = TextEditingController(text: item.grams.toStringAsFixed(0));
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(item.food.name),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Граммы'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'delete'),
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'save'),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result == 'delete') {
      setState(() => diary.removeWhere((entry) => entry.id == item.id));
      await _saveDiary();
    } else if (result == 'save') {
      final grams = double.tryParse(controller.text.replaceAll(',', '.'));
      if (grams == null || grams <= 0) {
        return;
      }
      final index = diary.indexWhere((entry) => entry.id == item.id);
      if (index < 0) {
        return;
      }
      setState(() {
        diary[index] = DiaryItem(
          id: item.id,
          meal: item.meal,
          food: item.food,
          grams: grams,
          time: item.time,
        );
      });
      await _saveDiary();
    }
    controller.dispose();
  }

  Future<void> _addCustomFood() async {
    final name = TextEditingController();
    final kcal = TextEditingController();
    final protein = TextEditingController();
    final fat = TextEditingController();
    final carbs = TextEditingController();
    final fiber = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Свой продукт'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Название')),
                TextField(controller: kcal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ккал / 100 г')),
                TextField(controller: protein, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Белок / 100 г')),
                TextField(controller: fat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Жиры / 100 г')),
                TextField(controller: carbs, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Углеводы / 100 г')),
                TextField(controller: fiber, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Клетчатка / 100 г')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Сохранить')),
          ],
        );
      },
    );

    if (ok != true || name.text.trim().isEmpty) {
      _disposeControllers([name, kcal, protein, fat, carbs, fiber]);
      return;
    }

    setState(() {
      customFoods.add(
        FoodItem(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          name: name.text.trim(),
          kcal: _parse(kcal.text),
          protein: _parse(protein.text),
          fat: _parse(fat.text),
          carbs: _parse(carbs.text),
          fiber: _parse(fiber.text),
        ),
      );
    });

    await _saveFoods();
    _disposeControllers([name, kcal, protein, fat, carbs, fiber]);
  }

  double _parse(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> _addWater() async {
    final next = water + 0.25;
    setState(() => water = next);
    await _setNumber('water', next);
  }

  Future<void> _addWeight() async {
    final controller = TextEditingController(text: weight.toStringAsFixed(1));
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Вес'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(suffixText: 'кг'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Сохранить')),
          ],
        );
      },
    );

    if (ok == true) {
      final value = _parse(controller.text);
      if (value >= 30 && value <= 300) {
        setState(() => weight = value);
        await _setNumber('weight', value);
      }
    }
    controller.dispose();
  }
}
