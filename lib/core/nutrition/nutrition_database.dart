import '../models/nutrition_profile.dart';

class NutritionFoodRecord {
  final String id;
  final String name;
  final String source;
  final String sourceUrl;
  final NutritionProfile profile;

  const NutritionFoodRecord({
    required this.id,
    required this.name,
    required this.source,
    required this.sourceUrl,
    required this.profile,
  });
}

/// Source-linked seed records for the FitLife nutrition database.
///
/// The first record is transcribed from the health-diet.ru card referenced by
/// the product-format requirement. The importer in tool/ can be used to add
/// more records after licensing/usage rights are confirmed.
const nutritionDatabase = <NutritionFoodRecord>[
  NutritionFoodRecord(
    id: 'healthdiet_17523',
    name: 'Жир говяжий, сырой',
    source: 'health-diet.ru / USDA',
    sourceUrl: 'https://health-diet.ru/base_of_food/sostav/17523.php',
    profile: NutritionProfile(
      kcal: 674,
      protein: 8.2,
      fat: 70.9,
      carbs: 0,
      fiber: 0,
      water: 20.2,
      ash: 0.3,
      vitamins: {
        'B1, тиамин (мг)': 0.03,
        'B2, рибофлавин (мг)': 0.037,
        'B5, пантотеновая (мг)': 0.163,
        'B6, пиридоксин (мг)': 0.108,
        'B12, кобаламин (мкг)': 0.73,
        'D, кальциферол (мкг)': 0.3,
        'D3, холекальциферол (мкг)': 0.3,
        'K, филлохинон (мкг)': 3.4,
        'PP, НЭ (мг)': 1.437,
      },
      minerals: {
        'Калий K (мг)': 96,
        'Кальций Ca (мг)': 26,
        'Магний Mg (мг)': 5,
        'Натрий Na (мг)': 26,
        'Сера S (мг)': 82.1,
        'Фосфор P (мг)': 61,
        'Железо Fe (мг)': 0.72,
        'Медь Cu (мкг)': 28,
        'Селен Se (мкг)': 6.6,
        'Цинк Zn (мг)': 0.82,
      },
      aminoAcids: {
        'Аргинин (г)': 0.531,
        'Валин (г)': 0.407,
        'Гистидин (г)': 0.262,
        'Изолейцин (г)': 0.374,
        'Лейцин (г)': 0.653,
        'Лизин (г)': 0.694,
        'Метионин (г)': 0.214,
        'Треонин (г)': 0.328,
        'Триптофан (г)': 0.054,
        'Фенилаланин (г)': 0.324,
        'Аланин (г)': 0.499,
        'Аспарагиновая кислота (г)': 0.748,
        'Гидроксипролин (г)': 0.086,
        'Глицин (г)': 0.5,
        'Глутаминовая кислота (г)': 1.233,
        'Пролин (г)': 0.391,
        'Серин (г)': 0.323,
        'Тирозин (г)': 0.262,
        'Цистеин (г)': 0.106,
      },
      fattyAcids: {
        'Насыщенные (г)': 29.45,
        '10:0 Каприновая (г)': 0.31,
        '12:0 Лауриновая (г)': 0.21,
        '14:0 Миристиновая (г)': 2.39,
        '16:0 Пальмитиновая (г)': 17.73,
        '18:0 Стеариновая (г)': 8.81,
        'Мононенасыщенные (г)': 30.94,
        '16:1 Пальмитолеиновая (г)': 3.88,
        '18:1 Олеиновая (г)': 26.95,
        '20:1 Гадолеиновая омега-9 (г)': 0.11,
        'Полиненасыщенные (г)': 2.56,
        '18:2 Линолевая (г)': 1.49,
        '18:3 Линоленовая (г)': 1.07,
      },
      omega3: 1.07,
      omega6: 1.49,
      cholesterol: 99,
    ),
  ),
];
