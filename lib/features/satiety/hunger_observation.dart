import 'dart:convert';
import '../../core/models/diary_item.dart';
import '../../data/repositories/diary_preferences.dart';
import '../../data/repositories/diary_repository.dart';
import 'satiety_estimate.dart';

const hungerObservationsKey = 'hunger_observations_v1';
const hungerLabels = [
  'Нет голода',
  'Небольшой голод',
  'Умеренный голод',
  'Сильный голод',
  'Очень сильный голод',
];

enum FoodSinceMeal { no, yes, unknown }

class HungerObservation {
  const HungerObservation({
    required this.id,
    required this.meal,
    required this.mealAt,
    required this.observedAt,
    required this.level,
    required this.foodSince,
    required this.items,
    this.structure,
  });
  final String id;
  final String meal;
  final DateTime mealAt;
  final DateTime observedAt;
  final int level;
  final FoodSinceMeal foodSince;
  final List<DiaryItem> items;
  final FoodStructure? structure;
  Duration get elapsed => observedAt.difference(mealAt);
  Map<String, dynamic> toJson() => {
    'version': 1, 'id': id, 'meal': meal,
    'mealAt': mealAt.toUtc().toIso8601String(),
    'observedAt': observedAt.toUtc().toIso8601String(),
    'level': level, 'foodSince': foodSince.name,
    'structure': structure?.name,
    // Snapshot the actual meal used at observation time, including provenance
    // and unknown fiber. Subsequent diary edits cannot rewrite the observation.
    'items': items.map((i) => i.toJson()).toList(),
  };
  factory HungerObservation.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final meal = json['meal'] as String;
    final mealAt = DateTime.parse(json['mealAt'] as String);
    final observedAt = DateTime.parse(json['observedAt'] as String);
    final level = json['level'];
    final items = (json['items'] as List)
        .map((i) => DiaryItem.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();
    if (json['version'] != 1 ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(id) ||
        !['Завтрак', 'Обед', 'Ужин', 'Перекус'].contains(meal) ||
        level is! int ||
        level < 1 ||
        level > 5 ||
        !mealAt.isUtc ||
        !observedAt.isUtc ||
        mealAt.toIso8601String() != json['mealAt'] ||
        observedAt.toIso8601String() != json['observedAt'] ||
        mealAt.year < 2020 ||
        observedAt.year > 2100 ||
        !observedAt.isAfter(mealAt) ||
        items.isEmpty ||
        items.length > 100 ||
        items.any((i) => i.meal != meal) ||
        !FoodSinceMeal.values.any((v) => v.name == json['foodSince']) ||
        (json['structure'] != null &&
            !FoodStructure.values.any((v) => v.name == json['structure']))) {
      throw const FormatException('Invalid hunger observation');
    }
    return HungerObservation(
      id: id,
      meal: meal,
      mealAt: mealAt,
      observedAt: observedAt,
      level: level,
      foodSince: FoodSinceMeal.values.byName(json['foodSince'] as String),
      items: List.unmodifiable(items),
      structure: json['structure'] == null
          ? null
          : FoodStructure.values.byName(json['structure'] as String),
    );
  }
}

class HungerRepository {
  HungerRepository(this.diary, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DiaryRepository diary;
  final DateTime Function() _clock;

  List<HungerObservation> _read(DiaryPreferences store) {
    final raw = store.preferences.get(hungerObservationsKey);
    if (raw == null) return [];
    // Private observations have no automatically retained recovery copies.
    // On malformed data, leave the original untouched and block replacement;
    // only an explicit clear-all may discard it.
    final data = jsonDecode(raw as String);
    if (data is! List) throw const FormatException('Invalid observation list');
    final result = data
        .map(
          (o) =>
              HungerObservation.fromJson(Map<String, dynamic>.from(o as Map)),
        )
        .toList();
    if (result.map((o) => o.id).toSet().length != result.length) {
      throw const FormatException('Duplicate observation IDs');
    }
    return result..sort((a, b) => b.observedAt.compareTo(a.observedAt));
  }

  Future<List<HungerObservation>> load() =>
      diary.run((store) async => List.unmodifiable(_read(store)));
  Future<void> save(HungerObservation observation) => diary.run((store) async {
    final checked = HungerObservation.fromJson(observation.toJson());
    if (checked.observedAt.isAfter(_clock().toUtc())) {
      throw const FormatException('Future observation');
    }
    final current = _read(store);
    await store.writeString(
      hungerObservationsKey,
      jsonEncode([
        for (final old in current)
          if (old.id != checked.id) old.toJson(),
        checked.toJson(),
      ]),
    );
  });
  Future<void> delete(String id) => diary.run((store) async {
    final current = _read(store);
    await store.writeString(
      hungerObservationsKey,
      jsonEncode([
        for (final old in current)
          if (old.id != id) old.toJson(),
      ]),
    );
  });
  Future<void> clear() =>
      diary.run((store) => store.writeString(hungerObservationsKey, '[]'));
}
