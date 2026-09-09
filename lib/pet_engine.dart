import 'dart:math' as math;

/// Long-term pet progression for FitLife.
///
/// The pet reacts to consistent habits rather than punishing a single bad day.
class PetState {
  const PetState({
    this.xp = 0,
    this.energy = 70,
    this.wellness = 70,
    this.habitLevel = 0,
    this.knowledge = 0,
    this.fitnessStage = 0,
  });

  final int xp;
  final double energy;
  final double wellness;
  final int habitLevel;
  final int knowledge;
  final int fitnessStage;

  PetState copyWith({
    int? xp,
    double? energy,
    double? wellness,
    int? habitLevel,
    int? knowledge,
    int? fitnessStage,
  }) {
    return PetState(
      xp: xp ?? this.xp,
      energy: energy ?? this.energy,
      wellness: wellness ?? this.wellness,
      habitLevel: habitLevel ?? this.habitLevel,
      knowledge: knowledge ?? this.knowledge,
      fitnessStage: fitnessStage ?? this.fitnessStage,
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'energy': energy,
        'wellness': wellness,
        'habitLevel': habitLevel,
        'knowledge': knowledge,
        'fitnessStage': fitnessStage,
      };

  factory PetState.fromJson(Map<String, dynamic> json) => PetState(
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        energy: (json['energy'] as num?)?.toDouble() ?? 70,
        wellness: (json['wellness'] as num?)?.toDouble() ?? 70,
        habitLevel: (json['habitLevel'] as num?)?.toInt() ?? 0,
        knowledge: (json['knowledge'] as num?)?.toInt() ?? 0,
        fitnessStage: (json['fitnessStage'] as num?)?.toInt() ?? 0,
      );
}

class PetStage {
  const PetStage({required this.index, required this.name, required this.emoji, required this.minXp});

  final int index;
  final String name;
  final String emoji;
  final int minXp;
}

const petStages = <PetStage>[
  PetStage(index: 0, name: 'Cozy', emoji: '🐼', minXp: 0),
  PetStage(index: 1, name: 'Active', emoji: '🐼', minXp: 150),
  PetStage(index: 2, name: 'Fit', emoji: '🐼', minXp: 400),
  PetStage(index: 3, name: 'Strong', emoji: '🐼', minXp: 800),
  PetStage(index: 4, name: 'Hero', emoji: '🐼', minXp: 1400),
];

class PetEngine {
  static const xpMeal = 10;
  static const xpWater = 5;
  static const xpDailyQuest = 20;
  static const xpSteps5k = 20;
  static const xpSteps10k = 40;
  static const xpProteinGoal = 20;
  static const xpLearning = 5;
  static const xpWeighIn = 10;
  static const xpWeeklyQuest = 100;

  static int addXp(PetState state, int amount) {
    // XP is never negative: food lapses must not punish the user.
    return math.max(0, state.xp + math.max(0, amount));
  }

  static PetState reward(PetState state, int amount) {
    final xp = addXp(state, amount);
    return state.copyWith(xp: xp, fitnessStage: stageForXp(xp).index);
  }

  static PetState mealLogged(PetState state) => reward(state, xpMeal);
  static PetState waterLogged(PetState state) => reward(state, xpWater);
  static PetState dailyQuestCompleted(PetState state) => reward(state, xpDailyQuest);
  static PetState learningCompleted(PetState state) => reward(state, xpLearning);
  static PetState weighInCompleted(PetState state) => reward(state, xpWeighIn);
  static PetState weeklyQuestCompleted(PetState state) => reward(state, xpWeeklyQuest);

  static PetState stepsCompleted(PetState state, int steps) {
    if (steps >= 10000) return reward(state, xpSteps10k);
    if (steps >= 5000) return reward(state, xpSteps5k);
    return state;
  }

  static PetState proteinGoalCompleted(PetState state, {double goal = 180, required double protein}) {
    if (protein >= goal) return reward(state, xpProteinGoal);
    return state;
  }

  static PetStage stageForXp(int xp) {
    var current = petStages.first;
    for (final stage in petStages) {
      if (xp >= stage.minXp) current = stage;
    }
    return current;
  }

  /// Smooth long-term score. Single-day fluctuations are intentionally small.
  static double fitnessScore({
    required double weightTrendScore,
    required double habitConsistencyScore,
    required double activityScore,
    required double proteinConsistencyScore,
    required double hydrationScore,
  }) {
    return _clamp(
      weightTrendScore * .40 +
          habitConsistencyScore * .25 +
          activityScore * .20 +
          proteinConsistencyScore * .10 +
          hydrationScore * .05,
    );
  }

  static double _clamp(double value) => value.clamp(0, 100).toDouble();
}
