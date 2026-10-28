import 'dart:io';
import 'package:fitlife/core/nutrition/food_catalog_import.dart';
import 'package:fitlife/features/chef/chef_catalogue.dart';

const chefApple = 'imported_cofid_2021_14-319';
const chefYogurt = 'imported_cofid_2021_12-379';
final chefAsset = File('shared/chef_catalogue.json').readAsStringSync();
final chefFoodsAsset = File('assets/data/food_catalog.json').readAsStringSync();
final chefRecords = parseFoodCatalog(chefFoodsAsset);
ChefCatalogue chefFixture() => ChefCatalogue.parse(chefAsset, chefRecords);
Map<String, dynamic> chefReply(
  String id, {
  List<Map<String, dynamic>>? items,
  List<String>? warnings,
}) => {
  'version': 1,
  'kind': 'chef',
  'catalogueVersion': chefCatalogueVersion,
  'requestId': id,
  'items':
      items ??
      [
        {'recordId': chefApple, 'grams': 150.5},
      ],
  'warnings': warnings ?? ['check_portions'],
};
