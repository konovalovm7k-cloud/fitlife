import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/fitlife_theme.dart';
import 'app/bootstrap.dart';
import 'app/fitlife_app_frame.dart';
import 'app/nutrition_goal_format.dart';
import 'app/state/fitlife_controller.dart';
import 'app/state/fitlife_state.dart';
import 'app/widgets/day_nutrition_summary.dart';
import 'app/widgets/companion_avatar.dart';
import 'app/widgets/value_editor.dart';
import 'core/models/diary_item.dart';
import 'core/models/nutrition_goal_settings.dart';
import 'core/nutrition/nutrition_catalog_page.dart';
import 'features/photo_analysis/photo_models.dart';
import 'features/photo_analysis/photo_page.dart';
import 'features/photo_analysis/photo_settings_page.dart';

export 'core/models/diary_item.dart';
export 'data/built_in_foods.dart';

class ModernFitLifeApp extends StatelessWidget {
  const ModernFitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitLifeAppFrame(home: FitLifeHome());
  }
}

class FitLifeHome extends StatefulWidget {
  const FitLifeHome({super.key, this.preferencesLoader, this.controller})
    : assert(preferencesLoader == null || controller == null);

  // Retained for existing embedders and startup tests; storage stays in bootstrap.
  final PreferencesLoader? preferencesLoader;
  final FitLifeController? controller;

  @override
  State<FitLifeHome> createState() => _FitLifeHomeState();
}

class _FitLifeHomeState extends State<FitLifeHome> with WidgetsBindingObserver {
  late FitLifeController _controller;
  late bool _ownsController;
  int tab = 0;

  FitLifeState get data => _controller.state;
  double get kcalTarget => data.goals.calories;
  double get proteinTarget => data.goals.protein;
  double get fatTarget => data.goals.fat;
  double get fiberTarget => data.goals.fiber;
  double get carbsTarget => data.carbsTarget;
  double get water => data.water;
  double get weight => data.weight;
  bool get loading => data.status == FitLifeLoadStatus.loading;
  bool get loadFailed => data.status == FitLifeLoadStatus.failed;
  bool get recoveredData => data.recoveredData;
  DateTime get day => data.day;
  List<DiaryItem> get diary => data.diary;
  List<String> get favorites => data.favorites;
  List<String> get recent => data.recent;
  List<FoodItem> get foods => _controller.foods;
  double get calories => data.total.calories;
  double get protein => data.total.protein;
  double get fat => data.total.fat;
  double get carbs => data.total.carbs;
  double get fiber => data.total.fiber;
  double get caloriesLeft => data.caloriesLeft;

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _attachController() {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        createFitLifeController(preferencesLoader: widget.preferencesLoader);
    _controller.addListener(_refresh);
    unawaited(_controller.initialize());
  }

  void _detachController() {
    _controller.removeListener(_refresh);
    if (_ownsController) _controller.dispose();
  }

