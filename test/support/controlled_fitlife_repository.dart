import 'package:fitlife/app/state/fitlife_repository.dart';
import 'package:fitlife/app/state/fitlife_state.dart';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/core/models/nutrition_goal_settings.dart';
import 'package:fitlife/data/repositories/local_fitlife_repository.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';

/// Intercepts timing for race tests; actual data operations use real repositories.
class ControlledFitLifeRepository implements FitLifeRepository {
  final local = LocalFitLifeRepository();
  Future<FitLifeState> Function(DateTime, DateTime)? onLoad;
  Future<List<DiaryItem>> Function(DateTime, DiaryItem)? onEntry;
  Future<double> Function(DateTime, double)? onWater;
  Future<void> Function(NutritionGoalSettings)? onGoals;
  Future<List<DiaryItem>> Function(PhotoMeal)? onPhoto;
  int loads = 0;

  @override
  Future<FitLifeState> loadDay(DateTime day, {required DateTime today}) {
    loads++;
    return onLoad?.call(day, today) ?? local.loadDay(day, today: today);
  }

  @override
  Future<List<DiaryItem>> saveEntry(DateTime day, DiaryItem entry) =>
      onEntry?.call(day, entry) ?? local.saveEntry(day, entry);
  @override
  Future<List<DiaryItem>> editEntry(
    DateTime day,
    DiaryItem entry, {
    bool delete = false,
  }) => local.editEntry(day, entry, delete: delete);
  @override
  Future<List<DiaryItem>> savePhoto(PhotoMeal meal) =>
      onPhoto?.call(meal) ?? local.savePhoto(meal);
  @override
  Future<List<FoodItem>> saveFood(FoodItem food) => local.saveFood(food);
  @override
  Future<List<String>> setFavorite(String id, bool selected) =>
      local.setFavorite(id, selected);
  @override
  Future<List<String>> rememberFood(String id) => local.rememberFood(id);
  @override
  Future<void> saveGoals(NutritionGoalSettings goals) =>
      onGoals?.call(goals) ?? local.saveGoals(goals);
  @override
  Future<double> addWater(DateTime day, double amount) =>
      onWater?.call(day, amount) ?? local.addWater(day, amount);
  @override
  Future<void> saveWeight(double value) => local.saveWeight(value);
}
