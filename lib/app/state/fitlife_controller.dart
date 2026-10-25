import 'package:flutter/foundation.dart';

import '../../core/models/diary_date.dart';
import '../../core/models/diary_item.dart';
import '../../core/models/nutrition_goal_settings.dart';
import '../../core/nutrition/nutrition_database.dart';
import '../../core/nutrition/nutrition_day.dart';
import '../../data/built_in_foods.dart';
import '../../features/photo_analysis/photo_models.dart';
import 'fitlife_repository.dart';
import 'fitlife_state.dart';

class FitLifeController extends ChangeNotifier {
  FitLifeController({
    required this.repository,
    DateTime Function()? clock,
    this.loadTimeout = const Duration(seconds: 15),
  }) : _clock = clock ?? DateTime.now {
    _lastToday = DiaryDate.only(now);
    _state = FitLifeState(day: _lastToday);
  }

  final FitLifeRepository repository;
  final DateTime Function() _clock;
  final Duration loadTimeout;
  late FitLifeState _state;
  late DateTime _lastToday;
  bool _disposed = false;
  bool _started = false;
  int _loadAttempt = 0;
  int _revision = 0;
  int _idSequence = 0;

  FitLifeState get state => _state;
  DateTime get now => _clock();
  bool get isToday => DiaryDate.same(state.day, now);
  List<FoodItem> get foods =>
      List.unmodifiable([...builtInFoods, ...state.customFoods]);
  String newId({String prefix = ''}) =>
      '$prefix${now.microsecondsSinceEpoch}_${_idSequence++}';
  String get suggestedMeal {
    final hour = now.hour;
    if (hour < 11) return 'Завтрак';
    if (hour < 16) return 'Обед';
    if (hour < 21) return 'Ужин';
    return 'Перекус';
  }

  void _publish(FitLifeState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  void _requireReady() {
    if (_disposed || state.status != FitLifeLoadStatus.ready) {
      throw StateError('Diary is not ready');
    }
  }

  Future<void> initialize() async {
    if (_started || _disposed) return;
    await load();
  }

  Future<void> load() async {
    if (_disposed) return;
    _started = true;
    final day = state.day;
    final attempt = ++_loadAttempt;
    final revision = _revision;
    _publish(state.copyWith(status: FitLifeLoadStatus.loading));
    try {
      final saved = await repository
          .loadDay(day, today: DiaryDate.only(now))
          .timeout(loadTimeout);
      if (_disposed ||
          attempt != _loadAttempt ||
          !DiaryDate.same(day, state.day)) {
        return;
      }
      if (revision != _revision) {
        // A save completed after this snapshot was requested. Read fresh data.
        await load();
        return;
      }
      _publish(saved.copyWith(day: day, status: FitLifeLoadStatus.ready));
    } catch (error) {
      if (_disposed ||
          attempt != _loadAttempt ||
          !DiaryDate.same(day, state.day)) {
        return;
      }
      if (revision != _revision) {
        await load();
        return;
      }
      debugPrint('FitLife storage initialization failed: ${error.runtimeType}');
      _publish(state.copyWith(status: FitLifeLoadStatus.failed));
    }
  }

  Future<void> selectDay(DateTime day) async {
    if (_disposed || DiaryDate.same(day, state.day)) return;
    _publish(
      state.copyWith(
        day: day,
        diary: [],
        water: 0,
        status: FitLifeLoadStatus.loading,
      ),
    );
    await load();
  }

  Future<void> resume() async {
    if (_disposed) return;
    final today = DiaryDate.only(now);
    if (DiaryDate.same(today, _lastToday)) return;
    final followToday = DiaryDate.same(state.day, _lastToday);
    _lastToday = today;
    if (followToday) await selectDay(today);
  }

  void _publishDiary(DateTime day, List<DiaryItem> entries) {
    _revision++;
    if (DiaryDate.same(day, state.day)) {
      _publish(state.copyWith(diary: entries));
    }
  }

  Future<void> saveEntry(DateTime day, DiaryItem entry) async {
    _requireReady();
    final saved = await repository.saveEntry(day, entry);
    _publishDiary(day, saved);
  }

  /// false means the meal is committed but its optional recent-food hint failed.
  Future<bool> addMeal(DateTime day, DiaryItem entry) async {
    await saveEntry(day, entry);
    if (_disposed) return true;
    try {
      final recent = await repository.rememberFood(entry.food.id);
      _revision++;
      _publish(state.copyWith(recent: recent));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> editEntry(
    DateTime day,
    DiaryItem entry, {
    bool delete = false,
  }) async {
    _requireReady();
    _publishDiary(day, await repository.editEntry(day, entry, delete: delete));
  }

  Future<List<String>> setFavorite(String id, bool selected) async {
    _requireReady();
    final favorites = await repository.setFavorite(id, selected);
    _revision++;
    _publish(state.copyWith(favorites: favorites));
    return List.unmodifiable(favorites);
  }

  Future<void> saveFood(FoodItem food) async {
    _requireReady();
    final saved = await repository.saveFood(food);
    _revision++;
    _publish(state.copyWith(customFoods: saved));
  }

  Future<void> saveGoals(NutritionGoalSettings goals) async {
    _requireReady();
    goals.validate();
    await repository.saveGoals(goals);
    _revision++;
    _publish(state.copyWith(goals: goals));
  }

  Future<void> addWater(DateTime day, {double amount = 0.25}) async {
    _requireReady();
    final water = await repository.addWater(day, amount);
    _revision++;
    if (DiaryDate.same(day, state.day)) _publish(state.copyWith(water: water));
  }

  Future<void> saveWeight(double value) async {
    _requireReady();
    await repository.saveWeight(value);
    _revision++;
    _publish(state.copyWith(weight: value));
  }

  Future<void> savePhoto(PhotoMeal meal) async {
    _requireReady();
    final saved = await repository.savePhoto(meal).timeout(loadTimeout);
    _publishDiary(meal.day, saved);
  }

  NutritionDay get nutritionDay => NutritionDay(
    entries: state.diary
        .map(
          (entry) => NutritionDayEntry(
            food: NutritionFoodRecord(
              id: entry.food.id,
              name: entry.food.name,
              source: '',
              sourceUrl: '',
              profile: entry.food.profile,
              macrosOnly: !entry.food.hasKnownFiber,
            ),
            grams: entry.grams,
          ),
        )
        .toList(growable: false),
  );

  Future<void> addCatalogFood(
    DateTime day,
    NutritionFoodRecord record, {
    required double grams,
    String? entryId,
    required String meal,
    required String time,
  }) async {
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
      hasKnownFiber: !record.macrosOnly,
    );
    if (!foods.any((item) => item.id == food.id)) await saveFood(food);
    if (_disposed) return;
    await saveEntry(
      day,
      DiaryItem(
        id: entryId ?? newId(),
        meal: meal,
        food: food,
        grams: grams,
        time: time,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _loadAttempt++;
    super.dispose();
  }
}
