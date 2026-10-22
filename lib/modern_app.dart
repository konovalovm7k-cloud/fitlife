import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'app/fitlife_theme.dart';
import 'app/widgets/day_nutrition_summary.dart';
import 'app/widgets/companion_avatar.dart';
import 'app/widgets/value_editor.dart';
import 'core/models/diary_item.dart';
import 'core/nutrition/nutrition_catalog_page.dart';
import 'core/nutrition/nutrition_database.dart';
import 'core/nutrition/nutrition_day.dart';
import 'data/repositories/diary_preferences.dart';
import 'features/photo_analysis/photo_diary.dart';
import 'features/photo_analysis/photo_models.dart';
import 'features/photo_analysis/photo_page.dart';
import 'features/photo_analysis/photo_settings_page.dart';
import 'features/photo_analysis/text_meal_page.dart';
import 'features/progress/weekly_summary_page.dart';

export 'core/models/diary_item.dart';

class ModernFitLifeApp extends StatelessWidget {
  const ModernFitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: fitLifeTheme(),
      home: const FitLifeHome(),
    );
  }
}

const builtInFoods = <FoodItem>[
  FoodItem(
    id: 'egg',
    name: 'Яйцо',
    kcal: 157,
    protein: 12.7,
    fat: 10.9,
    carbs: 0.7,
    fiber: 0,
  ),
  FoodItem(
    id: 'chicken',
    name: 'Куриная грудка',
    kcal: 120,
    protein: 22.5,
    fat: 2.6,
    carbs: 0,
    fiber: 0,
  ),
  FoodItem(
    id: 'turkey',
    name: 'Индейка',
    kcal: 114,
    protein: 23.7,
    fat: 1.5,
    carbs: 0,
    fiber: 0,
  ),
  FoodItem(
    id: 'turkey_ham',
    name: 'Ветчина из индейки',
    kcal: 84,
    protein: 18,
    fat: 2,
    carbs: 2,
    fiber: 0,
  ),
  FoodItem(
    id: 'beef',
    name: 'Говядина постная',
    kcal: 158,
    protein: 26,
    fat: 6,
    carbs: 0,
    fiber: 0,
  ),
  FoodItem(
    id: 'salmon',
    name: 'Лосось',
    kcal: 208,
    protein: 20,
    fat: 13,
    carbs: 0,
    fiber: 0,
  ),
  FoodItem(
    id: 'tuna',
    name: 'Тунец',
    kcal: 116,
    protein: 26,
    fat: 0.8,
    carbs: 0,
    fiber: 0,
  ),
  FoodItem(
    id: 'cottage',
    name: 'Творог 5%',
    kcal: 121,
    protein: 17,
    fat: 5,
    carbs: 1.8,
    fiber: 0,
  ),
  FoodItem(
    id: 'yogurt',
    name: 'Греческий йогурт',
    kcal: 73,
    protein: 9,
    fat: 2.5,
    carbs: 3.8,
    fiber: 0,
  ),
  FoodItem(
    id: 'skyr',
    name: 'Skyr',
    kcal: 35,
    protein: 6,
    fat: 0,
    carbs: 3,
    fiber: 0,
  ),
  FoodItem(
    id: 'oats',
    name: 'Овсянка',
    kcal: 366,
    protein: 12.3,
    fat: 6.1,
    carbs: 59.5,
    fiber: 8.3,
  ),
  FoodItem(
    id: 'buckwheat',
    name: 'Гречка',
    kcal: 343,
    protein: 13.6,
    fat: 3.4,
    carbs: 71.5,
    fiber: 10,
  ),
  FoodItem(
    id: 'rice',
    name: 'Рис',
    kcal: 344,
    protein: 7,
    fat: 0.7,
    carbs: 78,
    fiber: 2.4,
  ),
  FoodItem(
    id: 'couscous',
    name: 'Кускус',
    kcal: 376,
    protein: 12.8,
    fat: 0.6,
    carbs: 77.4,
    fiber: 5,
  ),
  FoodItem(
    id: 'pasta',
    name: 'Макароны',
    kcal: 350,
    protein: 12,
    fat: 1.5,
    carbs: 70,
    fiber: 3,
  ),
  FoodItem(
    id: 'potato',
    name: 'Картофель',
    kcal: 82,
    protein: 2,
    fat: 0.4,
    carbs: 17,
    fiber: 1.8,
  ),
  FoodItem(
    id: 'bread',
    name: 'Хлеб цельнозерновой',
    kcal: 247,
    protein: 13,
    fat: 4.2,
    carbs: 41,
    fiber: 7,
  ),
  FoodItem(
    id: 'pepper',
    name: 'Перец',
    kcal: 31,
    protein: 1,
    fat: 0.3,
    carbs: 6,
    fiber: 2.1,
  ),
  FoodItem(
    id: 'iceberg',
    name: 'Айсберг',
    kcal: 14,
    protein: 0.9,
    fat: 0.1,
    carbs: 3,
    fiber: 1.2,
  ),
  FoodItem(
    id: 'tomato',
    name: 'Помидор',
    kcal: 18,
    protein: 0.9,
    fat: 0.2,
    carbs: 3.9,
    fiber: 1.2,
  ),
  FoodItem(
    id: 'cucumber',
    name: 'Огурец',
    kcal: 15,
    protein: 0.7,
    fat: 0.1,
    carbs: 3.6,
    fiber: 0.5,
  ),
  FoodItem(
    id: 'broccoli',
    name: 'Брокколи',
    kcal: 34,
    protein: 2.8,
    fat: 0.4,
    carbs: 6.6,
    fiber: 2.6,
  ),
  FoodItem(
    id: 'cauliflower',
    name: 'Цветная капуста',
    kcal: 25,
    protein: 1.9,
    fat: 0.3,
    carbs: 5,
    fiber: 2,
  ),
  FoodItem(
    id: 'carrot',
    name: 'Морковь',
    kcal: 41,
    protein: 0.9,
    fat: 0.2,
    carbs: 9.6,
    fiber: 2.8,
  ),
  FoodItem(
    id: 'mushroom',
    name: 'Шампиньоны',
    kcal: 22,
    protein: 3.1,
    fat: 0.3,
    carbs: 3.3,
    fiber: 1,
  ),
  FoodItem(
    id: 'apple',
    name: 'Яблоко',
    kcal: 52,
    protein: 0.3,
    fat: 0.2,
    carbs: 13.8,
    fiber: 2.4,
  ),
  FoodItem(
    id: 'banana',
    name: 'Банан',
    kcal: 89,
    protein: 1.1,
    fat: 0.3,
    carbs: 22.8,
    fiber: 2.6,
  ),
  FoodItem(
    id: 'orange',
    name: 'Апельсин',
    kcal: 47,
    protein: 0.9,
    fat: 0.1,
    carbs: 11.8,
    fiber: 2.4,
  ),
  FoodItem(
    id: 'peach',
    name: 'Персик',
    kcal: 39,
    protein: 0.9,
    fat: 0.3,
    carbs: 9.5,
    fiber: 1.5,
  ),
  FoodItem(
    id: 'blackberry',
    name: 'Ежевика',
    kcal: 43,
    protein: 1.4,
    fat: 0.5,
    carbs: 9.6,
    fiber: 5.3,
  ),
  FoodItem(
    id: 'blueberry',
    name: 'Черника',
    kcal: 57,
    protein: 0.7,
    fat: 0.3,
    carbs: 14.5,
    fiber: 2.4,
  ),
  FoodItem(
    id: 'avocado',
    name: 'Авокадо',
    kcal: 160,
    protein: 2,
    fat: 14.7,
    carbs: 8.5,
    fiber: 6.7,
  ),
  FoodItem(
    id: 'almonds',
    name: 'Миндаль',
    kcal: 579,
    protein: 21.2,
    fat: 49.9,
    carbs: 21.6,
    fiber: 12.5,
  ),
  FoodItem(
    id: 'walnut',
    name: 'Грецкий орех',
    kcal: 654,
    protein: 15.2,
    fat: 65.2,
    carbs: 13.7,
    fiber: 6.7,
  ),
  FoodItem(
    id: 'oil',
    name: 'Оливковое масло',
    kcal: 884,
    protein: 0,
    fat: 100,
    carbs: 0,
    fiber: 0,
  ),
  FoodItem(
    id: 'sour_cream',
    name: 'Сметана 25%',
    kcal: 248,
    protein: 2.6,
    fat: 25,
    carbs: 3.2,
    fiber: 0,
  ),
  FoodItem(
    id: 'ketchup',
    name: 'Кетчуп',
    kcal: 110,
    protein: 1.2,
    fat: 0.2,
    carbs: 25,
    fiber: 0.7,
  ),
];

