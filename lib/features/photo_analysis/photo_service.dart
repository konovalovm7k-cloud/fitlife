import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'photo_models.dart';
import '../chef/chef_catalogue.dart';

class PhotoFailure implements Exception {
  const PhotoFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class PhotoConnection {
  PhotoConnection(String address, this.token)
    : endpoint = parseAddress(address) {
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      throw const FormatException('Введите индивидуальный код из 43 символов');
    }
  }
  final Uri endpoint;
  final String token;
  static Uri parseAddress(String address) {
    final uri = Uri.tryParse(address.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        !uri.host.contains('.') ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.port != 443) {
      throw const FormatException(
        'Нужен адрес HTTPS без пути, например https://fitlife.example.com',
      );
    }
    return uri.replace(path: '/v1/analyze');
  }

  String get address => endpoint.origin;
}

class PhotoConnectionStore {
  const PhotoConnectionStore({
    this.automaticAddress = const String.fromEnvironment(
      'FITLIFE_PHOTO_SERVER',
    ),
    this.automaticToken = const String.fromEnvironment('FITLIFE_PHOTO_TOKEN'),
  });
  final String automaticAddress;
  final String automaticToken;
  static const _storage = FlutterSecureStorage();
  static const _key = 'fitlife_photo_connection_v1';
  static const _disabledKey = 'fitlife_photo_automatic_disabled_v1';
  bool get hasAutomaticConnection =>
      automaticAddress.isNotEmpty && automaticToken.isNotEmpty;

  Future<PhotoConnection?> read() => (() async {
    if (await _storage.read(key: _disabledKey) == '1') return null;
    final raw = await _storage.read(key: _key);
    if (raw == null && hasAutomaticConnection) {
      final connection = PhotoConnection(automaticAddress, automaticToken);
      await _persist(connection);
      if (await _storage.read(key: _disabledKey) == '1') return null;
      return connection;
    }
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PhotoConnection(json['address'] as String, json['token'] as String);
  })().timeout(const Duration(seconds: 10));

  Future<void> _persist(PhotoConnection connection) => _storage
      .write(
        key: _key,
        value: jsonEncode({
          'address': connection.address,
          'token': connection.token,
        }),
      )
      .timeout(const Duration(seconds: 10));
  Future<void> write(PhotoConnection connection) => (() async {
    await _persist(connection);
    await _storage.delete(key: _disabledKey);
  })().timeout(const Duration(seconds: 10));
  Future<void> clear() => (() async {
    // An explicit disconnect must not silently re-enable bundled access.
    await _storage.write(key: _disabledKey, value: '1');
    await _storage.delete(key: _key);
  })().timeout(const Duration(seconds: 10));

  Future<PhotoConnection?> restoreAutomatic() async {
    if (!hasAutomaticConnection) return null;
    final connection = PhotoConnection(automaticAddress, automaticToken);
    await write(connection);
    return connection;
  }
}

String photoRequestId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

class PhotoService {
  PhotoService({
    http.Client? client,
    this.timeout = const Duration(seconds: 50),
  }) : _client = client ?? http.Client();
  final http.Client _client;
  final Duration timeout;
  void close() => _client.close();

  Future<PhotoAnalysis> analyze(
    PhotoConnection connection,
    Uint8List jpeg,
  ) async {
    if (jpeg.length > 512 * 1024 ||
        jpeg.length < 4 ||
        jpeg[0] != 255 ||
        jpeg[1] != 216 ||
        jpeg[2] != 255 ||
        jpeg[jpeg.length - 2] != 255 ||
        jpeg.last != 217) {
      throw const PhotoFailure(
        'Подготовьте другое фото: нужен JPEG до 512 КБ.',
      );
    }
    return _send(connection, jpeg, 'image/jpeg', MealEstimateSource.photo);
  }

  Future<PhotoAnalysis> analyzeText(PhotoConnection connection, String text) {
    final description = text.trim();
    if (description.isEmpty ||
        description.length > 2000 ||
        RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(description)) {
      throw const PhotoFailure('Опишите еду: от 1 до 2000 символов.');
    }
    return _send(
      connection,
      Uint8List.fromList(utf8.encode(jsonEncode({'text': description}))),
      'application/json',
      MealEstimateSource.text,
    );
  }

