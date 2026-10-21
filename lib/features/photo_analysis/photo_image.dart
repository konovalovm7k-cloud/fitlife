import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'photo_service.dart';

Future<Uint8List> preparePhoto(Uint8List bytes) async {
  if (bytes.length > 15 * 1024 * 1024) {
    throw const PhotoFailure('Снимок слишком большой. Выберите фото до 15 МБ.');
  }
  try {
    return await compute(
      preparePhotoBytes,
      bytes,
    ).timeout(const Duration(seconds: 20));
  } catch (_) {
    throw const PhotoFailure(
      'Не удалось обработать фото. Выберите JPEG или PNG поменьше.',
    );
  }
}

Uint8List preparePhotoBytes(Uint8List bytes) {
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (info == null || info.width * info.height > 24000000) {
    throw const FormatException('Image dimensions exceed limit');
  }
  var image = decoder!.decodeFrame(0);
  if (image == null) throw const FormatException('Unsupported image');
  image = img.bakeOrientation(image);
  if (image.width > 1280 || image.height > 1280) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? 1280 : null,
      height: image.height > image.width ? 1280 : null,
    );
  }
  // Re-encoding alone preserves EXIF in this library. Remove it explicitly.
  image.exif = img.ExifData();
  image.iccProfile = null;
  for (final quality in [82, 65, 45]) {
    final jpeg = img.encodeJpg(
      image,
      quality: quality,
      chroma: img.JpegChroma.yuv420,
    );
    if (jpeg.length <= 512 * 1024) return jpeg;
  }
  throw const FormatException('Image too large');
}
