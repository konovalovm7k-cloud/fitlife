import '../../core/models/nutrition_profile.dart';
import '../../core/nutrition/nutrition_database.dart';
import '../../core/nutrition/nutrition_engine.dart';
import '../photo_analysis/photo_models.dart';

class IdeaIngredient {
  const IdeaIngredient(this.foodCode, this.grams);
  final String foodCode;
  final double grams;
  String get recordId => 'imported_cofid_2021_$foodCode';
}

class MealIdea {
  const MealIdea({
    required this.id,
    required this.title,
    required this.instructions,
    required this.allergenNote,
    required this.ingredients,
  });
  final String id;
  final String title;
  final String instructions;
  final String allergenNote;
  final List<IdeaIngredient> ingredients;

  List<PhotoFood> resolve(List<NutritionFoodRecord> records, double factor) {
    if (![.5, 1.0, 2.0].contains(factor)) {
      throw const FormatException('Unsupported example portion');
    }
    return List.unmodifiable(
      ingredients.map((ingredient) {
        final matches = records
            .where((r) => r.id == ingredient.recordId)
            .toList();
        if (matches.length != 1) {
          throw const FormatException('Missing or ambiguous recipe source');
        }
        final source = NutritionSource.catalogue(matches.single);
        final grams = ingredient.grams * factor;
        NutritionEngine.portion(source, grams);
        return PhotoFood(
          name: source.name,
          grams: grams,
          confidence: 'high',
          source: source,
        );
      }),
    );
  }
}

NutritionProfile ideaTotal(List<PhotoFood> foods) => foods.fold(
  const NutritionProfile(kcal: 0, protein: 0, fat: 0, carbs: 0),
  (sum, food) => sum + NutritionEngine.portion(food.source!, food.grams),
);

// Masses refer to the exact edible state in each source. No raw-to-cooked
// conversion, model-generated nutrients or personalised intake target is used.
const mealIdeas = [
  MealIdea(
    id: 'cottage_vegetables_v1',
    title: 'Овощи с зернёным творогом и хлебом',
    instructions:
        'Взвесьте зернёный творог и хлеб. Нарежьте сырые помидор и огурец с кожурой, соберите тарелку.',
    allergenNote:
        'В этой идее есть молоко и пшеница. Проверьте также состав и аллергены на упаковках.',
    ingredients: [
      IdeaIngredient('12-550', 120),
      IdeaIngredient('13-517', 150),
      IdeaIngredient('13-523', 100),
      IdeaIngredient('11-981', 50),
    ],
  ),
  MealIdea(
    id: 'chicken_rice_v1',
    title: 'Готовая курица с рисом и овощами',
    instructions:
        'Возьмите уже приготовленную на гриле грудку без кожи и уже сваренный без соли рис басмати. Взвесьте их готовыми. Добавьте нарезанные сырые помидор и огурец.',
    allergenNote:
        'Проверьте состав и аллергены готовых продуктов. Соусы и масло здесь не учтены.',
    ingredients: [
      IdeaIngredient('18-323', 120),
      IdeaIngredient('11-858', 150),
      IdeaIngredient('13-517', 150),
      IdeaIngredient('13-523', 100),
    ],
  ),
  MealIdea(
    id: 'lentils_vegetables_v1',
    title: 'Чечевица с овощами и хлебом',
    instructions:
        'Взвесьте уже сваренную без соли красную чечевицу. Добавьте сырые морковь и помидор, подайте с цельнозерновым хлебом.',
    allergenNote:
        'В этой идее есть пшеница. Проверьте также состав и аллергены на упаковках.',
    ingredients: [
      IdeaIngredient('13-658', 150),
      IdeaIngredient('13-496', 75),
      IdeaIngredient('13-517', 100),
      IdeaIngredient('11-981', 50),
    ],
  ),
];
