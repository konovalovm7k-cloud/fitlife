import 'package:shared_preferences/shared_preferences.dart';

import '../../app/state/fitlife_repository.dart';
import '../../app/state/fitlife_state.dart';
import '../../core/models/diary_date.dart';
import '../../core/models/diary_item.dart';
import '../../core/models/nutrition_goal_settings.dart';
import '../../features/photo_analysis/photo_diary.dart' as photo_diary;
import '../../features/photo_analysis/photo_models.dart';
import 'diary_repository.dart';
import 'settings_repository.dart';

typedef PreferencesLoader = Future<SharedPreferences> Function();

class LocalFitLifeRepository implements FitLifeRepository {
  LocalFitLifeRepository({PreferencesLoader? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;
  final PreferencesLoader _preferencesLoader;

  Future<SettingsRepository> _settings() async =>
      SettingsRepository(await _preferencesLoader());

  @override
  Future<FitLifeState> loadDay(DateTime day, {required DateTime today}) async {
    final saved = await (await _settings()).load(
      DiaryDate.key(day),
      todayKey: DiaryDate.key(today),
    );
    return FitLifeState(
      day: day,
      status: FitLifeLoadStatus.ready,
      goals: saved.goals,
      water: saved.water,
      weight: saved.weight,
      diary: saved.diary,
      customFoods: saved.foods,
      favorites: saved.favorites,
      recent: saved.recent,
      recoveredData: saved.recoveredData,
    );
  }

  @override
  Future<List<DiaryItem>> saveEntry(DateTime day, DiaryItem entry) async =>
      DiaryRepository(
        await _preferencesLoader(),
      ).upsert('diary_${DiaryDate.key(day)}', entry);

  @override
  Future<List<DiaryItem>> editEntry(
    DateTime day,
    DiaryItem entry, {
    bool delete = false,
  }) async => DiaryRepository(await _preferencesLoader()).update(
    'diary_${DiaryDate.key(day)}',
    (current) {
      if (!current.any((item) => item.id == entry.id)) {
        throw StateError('Diary entry no longer exists');
      }
      if (delete) return current.where((item) => item.id != entry.id).toList();
      return current.map((item) => item.id == entry.id ? entry : item).toList();
    },
  );

  @override
  Future<List<DiaryItem>> savePhoto(PhotoMeal meal) =>
      photo_diary.savePhotoMeal(meal, preferencesLoader: _preferencesLoader);
  @override
  Future<List<FoodItem>> saveFood(FoodItem food) async =>
      (await _settings()).upsertFood(food);
  @override
  Future<List<String>> setFavorite(String id, bool selected) async =>
      (await _settings()).setFavorite(id, selected);
  @override
  Future<List<String>> rememberFood(String id) async =>
      (await _settings()).rememberFood(id);
  @override
  Future<void> saveGoals(NutritionGoalSettings goals) async =>
      (await _settings()).saveGoals(goals);
  @override
  Future<double> addWater(DateTime day, double amount) async =>
      (await _settings()).addWater(DiaryDate.key(day), amount);
  @override
  Future<void> saveWeight(double value) async =>
      (await _settings()).saveWeight(value);
}
