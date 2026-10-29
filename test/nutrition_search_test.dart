import 'dart:io';
import 'package:fitlife/core/nutrition/food_catalog_import.dart';
import 'package:fitlife/core/nutrition/nutrition_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final records = parseFoodCatalog(
    File('assets/data/food_catalog.json').readAsStringSync(),
  );
  final catalogue = NutritionCatalog(records: records);
  test('word order, multiple spaces and е/ё find the prepared rice', () {
    for (final query in [' ВАРЕНЫЙ   рис ', 'рис, варёный']) {
      expect(
        catalogue.search(query).map((r) => r.id),
        unorderedEquals([
          'imported_cofid_2021_11-858',
          'imported_cofid_2021_11-869',
        ]),
      );
    }
  });
  test('source identity is searchable by code and original English name', () {
    expect(catalogue.search('11-858').single.id, endsWith('11-858'));
    expect(catalogue.search('basmati boiled').single.id, endsWith('11-858'));
  });
  test('all words must match and raw/cooked state is never discarded', () {
    expect(catalogue.search('рис сухой').single.id, endsWith('11-857'));
    expect(catalogue.search('rice raw').single.id, endsWith('11-857'));
    expect(catalogue.search('рис вареный сухой'), isEmpty);
    expect(catalogue.search('рис неизвестный'), isEmpty);
  });
  test('empty query retains original order and does not mutate records', () {
    expect(catalogue.search(' \n '), same(records));
    expect(catalogue.search('CoFID'), orderedEquals(records));
  });
}