class FitLifeHome extends StatefulWidget {
  const FitLifeHome({super.key, this.preferencesLoader});

  final Future<SharedPreferences> Function()? preferencesLoader;

  @override
  State<FitLifeHome> createState() => _FitLifeHomeState();
}

class _FitLifeHomeState extends State<FitLifeHome> with WidgetsBindingObserver {
  double kcalTarget = 1900;
  double proteinTarget = 180;
  double fatTarget = 65;
  double fiberTarget = 30;
  double get carbsTarget =>
      ((kcalTarget - proteinTarget * 4 - fatTarget * 9) / 4)
          .clamp(0, kcalTarget)
          .toDouble();

  int tab = 0;
  double water = 0;
  double weight = 104.2;
  bool loading = true;
  bool loadFailed = false;
  int _loadAttempt = 0;
  DateTime day = DateUtils.dateOnly(DateTime.now());
  DateTime _lastToday = DateUtils.dateOnly(DateTime.now());
  bool recoveredData = false;

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
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final today = DateUtils.dateOnly(DateTime.now());
    if (!DateUtils.isSameDay(today, _lastToday)) {
      if (DateUtils.isSameDay(day, _lastToday)) {
        setState(() {
          day = today;
          loading = true;
        });
        _load();
      }
      _lastToday = today;
    }
  }

  Future<void> _load() async {
    final key = dayKey;
    final attempt = ++_loadAttempt;
    setState(() {
      loading = true;
      loadFailed = false;
    });
    try {
      final data = await _readSavedDay(
        key,
      ).timeout(const Duration(seconds: 15));
      if (!mounted || key != dayKey || attempt != _loadAttempt) return;
      final store = data.store;
      setState(() {
        water = store.number('water_$key', 0, allowZero: true);
        weight = store.number('weight', 104.2);
        kcalTarget = store.number('goal_calories', 1900);
        proteinTarget = store.number('goal_protein', 180);
        fatTarget = store.number('goal_fat', 65);
        fiberTarget = store.number('goal_fiber', 30);
        favorites = data.favorites;
        recent = data.recent;
        diary = data.diary;
        customFoods = data.foods;
        recoveredData = store.recoveredData;
        loading = false;
      });
    } catch (error) {
      // Do not open a writable empty diary when its real data could not be read.
      debugPrint('FitLife storage initialization failed: ${error.runtimeType}');
      if (!mounted || key != dayKey || attempt != _loadAttempt) return;
      setState(() {
        loading = false;
        loadFailed = true;
      });
    }
  }

  Future<
    ({
      DiaryPreferences store,
      List<DiaryItem> diary,
      List<FoodItem> foods,
      List<String> favorites,
      List<String> recent,
    })
  >
  _readSavedDay(String key) async {
    final prefs =
        await (widget.preferencesLoader ?? SharedPreferences.getInstance)();
    final store = DiaryPreferences(prefs);
    final savedDiary = await store.readRecords(
      'diary_$key',
      DiaryItem.fromJson,
    );
    final savedFoods = await store.readRecords(
      'custom_foods',
      FoodItem.fromJson,
    );
    final savedFavorites = await store.readStringList('favorites');
    final savedRecent = await store.readStringList('recent');
    if (!prefs.containsKey('water_migrated')) {
      if (!prefs.containsKey('water_$key')) {
        await prefs.setDouble(
          'water_$key',
          store.number('water', 0, allowZero: true),
        );
      }
      await prefs.setBool('water_migrated', true);
    }

    return (
      store: store,
      diary: savedDiary,
      foods: savedFoods,
      favorites: savedFavorites,
      recent: savedRecent,
    );
  }

  Future<void> _saveDiary() async {
    final key = 'diary_$dayKey';
    final value = jsonEncode(diary.map((item) => item.toJson()).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
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
    if (loadFailed) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_rounded, size: 48, color: green),
                  const SizedBox(height: 20),
                  Text(
                    'Не удалось открыть дневник',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Локальное хранилище не ответило. Попробуйте ещё раз. '
                    'Мы не удаляли ваши записи.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final pages = <Widget>[
      _todayPage(),
      _foodPage(),
      _cameraPage(),
      _progressPage(),
      _profilePage(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(index: tab, children: pages),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          backgroundColor: Colors.white,
          indicatorColor: mint,
          onDestinationSelected: (index) => setState(() => tab = index),
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
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt),
              label: 'Камера',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Прогресс',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
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
      ),
    );
  }

  Widget _header(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        const SizedBox(height: 6),
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

  Widget _todayPage() {
    return ListView(
      key: const PageStorageKey('today'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.spa_outlined, color: greenDark, size: 23),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'FITLIFE',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'База продуктов',
              onPressed: _openCatalog,
              icon: const Icon(Icons.manage_search_outlined),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Твой день,\nв балансе.',
          style: TextStyle(
            fontSize: 34,
            height: 1.15,
            letterSpacing: -1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _chooseDay,
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(_dateLabel()),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ),
        const SizedBox(height: 14),
        _quickMealActions(),
        const SizedBox(height: 16),
        DayNutritionSummary(calories: calories, target: kcalTarget),
        const SizedBox(height: 16),
        Row(
          children: [
            MacroProgress(
              title: 'Белки',
              value: protein,
              target: proteinTarget,
              color: green,
            ),
            const SizedBox(width: 8),
            MacroProgress(
              title: 'Жиры',
              value: fat,
              target: fatTarget,
              color: gold,
            ),
            const SizedBox(width: 8),
            MacroProgress(
              title: 'Углеводы',
              value: carbs,
              target: carbsTarget,
              color: coral,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _statCard(
              'Вода',
              '${water.toStringAsFixed(2)} л',
              Icons.water_drop_outlined,
              _addWater,
            ),
            const SizedBox(width: 8),
            _statCard(
              'Вес',
              '${weight.toStringAsFixed(1)} кг',
              Icons.monitor_weight_outlined,
              _addWeight,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _card(
          Row(
            children: [
              const CompanionAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Твой помощник',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      diary.isEmpty
                          ? 'Начнём с первого приёма пищи?'
                          : 'Каждая запись помогает видеть баланс.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (recoveredData) ...[
          const SizedBox(height: 12),
          const Text(
            'Часть записей повреждена. Доступные записи восстановлены, исходные данные сохранены для восстановления.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        _nextAction(),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Дневник питания',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${diary.length} записей',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (diary.isEmpty) _emptyCard() else ..._mealCards(),
      ],
    );
  }

  Widget _foodPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        _header('Питание', 'Поиск, избранное и последние продукты'),
        const SizedBox(height: 14),
        _quickMealActions(),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${calories.round()} ккал',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
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
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _openCatalog,
          icon: const Icon(Icons.manage_search_outlined),
          label: const Text('Расширенный состав продуктов'),
        ),
        const SizedBox(height: 14),
        if (diary.isNotEmpty) ..._mealCards(),
      ],
    );
  }

  Widget _cameraPage() {
    return PhotoPage(
      day: day,
      meal: _suggestedMeal(),
      onManual: _addFood,
      onSave: _savePhotoMeal,
    );
  }

  Widget _quickMealActions() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'БЫСТРАЯ ЗАПИСЬ',
          style: TextStyle(
            fontSize: 10,
            color: muted,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _entryAction(
              'Описать еду',
              Icons.edit_note_rounded,
              _describeMeal,
              'quick-text',
            ),
            const SizedBox(width: 8),
            _entryAction(
              'Фото блюда',
              Icons.photo_camera_outlined,
              () => setState(() => tab = 2),
              'quick-photo',
            ),
            const SizedBox(width: 8),
            _entryAction(
              'Найти продукт',
              Icons.search,
              _addFood,
              'quick-search',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _entryAction(
    String label,
    IconData icon,
    VoidCallback action,
    String key,
  ) => Expanded(
    child: InkWell(
      key: Key(key),
      onTap: action,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: mint.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: greenDark),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _describeMeal() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TextMealPage(
          day: day,
          meal: _suggestedMeal(),
          onSave: _savePhotoMeal,
        ),
      ),
    );
  }

  Future<void> _showWeeklyReport() async {
    final selected = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => WeeklySummaryPage(
          end: day,
          preferencesLoader: widget.preferencesLoader,
        ),
      ),
    );
    if (!mounted || selected == null || DateUtils.isSameDay(selected, day)) {
      return;
    }
    setState(() {
      day = selected;
      tab = 0;
    });
    await _load();
  }

  Widget _progressPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        _header('Прогресс', 'Устойчивость важнее идеального дня'),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _showWeeklyReport,
          icon: const Icon(Icons.calendar_view_week_outlined),
          label: const Text('Обзор 7 дней'),
        ),
        const SizedBox(height: 14),
        _card(
          Column(
            children: [
              _progressLine(
                'Калории',
                calories / kcalTarget,
                '${calories.round()} / ${kcalTarget.round()} ккал',
              ),
              const SizedBox(height: 14),
              _progressLine(
                'Белок',
                protein / proteinTarget,
                '${protein.round()} / ${proteinTarget.round()} г',
              ),
              const SizedBox(height: 14),
              _progressLine(
                'Жиры',
                fat / fatTarget,
                '${fat.round()} / ${fatTarget.round()} г',
              ),
              const SizedBox(height: 14),
              _progressLine(
                'Клетчатка',
                fiber / fiberTarget,
                '${fiber.round()} / ${fiberTarget.round()} г',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          const Row(
            children: [
              CompanionAvatar(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Панда растёт вместе с привычками',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Сейчас важнее регулярность, чем идеальный результат за один день.',
                      style: TextStyle(color: muted),
                    ),
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
              const Text(
                'Текущие настройки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              _profileRow('Вес', '${weight.toStringAsFixed(1)} кг'),
              _profileRow('Цель по калориям', '${kcalTarget.round()} ккал'),
              _profileRow('Белок', '${proteinTarget.round()} г'),
              _profileRow('Жиры', '${fatTarget.round()} г'),
              _profileRow('Клетчатка', '${fiberTarget.round()} г'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _editGoals,
                icon: const Icon(Icons.tune),
                label: const Text('Настроить цели'),
              ),
              TextButton.icon(
                onPressed: _addWeight,
                icon: const Icon(Icons.monitor_weight_outlined),
                label: const Text('Обновить вес'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          const Text(
            'Твой дневник хранится на этом устройстве и работает без интернета. Анализ фото использует интернет и общий сервер; отправка только с твоего согласия.',
            style: TextStyle(color: muted),
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const PhotoSettingsPage()),
          ),
          icon: const Icon(Icons.cloud_outlined),
          label: const Text('Распознавание по фото'),
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
          Expanded(
            child: Text(name, style: const TextStyle(color: muted)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, color: ink),
          ),
        ],
      ),
    );
  }

  Widget _progressLine(String title, double value, String label) {
    final safeValue = value.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, color: ink),
            ),
            Text(label, style: const TextStyle(color: muted)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: safeValue,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: _card(
          Column(
            children: [
              Icon(icon, color: greenDark),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900, color: ink),
              ),
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800, color: ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return _card(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Здесь появятся продукты и приёмы пищи.',
          style: TextStyle(color: muted),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: ink,
        ),
      ),
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
            Text(
              meal,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  item.food.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${item.food.isTextEstimate
                      ? 'AI-оценка по описанию · '
                      : item.food.isPhotoEstimate
                      ? 'Оценка по фото · '
                      : ''}${item.grams.round()} г · ${item.kcal.round()} ккал · Б ${item.protein.round()} г · Кл ${item.fiber.round()} г',
                ),
                trailing: IconButton(
                  tooltip: 'Изменить порцию',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editDiaryItem(item),
                ),
              ),
            ),
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
    const months = [
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
    final date = '${day.day} ${months[day.month - 1]} ${day.year}';
    return DateUtils.isSameDay(day, DateTime.now()) ? 'Сегодня, $date' : date;
  }

  Future<void> _chooseDay() async {
    final result = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'День дневника',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );
    if (!mounted || result == null || DateUtils.isSameDay(day, result)) return;
    setState(() {
      day = result;
      loading = true;
    });
    await _load();
  }

  String _suggestedMeal() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Завтрак';
    if (hour < 16) return 'Обед';
    if (hour < 21) return 'Ужин';
    return 'Перекус';
  }

  Future<void> _openCatalog() async {
    final entries = diary
        .map(
          (entry) => NutritionDayEntry(
            food: NutritionFoodRecord(
              id: entry.food.id,
              name: entry.food.name,
              source: '',
              sourceUrl: '',
              profile: entry.food.profile,
            ),
            grams: entry.grams,
          ),
        )
        .toList();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NutritionCatalogPage(
          initialDay: NutritionDay(entries: entries),
          dayLabel: _dateLabel(),
          onAdd: (entry) async {
            if (!mounted) return;
            final record = entry.food;
            final p = record.profile;
            final food = FoodItem(
              id: 'catalog_${record.id}',
              name: record.name,
              kcal: p.kcal,
              protein: p.protein,
              fat: p.fat,
              carbs: p.carbs,
              fiber: p.fiber,
              nutrition: p,
            );
            setState(() {
              if (_foodById(food.id) == null) customFoods.add(food);
              diary.add(
                DiaryItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  meal: _suggestedMeal(),
                  food: food,
                  grams: entry.grams,
                  time: TimeOfDay.now().format(context),
                ),
              );
            });
            await _saveDiary();
            await _saveFoods();
          },
        ),
      ),
    );
  }

  Future<void> _savePhotoMeal(PhotoMeal meal) async {
    final saved = await savePhotoMeal(
      meal,
      preferencesLoader: widget.preferencesLoader,
    ).timeout(const Duration(seconds: 15));
    if (mounted && DateUtils.isSameDay(day, meal.day)) {
      setState(() => diary = saved);
    }
  }

  Future<void> _addFood({FoodItem? preselected}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FoodEntrySheet(
        foods: foods,
        favorites: favorites,
        preselected: preselected,
        initialMeal: _suggestedMeal(),
        onFavorite: (food) {
          setState(() {
            if (favorites.contains(food.id)) {
              favorites.remove(food.id);
            } else {
              favorites.add(food.id);
            }
          });
          _saveLists();
        },
        onAdd: (food, grams, meal) async {
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
            recent = [
              food.id,
              ...recent.where((id) => id != food.id),
            ].take(10).toList();
          });
          await _saveDiary();
          await _saveLists();
        },
      ),
    );
  }

  Future<void> _editDiaryItem(DiaryItem item) async {
    final result = await showDialog<ValueEditResult>(
      context: context,
      builder: (_) => ValueEditorDialog(
        title: item.food.name,
        allowDelete: true,
        fields: [NumberFieldSpec('Граммы', item.grams, min: 0.1)],
      ),
    );
    if (!mounted || result == null) return;
    final index = diary.indexWhere((entry) => entry.id == item.id);
    if (index < 0) return;
    setState(() {
      if (result.deleted) {
        diary.removeAt(index);
      } else {
        diary[index] = DiaryItem(
          id: item.id,
          meal: item.meal,
          food: item.food,
          grams: result.values.first,
          time: item.time,
        );
      }
    });
    await _saveDiary();
  }

  Future<void> _addCustomFood() async {
    final result = await showDialog<ValueEditResult>(
      context: context,
      builder: (_) => const ValueEditorDialog(
        title: 'Свой продукт',
        initialName: '',
        fields: [
          NumberFieldSpec('Ккал / 100 г', 0),
          NumberFieldSpec('Белок / 100 г', 0, max: 100),
          NumberFieldSpec('Жиры / 100 г', 0, max: 100),
          NumberFieldSpec('Углеводы / 100 г', 0, max: 100),
          NumberFieldSpec('Клетчатка / 100 г', 0, max: 100),
        ],
      ),
    );
    if (!mounted || result == null) return;
    final v = result.values;
    setState(
      () => customFoods.add(
        FoodItem(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          name: result.name!,
          kcal: v[0],
          protein: v[1],
          fat: v[2],
          carbs: v[3],
          fiber: v[4],
        ),
      ),
    );
    await _saveFoods();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Продукт сохранён и доступен в поиске')),
    );
  }

  Future<void> _editGoals() async {
    final result = await showDialog<ValueEditResult>(
      context: context,
      builder: (_) => ValueEditorDialog(
        title: 'Цели питания',
        fields: [
          NumberFieldSpec('Калории, ккал', kcalTarget, min: 1),
          NumberFieldSpec('Белок, г', proteinTarget, min: 1, max: 1000),
          NumberFieldSpec('Жиры, г', fatTarget, min: 1, max: 1000),
          NumberFieldSpec('Клетчатка, г', fiberTarget, min: 1, max: 1000),
        ],
        validate: (v) => v[1] * 4 + v[2] * 9 > v[0]
            ? 'Калории из белков и жиров превышают дневную цель.'
            : null,
      ),
    );
    if (!mounted || result == null) return;
    final v = result.values;
    setState(() {
      kcalTarget = v[0];
      proteinTarget = v[1];
      fatTarget = v[2];
      fiberTarget = v[3];
    });
    await _setNumber('goal_calories', v[0]);
    await _setNumber('goal_protein', v[1]);
    await _setNumber('goal_fat', v[2]);
    await _setNumber('goal_fiber', v[3]);
  }

  Future<void> _addWater() async {
    final next = water + 0.25;
    setState(() => water = next);
    await _setNumber('water_$dayKey', next);
  }

  Future<void> _addWeight() async {
    final result = await showDialog<ValueEditResult>(
      context: context,
      builder: (_) => ValueEditorDialog(
        title: 'Вес',
        fields: [NumberFieldSpec('Вес, кг', weight, min: 30, max: 300)],
      ),
    );
    if (!mounted || result == null) return;
    final value = result.values.first;
    setState(() => weight = value);
    await _setNumber('weight', value);
  }
}

