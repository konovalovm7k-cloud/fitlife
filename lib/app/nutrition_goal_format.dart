/// Display only: stored and calculated goals retain their full precision.
String formatNutritionGoal(double value) => value
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');
