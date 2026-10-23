import 'dart:convert';
import 'package:fitlife/features/photo_analysis/photo_page.dart';
import 'package:fitlife/features/photo_analysis/photo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  final automatic = PhotoConnectionStore(
    automaticAddress: 'https://personal.example.com',
    automaticToken: 'a' * 43,
  );

  test(
    'public build has no shared credential; personal build bootstraps secure storage',
    () async {
      expect(await const PhotoConnectionStore().read(), isNull);
      final first = await automatic.read();
      expect(first!.address, 'https://personal.example.com');
      expect(first.token, 'a' * 43);
      final cold = await const PhotoConnectionStore().read();
      expect(cold!.token, first.token);
    },
  );

  test(
    'manual settings win; disconnect remains disconnected; explicit restore works',
    () async {
      await automatic.read();
      await automatic.write(
        PhotoConnection('https://other.example.com', 'b' * 43),
      );
      expect((await automatic.read())!.token, 'b' * 43);
      await automatic.clear();
      expect(await automatic.read(), isNull);
      expect(await automatic.read(), isNull);
      expect(
        (await automatic.restoreAutomatic())!.address,
        'https://personal.example.com',
      );
      expect((await automatic.read())!.token, 'a' * 43);
    },
  );

  test(
    'invalid bundled credentials never create an insecure connection',
    () async {
      await expectLater(
        PhotoConnectionStore(
          automaticAddress: 'http://bad.example.com',
          automaticToken: 'a' * 43,
        ).read(),
        throwsFormatException,
      );
      expect(await const PhotoConnectionStore().read(), isNull);
    },
  );

  test('a late bootstrap write cannot undo an explicit disconnect', () async {
    await automatic.read();
    await automatic.clear();
    await const FlutterSecureStorage().write(
      key: 'fitlife_photo_connection_v1',
      value: jsonEncode({
        'address': 'https://personal.example.com',
        'token': 'a' * 43,
      }),
    );
    expect(await automatic.read(), isNull);
    await automatic.write(
      PhotoConnection('https://other.example.com', 'b' * 43),
    );
    expect((await automatic.read())!.address, 'https://other.example.com');
  });
  testWidgets(
    'personal camera becomes ready without a setup screen or uploading anything',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPage(
              day: DateTime(2026, 10, 22),
              meal: 'Обед',
              onManual: () {},
              onSave: (_) async {},
              store: automatic,
              pickImage: (_) async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Подключение готово.'),
        150,
      );
      expect(find.textContaining('Подключение готово.'), findsOneWidget);
      expect(find.textContaining('нужны адрес и личный код'), findsNothing);
      expect((await automatic.read())!.address, 'https://personal.example.com');
    },
  );
}
