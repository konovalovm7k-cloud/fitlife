class DiaryDate {
  static DateTime only(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static String key(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static bool same(DateTime a, DateTime b) => key(a) == key(b);
}
