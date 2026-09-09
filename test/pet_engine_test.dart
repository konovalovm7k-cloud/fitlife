import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/pet_engine.dart';

void main() {
  test('XP rewards move pet through stages', () {
    var state = const PetState();
    state = PetEngine.reward(state, 150);
    expect(state.xp, 150);
    expect(PetEngine.stageForXp(state.xp).name, 'Active');

    state = PetEngine.reward(state, 250);
    expect(state.xp, 400);
    expect(PetEngine.stageForXp(state.xp).name, 'Fit');
  });

  test('negative XP can never punish the user', () {
    const state = PetState(xp: 200);
    final next = PetEngine.reward(state, -50);
    expect(next.xp, 200);
  });

  test('step rewards use the highest applicable tier', () {
    const state = PetState();
    expect(PetEngine.stepsCompleted(state, 4999).xp, 0);
    expect(PetEngine.stepsCompleted(state, 5000).xp, 20);
    expect(PetEngine.stepsCompleted(state, 10000).xp, 40);
  });

  test('protein reward is granted only when goal is reached', () {
    const state = PetState();
    expect(PetEngine.proteinGoalCompleted(state, protein: 179.9).xp, 0);
    expect(PetEngine.proteinGoalCompleted(state, protein: 180).xp, 20);
  });

  test('fitness score uses the planned long-term weights', () {
    final score = PetEngine.fitnessScore(
      weightTrendScore: 100,
      habitConsistencyScore: 100,
      activityScore: 100,
      proteinConsistencyScore: 100,
      hydrationScore: 100,
    );
    expect(score, 100);
  });
}
