import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fitlife/features/photo_analysis/photo_image.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/photo_analysis/photo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

const sampleFood = <String, dynamic>{
  'name': 'Рис варёный',
  'grams': 150,
  'kcal': 130,
  'protein': 2.7,
  'fat': 0.3,
  'carbs': 28,
  'fiber': 0.4,
  'confidence': 'medium',
};
final connection = PhotoConnection('https://fitlife.example.com', 'a' * 43);
final jpeg = Uint8List.fromList([255, 216, 255, 224, 255, 217]);
Map<String, dynamic> result(String id) => {
  'version': 1,
  'requestId': id,
  'items': [sampleFood],
  'warnings': <String>[],
};

void main() {
  test(
    'HTTPS address forbids credentials, redirects through paths and query secrets',
    () {
      for (final address in [
        'http://example.com',
        'https://example.com/key',
        'https://user:pass@example.com',
        'https://example.com?key=x',
        'https://example.com#x',
        'https://example.com:8443',
        'https://localhost',
      ]) {
        expect(() => PhotoConnection(address, 'a' * 43), throwsFormatException);
      }
      expect(
        connection.endpoint.toString(),
        'https://fitlife.example.com/v1/analyze',
      );
      expect(
        () => PhotoConnection(connection.address, 'short'),
        throwsFormatException,
      );
    },
  );
  test(
    'request is authenticated JPEG; validated per-100g values scale to portion',
    () async {
      http.Request? sent;
      final service = PhotoService(
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode(result(request.headers['X-Request-Id']!)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(service.close);
      final analysis = await service.analyze(connection, jpeg);
      expect(sent!.headers['Authorization'], 'Bearer ${connection.token}');
      expect(sent!.headers['Content-Type'], 'image/jpeg');
      expect(sent!.followRedirects, isFalse);
      expect(sent!.bodyBytes, jpeg);
      expect(analysis.items.single.calories, 195);
      expect(analysis.items.single.nutrition.kcal, 130);
    },
  );
  test('invalid nutrition and contract never pass as food', () {
    for (final patch in [
      {'kcal': -1},
      {'grams': double.nan},
      {'fat': 101},
      {'confidence': '99%'},
      {'name': ''},
      {'protein': 80, 'fat': 80},
    ]) {
      expect(
        () => PhotoFood.fromJson({...sampleFood, ...patch}),
        throwsFormatException,
      );
    }
    expect(
      () => PhotoAnalysis.fromJson(result('wrong'), 'id'),
      throwsFormatException,
    );
    expect(
      () => PhotoAnalysis.fromJson({...result('id'), 'version': 2}, 'id'),
      throwsFormatException,
    );
  });
  test(
    'status errors and malformed/oversized responses are safe and never retried',
    () async {
      for (final status in [401, 413, 422, 429, 503, 504, 302]) {
        var calls = 0;
        final service = PhotoService(
          client: MockClient((_) async {
            calls++;
            return http.Response('sensitive provider details', status);
          }),
        );
        await expectLater(
          service.analyze(connection, jpeg),
          throwsA(
            isA<PhotoFailure>().having(
              (e) => e.message,
              'safe error',
              isNot(contains('sensitive')),
            ),
          ),
        );
        expect(calls, 1);
        service.close();
      }
      for (final body in ['invalid-json', 'x' * 65537, '[]']) {
        final service = PhotoService(
          client: MockClient((_) async => http.Response(body, 200)),
        );
        await expectLater(
          service.analyze(connection, jpeg),
          throwsA(isA<PhotoFailure>()),
        );
        service.close();
      }
    },
  );
  test(
    'timeout terminates waiting and bad input does not hit network',
    () async {
      var calls = 0;
      final pending = Completer<http.Response>();
      final service = PhotoService(
        timeout: const Duration(milliseconds: 5),
        client: MockClient((_) {
          calls++;
          return pending.future;
        }),
      );
      await expectLater(
        service.analyze(connection, Uint8List(4)),
        throwsA(isA<PhotoFailure>()),
      );
      expect(calls, 0);
      await expectLater(
        service.analyze(connection, jpeg),
        throwsA(
          isA<PhotoFailure>().having(
            (e) => e.message,
            'timeout',
            contains('Время ожидания'),
          ),
        ),
      );
      expect(calls, 1);
      pending.complete(http.Response('{}', 200));
      service.close();
    },
  );
  test('photo is resized, oriented and stripped of EXIF/GPS before upload', () {
    final source = img.Image(width: 1600, height: 800);
    source.exif.imageIfd[0x010f] = 'Secret Camera';
    source.exif.imageIfd.orientation = 6;
    source.exif.gpsIfd[1] = 'N';
    final original = img.encodeJpg(source);
    expect(latin1.decode(original), contains('Secret Camera'));
    final prepared = preparePhotoBytes(original);
    final decoded = img.decodeJpg(prepared)!;
    expect(decoded.width, 640);
    expect(decoded.height, 1280);
    expect(prepared.length, lessThanOrEqualTo(512 * 1024));
    expect(latin1.decode(prepared), isNot(contains('Secret Camera')));
    expect(decoded.exif.gpsIfd.isEmpty, isTrue);
    expect(() => preparePhotoBytes(Uint8List(4)), throwsFormatException);
  });
}
