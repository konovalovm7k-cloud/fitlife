import 'dart:convert';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/photo_analysis/photo_service.dart';
import 'package:fitlife/features/photo_analysis/text_meal_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'photo_page_test.dart' show MemoryPhotoConnection;
import 'photo_service_test.dart' show result;

void main() {
  final connection = PhotoConnection('https://personal.example.com', 'a' * 43);
  test(
    'description uses the authenticated text route and per-100g review contract',
    () async {
      final service = PhotoService(
        client: MockClient((request) async {
          expect(request.url.path, '/v1/analyze-text');
          expect(request.url.host, connection.endpoint.host);
          expect(
            request.headers['Authorization'],
            'Bearer ${connection.token}',
          );
          expect(request.headers['Content-Type'], 'application/json');
          expect(request.followRedirects, isFalse);
          expect(jsonDecode(utf8.decode(request.bodyBytes)), {
            'text': 'Рис варёный 150 г',
          });
          return http.Response(
            jsonEncode(result(request.headers['X-Request-Id']!)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(service.close);
      final analysis = await service.analyzeText(
        connection,
        '  Рис варёный 150 г  ',
      );
      expect(analysis.source, MealEstimateSource.text);
      expect(analysis.items.single.calories, 195);
    },
  );
  test(
    'empty, oversized and control-character input never reaches the network',
    () async {
      var calls = 0;
      final service = PhotoService(
        client: MockClient((_) async {
          calls++;
          return http.Response('', 500);
        }),
      );
      addTearDown(service.close);
      for (final text in ['', '  ', 'я' * 2001, 'еда\u0000']) {
        await expectLater(
          Future.sync(() => service.analyzeText(connection, text)),
          throwsA(isA<PhotoFailure>()),
        );
      }
      expect(calls, 0);
    },
  );
  test(
    'text service failures never tell the user to replace a photo',
    () async {
      for (final status in [400, 413, 415, 422]) {
        final service = PhotoService(
          client: MockClient((_) async => http.Response('', status)),
        );
        try {
          await expectLater(
            service.analyzeText(connection, 'Яблоко 180 г'),
            throwsA(
              isA<PhotoFailure>().having(
                (error) => error.message,
                'message',
                isNot(contains('снимок')),
              ),
            ),
          );
        } finally {
          service.close();
        }
      }
    },
  );
  testWidgets(
    'text is retained on consent refusal; review is explicitly confirmed and labelled as text',
    (tester) async {
      var requests = 0;
      PhotoMeal? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: fitLifeTheme(),
          home: TextMealPage(
            day: DateTime(2026, 10, 22),
            meal: 'Обед',
            store: MemoryPhotoConnection(connection),
            createService: () => PhotoService(
              client: MockClient((request) async {
                requests++;
                return http.Response(
                  jsonEncode(result(request.headers['X-Request-Id']!)),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                );
              }),
            ),
            onSave: (meal) async {
              saved = meal;
              throw StateError('disk');
            },
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('meal-description')),
        'Рис варёный 150 г',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('text-analyze')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('text-analyze')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('Остальной дневник не отправляется'),
        findsOneWidget,
      );
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(saved, isNull);
      expect(find.text('Рис варёный 150 г'), findsOneWidget);
      await tester.tap(find.byKey(const Key('text-analyze')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Отправить'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(saved, isNull);
      expect(find.text('ОЦЕНКА ПО ОПИСАНИЮ'), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const Key('photo-save')), 150);
      await tester.tap(find.byKey(const Key('photo-save')));
      await tester.pumpAndSettle();
      expect(saved!.source, MealEstimateSource.text);
      expect(saved!.day, DateTime(2026, 10, 22));
      expect(find.textContaining('Не удалось сохранить'), findsOneWidget);
    },
  );
}