  Future<PhotoAnalysis> suggestMeal(
    PhotoConnection connection,
    String text,
    ChefCatalogue catalogue,
  ) {
    final description = text.trim();
    if (description.isEmpty ||
        description.length > 2000 ||
        RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(description)) {
      throw const PhotoFailure('Укажите продукты: от 1 до 2000 символов.');
    }
    return _send(
      connection,
      Uint8List.fromList(utf8.encode(jsonEncode({'text': description}))),
      'application/json',
      MealEstimateSource.chef,
      catalogue: catalogue,
    );
  }

  Future<PhotoAnalysis> _send(
    PhotoConnection connection,
    Uint8List body,
    String contentType,
    MealEstimateSource source, {
    ChefCatalogue? catalogue,
  }) async {
    final id = photoRequestId();
    try {
      return await (() async {
        final endpoint = source == MealEstimateSource.chef
            ? connection.endpoint.replace(path: '/v2/chef')
            : source == MealEstimateSource.text
            ? connection.endpoint.replace(path: '/v2/identify-text')
            : connection.endpoint.replace(path: '/v2/identify');
        final request = http.Request('POST', endpoint)
          ..followRedirects = false
          ..headers.addAll({
            'Authorization': 'Bearer ${connection.token}',
            'Content-Type': contentType,
            'X-Request-Id': id,
          })
          ..bodyBytes = body;
        final response = await _client.send(request);
        if (response.statusCode != 200) {
          unawaited(response.stream.listen((_) {}).cancel());
          throw PhotoFailure(switch (response.statusCode) {
            400 || 413 || 415 when source == MealEstimateSource.chef =>
              'Сервер не принял список продуктов. Сократите текст и проверьте описание.',
            422 when source == MealEstimateSource.chef =>
              'Не удалось подобрать сочетание. Уточните готовые продукты или выберите локальную идею.',
            429 when source == MealEstimateSource.chef =>
              'Лимит AI-запросов исчерпан. Локальные идеи работают без запроса.',
            404 when source == MealEstimateSource.chef =>
              'Сервер ещё не поддерживает AI Chef. Используйте локальные идеи или обновите сервер.',
            401 ||
            403 => 'Код доступа не принят. Проверьте подключение к серверу.',
            400 when source == MealEstimateSource.text =>
              'Сервер не принял описание. Укажите еду текстом: от 1 до 2000 символов.',
            413 || 415 =>
              source == MealEstimateSource.text
                  ? 'Сервер не принял описание. Сократите текст и повторите попытку.'
                  : 'Сервер не принял фото. Выберите другой снимок.',
            422 =>
              source == MealEstimateSource.text
                  ? 'Не удалось разобрать описание еды. Уточните продукты и порции или добавьте их вручную.'
                  : 'Не удалось распознать еду. Попробуйте снимок ближе или ручной ввод.',
            429 =>
              'Лимит распознаваний исчерпан. Попробуйте позже или добавьте еду вручную.',
            404 =>
              'Сервер ещё не поддерживает проверку состава. Добавьте еду вручную или обновите сервер распознавания.',
            504 => 'Сервис не успел ответить. Повторите позже.',
            _ =>
              'Сервис временно недоступен. Проверьте адрес сервера или повторите позже.',
          });
        }
        final bytes = <int>[];
        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
          if (bytes.length > 65536) {
            throw const FormatException('Response too large');
          }
        }
        final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        if (source == MealEstimateSource.chef) {
          if (catalogue == null) {
            throw const FormatException('Missing Chef catalogue');
          }
          return catalogue.resolve(data, id);
        }
        return PhotoAnalysis.fromJson(data, id, source: source);
      })().timeout(timeout);
    } on PhotoFailure {
      rethrow;
    } on TimeoutException {
      close();
      throw const PhotoFailure(
        'Время ожидания истекло. Проверьте интернет и повторите позже.',
      );
    } on FormatException {
      throw const PhotoFailure(
        'Ответ сервера некорректен. Попробуйте позже или введите продукты вручную.',
      );
    } on TypeError {
      throw const PhotoFailure('Ответ сервера некорректен. Попробуйте позже.');
    } catch (_) {
      throw const PhotoFailure(
        'Нет соединения с сервером. Проверьте интернет и адрес подключения.',
      );
    }
  }
}
