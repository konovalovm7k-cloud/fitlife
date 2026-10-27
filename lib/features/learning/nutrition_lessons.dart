import '../../core/models/nutrition_profile.dart';
import '../../core/nutrition/nutrition_engine.dart';
import '../../data/repositories/diary_repository.dart';

class LessonSource {
  const LessonSource(this.title, this.url);
  final String title;
  final String url;
}

class NutritionLesson {
  const NutritionLesson({
    required this.id,
    required this.title,
    required this.paragraphs,
    required this.task,
    required this.sources,
  });
  final String id;
  final String title;
  final List<String> paragraphs;
  final String task;
  final List<LessonSource> sources;
}

const fdaLabelSource = LessonSource(
  'FDA: как читать пищевую этикетку',
  'https://www.fda.gov/food/nutrition-facts-label/how-understand-and-use-nutrition-facts-label',
);
const nutritionLessons = [
  NutritionLesson(
    id: 'portions_v1',
    title: 'Порция и состав',
    paragraphs: [
      'Сначала проверьте, к какой массе относится состав: к 100 г, одной порции '
          'или всей упаковке. Если масса того же продукта удваивается, его калории '
          'и нутриенты тоже удваиваются.',
      'В FitLife состав для ввода с этикетки нужен на 100 г. Если на упаковке '
          'данные на другую массу, сначала пересчитайте их. Масса порции на этикетке '
          'не говорит, сколько нужно съесть именно вам.',
      'Ниже учебная этикетка FDA: одна порция 227 г содержит 280 ккал. Это пример '
          'для расчёта, а не запись вашего приёма пищи и не рекомендуемая порция.',
    ],
    task:
        'Попробуйте переключить одну и две порции. Затем посмотрите, '
        'к какой массе относится состав одного знакомого продукта на упаковке.',
    sources: [fdaLabelSource],
  ),
  NutritionLesson(
    id: 'nutrients_v1',
    title: 'Зачем нужны нутриенты',
    paragraphs: [
      'Белки участвуют в построении и восстановлении клеток. Их можно получать '
          'из животных и растительных продуктов, например яиц, рыбы, молочных '
          'продуктов, сои и бобовых.',
      'Жиры дают энергию и помогают усваивать жирорастворимые витамины A, D, E '
          'и K. Углеводы тоже служат источником энергии; они встречаются во многих '
          'продуктах, включая крупы, фрукты и бобовые.',
      'Одно число калорий не описывает весь состав. В FitLife можно смотреть '
          'белки, жиры, углеводы и клетчатку вместе. Личные потребности различаются; '
          'этот урок не назначает вам новые цели питания.',
    ],
    task:
        'Откройте состав одного привычного продукта и найдите белки, жиры, '
        'углеводы и клетчатку. Если каких-то данных нет, это тоже полезно заметить.',
    sources: [
      LessonSource(
        'MedlinePlus: белок',
        'https://medlineplus.gov/ency/article/002467.htm',
      ),
      LessonSource(
        'MedlinePlus: углеводы',
        'https://medlineplus.gov/carbohydrates.html',
      ),
      LessonSource(
        'MedlinePlus: жиры',
        'https://medlineplus.gov/ency/patientinstructions/000104.htm',
      ),
    ],
  ),
  NutritionLesson(
    id: 'sources_v1',
    title: 'Что известно о составе',
    paragraphs: [
      'Название продукта не всегда определяет его состав. Проверьте марку, вид '
          'и способ приготовления. Похожие продукты или сырые и приготовленные '
          'ингредиенты могут требовать разных записей каталога.',
      'Если клетчатка не указана, это не измеренный ноль. FitLife помечает '
          'неполные данные и показывает только известную часть суточного итога. '
          'AI предлагает название и массу; состав подтверждается отдельно.',
      '«Умная сытость» оценивает свойства порции экспериментальной формулой. '
          'Личная отметка голода — отдельное наблюдение. Ни одно из этих чисел '
          'не обязывает ждать следующей еды.',
    ],
    task:
        'В дневнике выберите значок источника состава у одной записи. '
        'Уточните источник, если он у вас есть. Если фактов нет, можно оставить '
        'запись как есть и вернуться позже.',
    sources: [fdaLabelSource],
  ),
];

/// Published FDA teaching-label values per 227 g; no invented meal facts and no
/// diary insertion. The same Nutrition Engine used by food review scales them.
NutritionProfile teachingPortion(double grams) => NutritionEngine.portion(
  NutritionSource(
    name: 'Учебная этикетка FDA',
    fiberKnown: true,
    provenance: NutritionProvenance(
      kind: 'label',
      reference: fdaLabelSource.title,
      url: fdaLabelSource.url,
    ),
    profile: const NutritionProfile(
      kcal: 280 * 100 / 227,
      protein: 15 * 100 / 227,
      fat: 9 * 100 / 227,
      carbs: 34 * 100 / 227,
      fiber: 4 * 100 / 227,
    ),
  ),
  grams,
);

const lessonProgressKey = 'learning_completed_v1';

class LearningProgress {
  const LearningProgress(this.completed, {this.recovered = false});
  final Set<String> completed;
  final bool recovered;
  int get count =>
      nutritionLessons.where((l) => completed.contains(l.id)).length;
}

class LearningRepository {
  LearningRepository(this.diary);
  final DiaryRepository diary;
  Future<LearningProgress> load() => diary.run(
    (store) async => LearningProgress(
      Set.unmodifiable(await store.readStringList(lessonProgressKey)),
      recovered: store.recoveredData,
    ),
  );
  Future<void> mark(String id, bool completed) => diary.run((store) async {
    if (!nutritionLessons.any((l) => l.id == id)) {
      throw const FormatException('Unknown lesson');
    }
    final current = (await store.readStringList(lessonProgressKey)).toSet();
    if (completed) {
      current.add(id);
    } else {
      current.remove(id);
    }
    // Preserve unknown IDs from a later content version; only this lesson's
    // explicit mark is changed. No food, goals, pet or observation writes.
    await store.writeList(lessonProgressKey, current.toList()..sort());
  });
}
