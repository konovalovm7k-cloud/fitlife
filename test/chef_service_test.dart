import 'dart:async';
import 'dart:convert';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/features/chef/chef_catalogue.dart';
import 'package:fitlife/features/photo_analysis/photo_diary.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/photo_analysis/photo_service.dart';
import 'package:fitlife/data/repositories/local_fitlife_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/chef_fixture.dart';

void main() {
  final connection = PhotoConnection('https://chef.example.com', 'a' * 43);
  final catalogue = chefFixture();
  final id = 'c' * 32;
  test(
    'Chef ignores generated facts and resolves only local per-100-g profiles',
    () {
      final data = chefReply(id)..['kcal'] = 999;
      (data['items'] as List).single.addAll({
        'kcal': 999,
        'name': '100 kcal',
        'source': {'reference': 'fake'},
        'satietyHours': 8,
      });
      final result = catalogue.resolve(data, id);
      expect(result.source, MealEstimateSource.chef);
      expect(result.items.single.name, 'Яблоко с кожурой, сырое (CoFID)');
      expect(result.items.single.calories, closeTo(76.755, 1e-9));
      expect(result.items.single.source!.profile.kcal, 51);
      expect(result.items.single.source!.provenance.recordId, chefApple);
    },
  );
  test(
    'Chef rejects wrong nonce/version, unknown/dry/duplicate IDs and arbitrary advice',
    () {
      for (final patch in [
        {'version': 2},
        {'kind': 'photo'},
        {'catalogueVersion': 'other'},
        {'requestId': 'b' * 32},
        {
          'warnings': ['100 kcal'],
        },
        {'items': [], 'warnings': []},
        {
          'warnings': ['no_match'],
        },
        {
          'items': [
            {'recordId': 'invented', 'grams': 100},
          ],
        },
        {
          'items': [
            {'recordId': 'imported_cofid_2021_11-857', 'grams': 100},
          ],
        },
        {
          'items': [
            {'recordId': chefApple, 'grams': 100},
            {'recordId': chefApple, 'grams': 100},
          ],
        },
        {
          'items': [
            {'recordId': chefApple, 'grams': '100'},
          ],
        },
        {
          'items': [
            {'recordId': chefApple, 'grams': double.infinity},
          ],
        },
        {
          'items': [
            {'recordId': chefApple, 'grams': 0},
          ],
        },
        {
          'items': [
            {'recordId': chefApple, 'grams': 2000},
            {'recordId': chefYogurt, 'grams': 2000},
          ],
        },
      ]) {
        expect(
          () => catalogue.resolve(chefReply(id)..addAll(patch), id),
          throwsFormatException,
        );
      }
      expect(
        catalogue
            .resolve(chefReply(id, items: [], warnings: ['no_match']), id)
            .items,
        isEmpty,
      );
    },
  );
  test(
    'Chef metadata must match unambiguous local sources and supported version',
    () {
      final data = jsonDecode(chefAsset) as Map<String, dynamic>;
      data['version'] = 'future';
      expect(
        () => ChefCatalogue.parse(jsonEncode(data), chefRecords),
        throwsFormatException,
      );
      expect(
        () => ChefCatalogue.parse(chefAsset, chefRecords.skip(1).toList()),
        throwsFormatException,
      );
      expect(
        () =>
            ChefCatalogue.parse(chefAsset, [...chefRecords, chefRecords.first]),
        throwsFormatException,
      );
    },
  );
  test(
    'Chef service sends only authenticated pantry text to its endpoint once',
    () async {
      var calls = 0;
      final service = PhotoService(
        client: MockClient((request) async {
          calls++;
          expect(request.url.path, '/v2/chef');
          expect(request.followRedirects, isFalse);
          expect(request.headers['Authorization'], 'Bearer ${'a' * 43}');
          expect(jsonDecode(request.body), {'text': 'Яблоко 150,5 г'});
          return http.Response(
            jsonEncode(chefReply(request.headers['X-Request-Id']!)),
            200,
          );
        }),
      );
      addTearDown(service.close);
      final result = await service.suggestMeal(
        connection,
        '  Яблоко 150,5 г  ',
        catalogue,
      );
      expect(calls, 1);
      expect(result.items.single.calories, closeTo(76.755, 1e-9));
    },
  );
  test(
    'invalid pantry never reaches network; failures do not fall back to another API',
    () async {
      var calls = 0;
      final service = PhotoService(
        client: MockClient((_) async {
          calls++;
          return http.Response('', 404);
        }),
      );
      addTearDown(service.close);
      for (final text in ['', ' ', 'я' * 2001, 'еда\u0000']) {
        await expectLater(
          Future.sync(() => service.suggestMeal(connection, text, catalogue)),
          throwsA(isA<PhotoFailure>()),
        );
      }
      expect(calls, 0);
      await expectLater(
        service.suggestMeal(connection, 'Яблоко', catalogue),
        throwsA(
          isA<PhotoFailure>().having(
            (e) => e.message,
            'message',
            contains('AI Chef'),
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  test(
    'Chef status, malformed/oversize response and timeout are bounded single attempts',
    () async {
      for (final status in [302, 400, 413, 415, 422, 429, 503]) {
        var calls = 0;
        final service = PhotoService(
          client: MockClient((_) async {
            calls++;
            return http.Response('', status);
          }),
        );
        await expectLater(
          service.suggestMeal(connection, 'Яблоко', catalogue),
          throwsA(isA<PhotoFailure>()),
        );
        expect(calls, 1);
        service.close();
      }
      for (final body in [
        'not json',
        'x' * 65537,
        jsonEncode(chefReply('wrong')),
      ]) {
        final service = PhotoService(
          client: MockClient((_) async => http.Response(body, 200)),
        );
        await expectLater(
          service.suggestMeal(connection, 'Яблоко', catalogue),
          throwsA(isA<PhotoFailure>()),
        );
        service.close();
      }
      final pending = Completer<http.Response>();
      var calls = 0;
      final service = PhotoService(
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) {
          calls++;
          return pending.future;
        }),
      );
      await expectLater(
        service.suggestMeal(connection, 'Яблоко', catalogue),
        throwsA(isA<PhotoFailure>()),
      );
      pending.complete(http.Response('{}', 200));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      service.close();
    },
  );
  test(
    'Chef persistence preserves source snapshots, unknown fibre and origin without duplicates',
    () async {
      SharedPreferences.setMockInitialValues({});
      final day = DateTime(2026, 10, 28);
      final analysis = catalogue.resolve(
        chefReply(
          id,
          items: [
            {'recordId': chefApple, 'grams': 150.5},
            {'recordId': chefYogurt, 'grams': 100},
          ],
        ),
        id,
      );
      final meal = PhotoMeal(
        id: id,
        day: day,
        meal: 'Обед',
        items: analysis.items,
        source: analysis.source,
      );
      await savePhotoMeal(meal);
      await savePhotoMeal(meal);
      final saved = await LocalFitLifeRepository().loadDay(day, today: day);
      expect(saved.diary, hasLength(2));
      expect(saved.diary.every((e) => e.id.startsWith('chef_$id')), isTrue);
      expect(saved.diary.every((e) => e.food.isChefSuggestion), isTrue);
      expect(saved.diary.first.grams, 150.5);
      expect(saved.diary.last.food.hasKnownFiber, isFalse);
      expect(saved.diary.last.food.provenance!.recordId, chefYogurt);
      final legacy = saved.diary.first.food.toJson()..remove('chefSuggestion');
      expect(FoodItem.fromJson(legacy).isChefSuggestion, isFalse);
      expect(FoodItem.fromJson(legacy).provenance!.recordId, chefApple);
    },
  );
}