  @override
  void initState() {
    super.initState();
    _attachController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant FitLifeHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.preferencesLoader != oldWidget.preferencesLoader) {
      _detachController();
      _attachController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_controller.resume());
  }

  Future<void> _load() => _controller.load();

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

  Widget _progressPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        _header('Прогресс', 'Устойчивость важнее идеального дня'),
        const SizedBox(height: 14),
        _card(
          Column(
            children: [
              _progressLine(
                'Калории',
                calories / kcalTarget,
                '${calories.round()} / ${formatNutritionGoal(kcalTarget)} ккал',
              ),
              const SizedBox(height: 14),
              _progressLine(
                'Белок',
                protein / proteinTarget,
                '${protein.round()} / ${formatNutritionGoal(proteinTarget)} г',
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
              _profileRow(
                'Цель по калориям',
                '${formatNutritionGoal(kcalTarget)} ккал',
              ),
              _profileRow('Белок', '${formatNutritionGoal(proteinTarget)} г'),
              _profileRow('Жиры', '${formatNutritionGoal(fatTarget)} г'),
              _profileRow('Углеводы', '${formatNutritionGoal(carbsTarget)} г'),
              _profileRow('Клетчатка', '${formatNutritionGoal(fiberTarget)} г'),
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
                  '${item.food.isPhotoEstimate ? 'Оценка по фото · ' : ''}${item.grams.round()} г · ${item.kcal.round()} ккал · Б ${item.protein.round()} г · Кл ${item.fiber.round()} г',
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
    return _controller.isToday ? 'Сегодня, $date' : date;
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
    await _controller.selectDay(result);
  }

  String _suggestedMeal() => _controller.suggestedMeal;

  Future<void> _openCatalog() async {
    final targetDay = day;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NutritionCatalogPage(
          initialDay: _controller.nutritionDay,
          dayLabel: _dateLabel(),
          onAdd: (entry) async {
            if (!mounted) return;
            await _controller.addCatalogFood(
              targetDay,
              entry.food,
              grams: entry.grams,
              meal: _suggestedMeal(),
              time: TimeOfDay.fromDateTime(_controller.now).format(context),
            );
          },
        ),
      ),
    );
  }

  Future<void> _savePhotoMeal(PhotoMeal meal) => _controller.savePhoto(meal);

  Future<void> _addFood({FoodItem? preselected}) async {
    final targetDay = day;
    final entryId = _controller.newId();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FoodEntrySheet(
        foods: foods,
        favorites: favorites,
        preselected: preselected,
        initialMeal: _suggestedMeal(),
        onFavorite: (food, selected) =>
            _controller.setFavorite(food.id, selected),
        onAdd: (food, grams, meal) async {
          final recentSaved = await _controller.addMeal(
            targetDay,
            DiaryItem(
              id: entryId,
              meal: meal,
              food: food,
              grams: grams,
              time: TimeOfDay.fromDateTime(_controller.now).format(context),
            ),
          );
          if (recentSaved || !mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Еда сохранена, но список последних продуктов обновить не удалось.',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editDiaryItem(DiaryItem item) async {
    final targetDay = day;
    await showDialog<ValueEditResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueEditorDialog(
        title: item.food.name,
        allowDelete: true,
        fields: [NumberFieldSpec('Граммы', item.grams, min: 0.1)],
        onSave: (result) => _controller.editEntry(
          targetDay,
          DiaryItem(
            id: item.id,
            meal: item.meal,
            food: item.food,
            grams: result.deleted ? item.grams : result.values.first,
            time: item.time,
          ),
          delete: result.deleted,
        ),
      ),
    );
  }

  Future<void> _addCustomFood() async {
    final id = _controller.newId(prefix: 'custom_');
    final result = await showDialog<ValueEditResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueEditorDialog(
        title: 'Свой продукт',
        initialName: '',
        fields: const [
          NumberFieldSpec('Ккал / 100 г', 0),
          NumberFieldSpec('Белок / 100 г', 0, max: 100),
          NumberFieldSpec('Жиры / 100 г', 0, max: 100),
          NumberFieldSpec('Углеводы / 100 г', 0, max: 100),
          NumberFieldSpec('Клетчатка / 100 г', 0, max: 100),
        ],
        onSave: (result) async {
          final v = result.values;
          await _controller.saveFood(
            FoodItem(
              id: id,
              name: result.name!,
              kcal: v[0],
              protein: v[1],
              fat: v[2],
              carbs: v[3],
              fiber: v[4],
            ),
          );
        },
      ),
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Продукт сохранён и доступен в поиске')),
    );
  }

  Future<void> _editGoals() async {
    NutritionGoalSettings goalsFrom(List<double> values) =>
        NutritionGoalSettings(
          calories: values[0],
          protein: values[1],
          fat: values[2],
          fiber: values[3],
        );
    await showDialog<ValueEditResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueEditorDialog(
        title: 'Цели питания',
        fields: [
          NumberFieldSpec(
            'Калории, ккал',
            kcalTarget,
            min: NutritionGoalSettings.minValue,
            max: NutritionGoalSettings.maxCalories,
          ),
          NumberFieldSpec(
            'Белок, г',
            proteinTarget,
            min: NutritionGoalSettings.minValue,
            max: NutritionGoalSettings.maxGrams,
          ),
          NumberFieldSpec(
            'Жиры, г',
            fatTarget,
            min: NutritionGoalSettings.minValue,
            max: NutritionGoalSettings.maxGrams,
          ),
          NumberFieldSpec(
            'Клетчатка, г',
            fiberTarget,
            min: NutritionGoalSettings.minValue,
            max: NutritionGoalSettings.maxGrams,
          ),
        ],
        validate: (v) => goalsFrom(v).validationError,
        summaryBuilder: (v) {
          final goals = goalsFrom(v);
          if (goals.validationError != null) return null;
          return 'Углеводы: ${formatNutritionGoal(goals.carbs)} г. '
              'Рассчитаны из оставшихся калорий.';
        },
        onSave: (result) => _controller.saveGoals(goalsFrom(result.values)),
      ),
    );
  }

  Future<void> _addWater() async {
    final targetDay = day;
    try {
      await _controller.addWater(targetDay);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить воду. Попробуй ещё раз.'),
        ),
      );
    }
  }

  Future<void> _addWeight() async {
    await showDialog<ValueEditResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueEditorDialog(
        title: 'Вес',
        fields: [NumberFieldSpec('Вес, кг', weight, min: 30, max: 300)],
        onSave: (result) async {
          final value = result.values.first;
          await _controller.saveWeight(value);
        },
      ),
    );
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
  final Future<List<String>> Function(FoodItem, bool) onFavorite;
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
  late List<String> _favorites = [...widget.favorites];
  bool _favoriteSaving = false;
  String? _favoriteError;

  Future<void> _toggleFavorite(FoodItem food) async {
    if (_favoriteSaving) return;
    final selected = !_favorites.contains(food.id);
    setState(() {
      _favoriteSaving = true;
      _favoriteError = null;
    });
    try {
      final saved = await widget.onFavorite(food, selected);
      if (mounted) setState(() => _favorites = saved);
    } catch (_) {
      if (mounted) {
        setState(
          () => _favoriteError =
              'Не удалось сохранить избранное. Попробуй ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _favoriteSaving = false);
    }
  }

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
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onAdd(_selected!, grams, _meal);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Не удалось сохранить. Проверь свободное место и повтори.';
      });
    }
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
          if (_favoriteError != null)
            Text(
              _favoriteError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
                      final favorite = _favorites.contains(food.id);
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
                          onPressed: _favoriteSaving || _saving
                              ? null
                              : () => _toggleFavorite(food),
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
