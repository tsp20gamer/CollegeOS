import 'dart:isolate';
import 'dart:typed_data';

import 'package:college_os/features/feedback/data/feedback_api_client.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:image/image.dart' as img;

/// The longest side a screenshot keeps after compression.
const int feedbackScreenshotMaxSide = 1600;

/// Reads the image format from its first bytes, as the service does.
String? sniffImageMimeType(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

/// Thrown when a picked file is not an image the report can carry.
class ScreenshotUnsupported implements Exception {
  const ScreenshotUnsupported(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Makes a picked image small enough to send.
///
/// The picker already scales photos down natively; this pass is the safety
/// net for what it leaves large (full-resolution PNG screenshots, HEIC that
/// the picker converted, very detailed photos). A JPEG, PNG or WebP that is
/// already under the limit and no larger than [feedbackScreenshotMaxSide] is
/// sent untouched; anything else is decoded off the UI thread, scaled, and
/// re-encoded as JPEG at falling quality until it fits.
Future<FeedbackUpload> compressScreenshot(
  Uint8List bytes, {
  required String name,
}) async {
  final mime = sniffImageMimeType(bytes);
  if (mime != null && bytes.length <= feedbackMaxScreenshotBytes) {
    return FeedbackUpload(bytes: bytes, mimeType: mime, fileName: name);
  }
  final encoded = await Isolate.run(() => _reencode(bytes));
  if (encoded == null) {
    throw const ScreenshotUnsupported(
      'That file is not a picture CollegeOS can attach.',
    );
  }
  return FeedbackUpload(
    bytes: encoded,
    mimeType: 'image/jpeg',
    fileName: '${_baseName(name)}.jpg',
  );
}

Uint8List? _reencode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var image = decoded;
  var side = feedbackScreenshotMaxSide;
  for (var attempt = 0; attempt < 6; attempt++) {
    if (image.width > side || image.height > side) {
      image = image.width >= image.height
          ? img.copyResize(decoded, width: side)
          : img.copyResize(decoded, height: side);
    }
    for (final quality in const [80, 70, 60, 50]) {
      final jpeg = img.encodeJpg(image, quality: quality);
      if (jpeg.length <= feedbackMaxScreenshotBytes) return jpeg;
    }
    side = (side * 0.75).round();
  }
  return null;
}

String _baseName(String name) {
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}