class _FoodEntrySheet extends StatefulWidget {
  const _FoodEntrySheet({
    required this.foods,
    required this.favorites,
    required this.initialMeal,
    required this.onFavorite,
    required this.onAdd,
    this.preselected,
  });

  final List<FoodItem> foods;
  final List<String> favorites;
  final FoodItem? preselected;
  final String initialMeal;
  final ValueChanged<FoodItem> onFavorite;
  final Future<void> Function(FoodItem, double, String) onAdd;

  @override
  State<_FoodEntrySheet> createState() => _FoodEntrySheetState();
}

class _FoodEntrySheetState extends State<_FoodEntrySheet> {
  final _grams = TextEditingController(text: '100');
  late FoodItem? _selected = widget.preselected;
  late String _meal = widget.initialMeal;
  String _query = '';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final grams = double.tryParse(_grams.text.trim().replaceAll(',', '.'));
    if (grams == null || !grams.isFinite || grams <= 0 || grams > 10000) {
      setState(() => _error = 'Введи порцию от 0 до 10 000 г');
      return;
    }
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    await widget.onAdd(_selected!, grams, _meal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.foods
        .where(
          (food) => food.name
              .toLowerCase()
              .replaceAll('ё', 'е')
              .contains(_query.trim().toLowerCase().replaceAll('ё', 'е')),
        )
        .toList();
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: line,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Что было на тарелке?',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Выбери продукт и укажи свою порцию',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск продукта',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * 0.25).clamp(
              100.0,
              230.0,
            ),
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Ничего не найдено. Можно создать свой продукт.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final food = filtered[index];
                      final favorite = widget.favorites.contains(food.id);
                      return ListTile(
                        selected: _selected?.id == food.id,
                        selectedTileColor: mint,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        leading: Icon(
                          _selected?.id == food.id
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _selected?.id == food.id ? green : muted,
                          size: 22,
                        ),
                        title: Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${food.kcal.round()} ккал на 100 г',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          tooltip: favorite
                              ? 'Убрать из избранного'
                              : 'В избранное',
                          icon: Icon(
                            favorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: gold,
                          ),
                          onPressed: () {
                            widget.onFavorite(food);
                            setState(() {});
                          },
                        ),
                        onTap: () => setState(() => _selected = food),
                      );
                    },
                  ),
          ),
          if (_selected != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Выбрано: ${_selected!.name}',
                style: const TextStyle(
                  color: greenDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _grams,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Граммы',
                    errorText: _error,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _meal,
                  isExpanded: true,
                  items: const ['Завтрак', 'Обед', 'Ужин', 'Перекус']
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _meal = value ?? _meal),
                  decoration: const InputDecoration(labelText: 'Приём пищи'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _selected == null || _saving ? null : _add,
            icon: const Icon(Icons.add),
            label: Text(_saving ? 'Сохраняем...' : 'Добавить'),
          ),
        ],
      ),
    );
  }
}
