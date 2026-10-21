import '../../core/models/diary_date.dart';
import '../../core/models/diary_item.dart';
import '../../core/models/nutrition_goal_settings.dart';

enum FitLifeLoadStatus { loading, ready, failed }

class DiaryTotals {
  const DiaryTotals({
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
  });
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  factory DiaryTotals.fromEntries(List<DiaryItem> entries) => entries.fold(
    const DiaryTotals(),
    (total, entry) => DiaryTotals(
      calories: total.calories + entry.kcal,
      protein: total.protein + entry.protein,
      fat: total.fat + entry.fat,
      carbs: total.carbs + entry.carbs,
      fiber: total.fiber + entry.fiber,
    ),
  );
}

/// A snapshot: only the controller can replace lists or persisted values.
class FitLifeState {
  FitLifeState({
    required DateTime day,
    this.status = FitLifeLoadStatus.loading,
    this.goals = const NutritionGoalSettings(),
    this.water = 0,
    this.weight = 104.2,
    this.recoveredData = false,
    List<DiaryItem> diary = const [],
    List<FoodItem> customFoods = const [],
    List<String> favorites = const [],
    List<String> recent = const [],
  }) : day = DiaryDate.only(day),
       diary = List.unmodifiable(diary),
       customFoods = List.unmodifiable(customFoods),
       favorites = List.unmodifiable(favorites),
       recent = List.unmodifiable(recent);

  final DateTime day;
  final FitLifeLoadStatus status;
  final NutritionGoalSettings goals;
  final double water;
  final double weight;
  final bool recoveredData;
  final List<DiaryItem> diary;
  final List<FoodItem> customFoods;
  final List<String> favorites;
  final List<String> recent;
  late final DiaryTotals total = DiaryTotals.fromEntries(diary);
  double get carbsTarget =>
      ((goals.calories - goals.protein * 4 - goals.fat * 9) / 4)
          .clamp(0, goals.calories)
          .toDouble();
  double get caloriesLeft =>
      (goals.calories - total.calories).clamp(0, goals.calories).toDouble();

  FitLifeState copyWith({
    DateTime? day,
    FitLifeLoadStatus? status,
    NutritionGoalSettings? goals,
    double? water,
    double? weight,
    bool? recoveredData,
    List<DiaryItem>? diary,
    List<FoodItem>? customFoods,
    List<String>? favorites,
    List<String>? recent,
  }) => FitLifeState(
    day: day ?? this.day,
    status: status ?? this.status,
    goals: goals ?? this.goals,
    water: water ?? this.water,
    weight: weight ?? this.weight,
    recoveredData: recoveredData ?? this.recoveredData,
    diary: diary ?? this.diary,
    customFoods: customFoods ?? this.customFoods,
    favorites: favorites ?? this.favorites,
    recent: recent ?? this.recent,
  );
}
