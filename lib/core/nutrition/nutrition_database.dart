import '../models/nutrition_profile.dart';

class NutritionFoodRecord {
  final String id;
  final String name;
  final String source;
  final String sourceUrl;
  final NutritionProfile profile;

  const NutritionFoodRecord({required this.id, required this.name, required this.source, required this.sourceUrl, required this.profile});
}

/// Source-linked records, all values per 100 g edible product.
/// health-diet.ru remains a reference format; this app does not silently mirror
/// the site's complete copyrighted catalogue.
const nutritionDatabase = <NutritionFoodRecord>[
  NutritionFoodRecord(
    id: 'healthdiet_17523', name: 'Жир говяжий, сырой', source: 'health-diet.ru / USDA', sourceUrl: 'https://health-diet.ru/base_of_food/sostav/17523.php',
    profile: NutritionProfile(
      kcal: 674, protein: 8.2, fat: 70.9, carbs: 0, water: 20.2, ash: .3,
      vitamins: {'B1, тиамин (мг)': .03, 'B2, рибофлавин (мг)': .037, 'B5 (мг)': .163, 'B6 (мг)': .108, 'B12 (мкг)': .73, 'D (мкг)': .3, 'D3 (мкг)': .3, 'K (мкг)': 3.4, 'PP (мг)': 1.437},
      minerals: {'Калий K (мг)': 96, 'Кальций Ca (мг)': 26, 'Магний Mg (мг)': 5, 'Натрий Na (мг)': 26, 'Сера S (мг)': 82.1, 'Фосфор P (мг)': 61, 'Железо Fe (мг)': .72, 'Медь Cu (мкг)': 28, 'Селен Se (мкг)': 6.6, 'Цинк Zn (мг)': .82},
      aminoAcids: {'Аргинин (г)': .531, 'Валин (г)': .407, 'Гистидин (г)': .262, 'Изолейцин (г)': .374, 'Лейцин (г)': .653, 'Лизин (г)': .694, 'Метионин (г)': .214, 'Треонин (г)': .328, 'Триптофан (г)': .054, 'Фенилаланин (г)': .324, 'Аланин (г)': .499, 'Аспарагиновая кислота (г)': .748, 'Глицин (г)': .5, 'Глутаминовая кислота (г)': 1.233, 'Пролин (г)': .391, 'Серин (г)': .323, 'Тирозин (г)': .262, 'Цистеин (г)': .106},
      fattyAcids: {'Насыщенные (г)': 29.45, '16:0 Пальмитиновая (г)': 17.73, '18:0 Стеариновая (г)': 8.81, 'Мононенасыщенные (г)': 30.94, '18:1 Олеиновая (г)': 26.95, 'Полиненасыщенные (г)': 2.56, '18:2 Линолевая (г)': 1.49, '18:3 Линоленовая (г)': 1.07}, omega3: 1.07, omega6: 1.49, cholesterol: 99,
    ),
  ),
  NutritionFoodRecord(
    id: 'healthdiet_417', name: 'Хек', source: 'health-diet.ru / Скурихин И.М. и др.', sourceUrl: 'https://www.health-diet.ru/base_of_food/sostav/417.php',
    profile: NutritionProfile(
      kcal: 86, protein: 16.6, fat: 2.2, carbs: 0, water: 79.9, ash: 1.3,
      vitamins: {'A, РЭ (мкг)': 10},
      minerals: {'Калий K (мг)': 335, 'Кальций Ca (мг)': 30, 'Магний Mg (мг)': 35, 'Натрий Na (мг)': 75, 'Сера S (мг)': 200, 'Фосфор P (мг)': 240, 'Хлор Cl (мг)': 165, 'Йод I (мкг)': 160, 'Кобальт Co (мкг)': 20, 'Медь Cu (мкг)': 135, 'Фтор F (мкг)': 700, 'Хром Cr (мкг)': 55},
      fattyAcids: {'Насыщенные (г)': .6, '20:5 ЭПК (г)': .01, '22:5 ДПК (г)': .03, '22:6 ДГК (г)': .38}, omega3: .41, omega6: .04, cholesterol: 70,
    ),
  ),
  NutritionFoodRecord(
    id: 'healthdiet_37', name: 'Батат', source: 'health-diet.ru / Скурихин И.М. и др.', sourceUrl: 'https://health-diet.ru/base_of_food/sostav/37.php',
    profile: NutritionProfile(
      kcal: 60, protein: 2, fat: .1, carbs: 13.3, fiber: 1.3, water: 80.5, ash: 1.2,
      vitamins: {'A, РЭ (мкг)': 300, 'Бета-каротин (мг)': .3, 'B1 (мг)': .15, 'B2 (мг)': .05, 'Холин (мг)': 12.3, 'B5 (мг)': .8, 'B6 (мг)': .209, 'B9 (мкг)': 11, 'C (мг)': 23, 'E (мг)': .26, 'K (мкг)': 1.8, 'PP (мг)': .6},
      minerals: {'Калий K (мг)': 397, 'Кальций Ca (мг)': 34, 'Магний Mg (мг)': 28, 'Натрий Na (мг)': 55, 'Фосфор P (мг)': 49, 'Железо Fe (мг)': 1, 'Марганец Mn (мг)': .258, 'Медь Cu (мкг)': 151, 'Селен Se (мкг)': .6, 'Цинк Zn (мг)': .3}, omega3: .001, omega6: .013,
    ),
  ),
  NutritionFoodRecord(
    id: 'healthdiet_206', name: 'Мёд', source: 'health-diet.ru', sourceUrl: 'https://health-diet.ru/base_of_food/sostav/206.php',
    profile: NutritionProfile(
      kcal: 328, protein: .8, fat: 0, carbs: 80.3, fiber: .2, water: 17.4, ash: .3,
      vitamins: {'B1 (мг)': .01, 'B2 (мг)': .03, 'B5 (мг)': .13, 'B6 (мг)': .1, 'B9 (мкг)': 15, 'C (мг)': 2, 'H (мкг)': .04, 'PP (мг)': .4},
      minerals: {'Калий K (мг)': 36, 'Кальций Ca (мг)': 14, 'Магний Mg (мг)': 3, 'Натрий Na (мг)': 10, 'Фосфор P (мг)': 18, 'Хлор Cl (мг)': 19, 'Железо Fe (мг)': .8, 'Йод I (мкг)': 2, 'Кобальт Co (мкг)': .3, 'Марганец Mn (мг)': .03, 'Медь Cu (мкг)': 60, 'Фтор F (мкг)': 100, 'Цинк Zn (мг)': .09},
    ),
  ),
  NutritionFoodRecord(
    id: 'healthdiet_180', name: 'Лимон', source: 'health-diet.ru', sourceUrl: 'https://health-diet.ru/base_of_food/sostav/180.php',
    profile: NutritionProfile(
      kcal: 34, protein: .9, fat: .1, carbs: 3, fiber: 2.2, water: 87.8, ash: .5,
      vitamins: {'C (мг)': 40, 'B1 (мг)': .04, 'B2 (мг)': .02, 'B6 (мг)': .06, 'B9 (мкг)': 9, 'PP (мг)': .2},
      minerals: {'Калий K (мг)': 163, 'Кальций Ca (мг)': 40, 'Кремний Si (мг)': 2, 'Магний Mg (мг)': 12, 'Натрий Na (мг)': 11, 'Фосфор P (мг)': 22, 'Железо Fe (мг)': .6, 'Йод I (мкг)': .1, 'Кобальт Co (мкг)': 1, 'Марганец Mn (мг)': .04, 'Медь Cu (мкг)': 240}, omega3: .02, omega6: .06,
    ),
  ),
  NutritionFoodRecord(
    id: 'healthdiet_15983', name: 'Яблоко', source: 'health-diet.ru', sourceUrl: 'https://health-diet.ru/base_of_food/sostav/15983.php',
    profile: NutritionProfile(
      kcal: 52, protein: .3, fat: .2, carbs: 11.4, fiber: 2.4, water: 85.6, ash: .2,
      vitamins: {'A, РЭ (мкг)': 3, 'Бета-каротин (мг)': .027, 'B1 (мг)': .017, 'B2 (мг)': .026, 'B6 (мг)': .041, 'B9 (мкг)': 3, 'C (мг)': 4.6, 'E (мг)': .18, 'K (мкг)': 2.2, 'PP (мг)': .091},
      minerals: {'Калий K (мг)': 107, 'Кальций Ca (мг)': 6, 'Магний Mg (мг)': 5, 'Натрий Na (мг)': 1, 'Фосфор P (мг)': 11, 'Железо Fe (мг)': .12, 'Марганец Mn (мг)': .035, 'Медь Cu (мкг)': 27, 'Цинк Zn (мг)': .04}, omega3: .01, omega6: .04,
    ),
  ),
  NutritionFoodRecord(
    id: 'healthdiet_110365', name: 'Гречка [Основа]', source: 'health-diet.ru / Интернет', sourceUrl: 'https://health-diet.ru/base_of_food/sostav/110365.php',
    profile: NutritionProfile(kcal: 335, protein: 12.6, fat: 3.3, carbs: 62.1, minerals: {'Калий K (мг)': 460, 'Магний Mg (мг)': 200, 'Фосфор P (мг)': 334, 'Железо Fe (мг)': 6.7, 'Цинк Zn (мг)': 2.05}),
  ),
  NutritionFoodRecord(
    id: 'healthdiet_374', name: 'Сом', source: 'health-diet.ru / Скурихин И.М. и др.', sourceUrl: 'https://health-diet.ru/base_of_food/sostav/374.php',
    profile: NutritionProfile(kcal: 115, protein: 17.2, fat: 5.1, carbs: 0, water: 76.7, ash: 1, vitamins: {'A, РЭ (мкг)': 10}, minerals: {'Калий K (мг)': 295, 'Железо Fe (мг)': 1, 'Йод I (мкг)': 5, 'Кобальт Co (мкг)': 20, 'Марганец Mn (мг)': .06, 'Медь Cu (мкг)': 60, 'Молибден Mo (мкг)': 4, 'Фтор F (мкг)': 25, 'Хром Cr (мкг)': 55, 'Цинк Zn (мг)': .45}, omega3: .43, omega6: .31, cholesterol: 70, fattyAcids: {'Насыщенные (г)': 1.2, 'Мононенасыщенные (г)': 1.88, 'Полиненасыщенные (г)': .74, '20:5 ЭПК (г)': .1, '22:6 ДГК (г)': .2}),
  ),
];
