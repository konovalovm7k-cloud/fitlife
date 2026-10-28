import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/features/photo_analysis/photo_page.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/photo_analysis/photo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'photo_service_test.dart' show result;

class MemoryPhotoConnection extends PhotoConnectionStore {
  MemoryPhotoConnection(this.connection);
  PhotoConnection? connection;
  @override
  Future<PhotoConnection?> read() async => connection;
}

class ControlledPhotoService extends PhotoService {
  final pending = Completer<PhotoAnalysis>();
  int closes = 0;
  @override
  Future<PhotoAnalysis> analyze(PhotoConnection connection, Uint8List jpeg) =>
      pending.future;
  @override
  void close() {
    closes++;
    super.close();
  }
}

void main() {
  testWidgets(
    'cancel is enabled during request; stale completion cannot close retry',
    (tester) async {
      final first = ControlledPhotoService();
      final second = ControlledPhotoService();
      var created = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: fitLifeTheme(),
          home: Scaffold(
            body: PhotoPage(
              day: DateTime(2026, 10, 20),
              meal: 'Обед',
              onManual: () {},
              onSave: (_) async {},
              store: MemoryPhotoConnection(
                PhotoConnection('https://fitlife.example.com', 'a' * 43),
              ),
              pickImage: (_) async =>
                  img.encodePng(img.Image(width: 24, height: 24)),
              createService: () => created++ == 0 ? first : second,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Галерея'));
        for (var i = 0; i < 50; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.text('Фото готово к анализу').evaluate().isNotEmpty) break;
        }
      });
      await tester.pumpAndSettle();
      Future<void> send() async {
        await tester.ensureVisible(find.byKey(const Key('photo-analyze')));
        await tester.tap(find.byKey(const Key('photo-analyze')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Отправить'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await send();
      await tester.ensureVisible(find.text('Отменить ожидание'));
      final cancel = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Отменить ожидание'),
      );
      expect(cancel.onPressed, isNotNull);
      await tester.tap(find.text('Отменить ожидание'));
      await tester.pumpAndSettle();
      expect(first.closes, greaterThan(0));
      await send();
      first.pending.complete(
        PhotoAnalysis.fromJson(result('a' * 32), 'a' * 32),
      );
      await tester.pump();
      expect(second.closes, 0);
      expect(find.text('Проверьте блюдо'), findsNothing);
      second.pending.complete(
        PhotoAnalysis.fromJson(result('b' * 32), 'b' * 32),
      );
      await tester.pumpAndSettle();
      expect(find.text('Проверьте блюдо'), findsOneWidget);
    },
  );
  testWidgets(
    'consent rejection sends nothing; accepted photo opens review without auto-save',
    (tester) async {
      var requests = 0;
      var saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: fitLifeTheme(),
          home: Scaffold(
            body: PhotoPage(
              day: DateTime(2026, 10, 20),
              meal: 'Обед',
              onManual: () {},
              onSave: (_) async {
                saves++;
              },
              store: MemoryPhotoConnection(
                PhotoConnection('https://fitlife.example.com', 'a' * 43),
              ),
              pickImage: (_) async =>
                  img.encodePng(img.Image(width: 24, height: 24)),
              createService: () => PhotoService(
                client: MockClient((request) async {
                  requests++;
                  return http.Response(
                    jsonEncode(result(request.headers['X-Request-Id']!)),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8',
                    },
                  );
                }),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Галерея'));
        for (var i = 0; i < 50; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.text('Фото готово к анализу').evaluate().isNotEmpty) break;
        }
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('photo-analyze')));
      await tester.tap(find.byKey(const Key('photo-analyze')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Google может использовать'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(saves, 0);
      await tester.tap(find.byKey(const Key('photo-analyze')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Отправить'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(saves, 0);
      expect(find.text('Проверьте блюдо'), findsOneWidget);
      expect(find.text('Нужен источник состава'), findsOneWidget);
      expect(find.textContaining('195 ккал'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
