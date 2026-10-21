import '../../core/models/diary_item.dart';
import '../../core/models/nutrition_goal_settings.dart';
import '../../features/photo_analysis/photo_models.dart';
import 'fitlife_state.dart';

/// The application talks in dates and models, never preference keys.
abstract interface class FitLifeRepository {
  Future<FitLifeState> loadDay(DateTime day, {required DateTime today});
  Future<List<DiaryItem>> saveEntry(DateTime day, DiaryItem entry);
  Future<List<DiaryItem>> editEntry(
    DateTime day,
    DiaryItem entry, {
    bool delete = false,
  });
  Future<List<DiaryItem>> savePhoto(PhotoMeal meal);
  Future<List<FoodItem>> saveFood(FoodItem food);
  Future<List<String>> setFavorite(String id, bool selected);
  Future<List<String>> rememberFood(String id);
  Future<void> saveGoals(NutritionGoalSettings goals);
  Future<double> addWater(DateTime day, double amount);
  Future<void> saveWeight(double value);
}
