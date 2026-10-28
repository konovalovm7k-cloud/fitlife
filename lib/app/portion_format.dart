/// Display only; stored portion mass retains its full precision.
String formatFoodGrams(double grams) => grams
    .toStringAsFixed(3)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');
