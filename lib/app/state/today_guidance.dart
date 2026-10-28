import 'fitlife_state.dart';

enum TodayAction { logMeal, chooseFood, reviewDiary, savedMeals, reviewSource }

enum CompanionMood { welcoming, attentive, encouraging }

/// Local UI guidance from persisted records. No hunger, medical, completeness
/// or energy-expenditure conclusions are inferred from an incomplete diary.
class TodayGuidance {
  const TodayGuidance(
    this.title,
    this.detail,
    this.button,
    this.action,
    this.mood,
  );
  final String title;
  final String detail;
  final String button;
  final TodayAction action;
  final CompanionMood mood;

  static TodayGuidance forDay(FitLifeState data, {required bool isToday}) {
    if (!isToday) {
      return const TodayGuidance(
        'Записи за выбранный день',
        'Можно уточнить порции или повторить знакомое блюдо в другой день.',
        'Посмотреть дневник',
        TodayAction.reviewDiary,
        CompanionMood.attentive,
      );
    }
    if (data.diary.isEmpty) {
      return const TodayGuidance(
        'Начнём с удобной записи',
        'Добавьте то, что уже съели. Запись не должна мешать обычному приёму пищи.',
        'Записать еду',
        TodayAction.logMeal,
        CompanionMood.welcoming,
      );
    }
    if (data.total.calories >= data.goals.calories) {
      return const TodayGuidance(
        'Каждый день бывает разным',
        'Это сумма внесённых записей. Можно проверить порции; пропускать еду ради цифр не нужно.',
        'Проверить дневник',
        TodayAction.reviewDiary,
        CompanionMood.encouraging,
      );
    }
    final incomplete = data.diary
        .where((entry) => !entry.food.hasKnownFiber)
        .firstOrNull;
    if (incomplete != null) {
      return TodayGuidance(
        'Уточним состав, когда удобно',
        'Клетчатка указана не у всех продуктов. Сейчас показана только известная часть. '
            'Можно уточнить запись «${incomplete.food.name}».',
        'Уточнить запись',
        TodayAction.reviewSource,
        CompanionMood.attentive,
      );
    }
    if (data.total.protein < data.goals.protein * 0.7) {
      return const TodayGuidance(
        'Идея для следующего приёма',
        'Если планируете еду, выберите подходящий вам источник белка. Дневник может быть неполным.',
        'Выбрать продукт',
        TodayAction.chooseFood,
        CompanionMood.attentive,
      );
    }
    return const TodayGuidance(
      'Сделаем следующую запись проще',
      'Знакомый состав можно сохранить в «Мои блюда» и повторять с нужной порцией.',
      'Открыть мои блюда',
      TodayAction.savedMeals,
      CompanionMood.encouraging,
    );
  }
}
