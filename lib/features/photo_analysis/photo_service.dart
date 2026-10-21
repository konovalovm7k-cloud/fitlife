import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'photo_models.dart';

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
  const PhotoConnectionStore();
  static const _storage = FlutterSecureStorage();
  static const _key = 'fitlife_photo_connection_v1';
  Future<PhotoConnection?> read() async {
    final raw = await _storage
        .read(key: _key)
        .timeout(const Duration(seconds: 10));
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PhotoConnection(json['address'] as String, json['token'] as String);
  }

  Future<void> write(PhotoConnection connection) => _storage
      .write(
        key: _key,
        value: jsonEncode({
          'address': connection.address,
          'token': connection.token,
        }),
      )
      .timeout(const Duration(seconds: 10));
  Future<void> clear() =>
      _storage.delete(key: _key).timeout(const Duration(seconds: 10));
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
    final id = photoRequestId();
    try {
      return await (() async {
        final request = http.Request('POST', connection.endpoint)
          ..followRedirects = false
          ..headers.addAll({
            'Authorization': 'Bearer ${connection.token}',
            'Content-Type': 'image/jpeg',
            'X-Request-Id': id,
          })
          ..bodyBytes = jpeg;
        final response = await _client.send(request);
        if (response.statusCode != 200) {
          unawaited(response.stream.listen((_) {}).cancel());
          throw PhotoFailure(switch (response.statusCode) {
            401 ||
            403 => 'Код доступа не принят. Проверьте подключение к серверу.',
            413 || 415 => 'Сервер не принял фото. Выберите другой снимок.',
            422 =>
              'Не удалось распознать еду. Попробуйте снимок ближе или ручной ввод.',
            429 =>
              'Лимит распознаваний исчерпан. Попробуйте позже или добавьте еду вручную.',
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
        return PhotoAnalysis.fromJson(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
          id,
        );
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
