import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/platform/external_activity.dart';
import '../domain/scan_parser.dart';

// Scanning pages (docs/spec/F4-02 §3): capture, straighten, read. Nothing
// here touches the network; ML Kit reads the text on the phone.

/// The scan's cache folder. Everything in it is deleted when the scan closes.
Future<Directory> scanCacheDir() async => Directory('${(await getTemporaryDirectory()).path}/scan');

/// The scan cache folder; tests replace it.
final scanCacheProvider = Provider<Future<Directory> Function()>((ref) => scanCacheDir);

/// Deletes the scan cache folder [dir] and anything left in it.
Future<void> clearScanCache(Future<Directory> Function() dir) async {
  try {
    final folder = await dir();
    if (folder.existsSync()) await folder.delete(recursive: true);
  } on FileSystemException {
    // Already gone, or in use; the next scan clears it.
  }
}

/// A picture's size as shown (the phone's rotation flag applied).
Future<Size> pictureSize(String path) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final image = (await codec.getNextFrame()).image;
  final size = Size(image.width.toDouble(), image.height.toDouble());
  image.dispose();
  codec.dispose();
  return size;
}

/// Reads a picture's size; tests replace it.
final pictureSizeProvider = Provider<Future<Size> Function(String)>((ref) => pictureSize);

/// Opens the camera app or the system photo picker at print-text size
/// (longest side 2,400 px, quality 90) and returns the picture's path.
Future<String?> pickPage(ImageSource source) async {
  final x = await ExternalActivity.run(
      () => ImagePicker().pickImage(source: source, maxWidth: 2400, maxHeight: 2400, imageQuality: 90, requestFullMetadata: false));
  return x?.path;
}

/// The page picker; tests replace it.
final pagePickerProvider = Provider<Future<String?> Function(ImageSource)>((ref) => pickPage);

/// [p] (0–1, in the turned picture as shown) in the unturned picture (0–1).
/// [quarterTurns] counts clockwise turns.
Offset unturn(Offset p, int quarterTurns) => switch (quarterTurns % 4) {
      1 => Offset(p.dy, 1 - p.dx),
      2 => Offset(1 - p.dx, 1 - p.dy),
      3 => Offset(1 - p.dy, p.dx),
      _ => p,
    };

/// The 3×3 perspective transform (row by row, last entry 1) that takes each
/// of the four [from] points to the matching [to] point.
List<double> homography(List<Offset> from, List<Offset> to) {
  // Eight equations in h0…h7 (h8 = 1), solved by Gaussian elimination.
  final a = List.generate(8, (_) => List<double>.filled(9, 0));
  for (var i = 0; i < 4; i++) {
    final (x, y, u, v) = (from[i].dx, from[i].dy, to[i].dx, to[i].dy);
    a[2 * i].setAll(0, [x, y, 1, 0, 0, 0, -u * x, -u * y, u]);
    a[2 * i + 1].setAll(0, [0, 0, 0, x, y, 1, -v * x, -v * y, v]);
  }
  for (var c = 0; c < 8; c++) {
    var pivot = c;
    for (var r = c + 1; r < 8; r++) {
      if (a[r][c].abs() > a[pivot][c].abs()) pivot = r;
    }
    if (a[pivot][c].abs() < 1e-12) throw StateError('Corners are in a line');
    final t = a[c];
    a[c] = a[pivot];
    a[pivot] = t;
    for (var r = 0; r < 8; r++) {
      if (r == c) continue;
      final f = a[r][c] / a[c][c];
      for (var k = c; k < 9; k++) {
        a[r][k] -= f * a[c][k];
      }
    }
  }
  return [for (var r = 0; r < 8; r++) a[r][8] / a[r][r], 1];
}

/// The homography as a column-major 4×4 matrix for [Canvas.transform].
Float64List matrixOf(List<double> h) => Float64List.fromList([
      h[0], h[3], 0, h[6], //
      h[1], h[4], 0, h[7],
      0, 0, 1, 0,
      h[2], h[5], 0, h[8],
    ]);

/// Straightens the page in [picture]: the four [corners] (top left, top right,
/// bottom right, bottom left; 0–1 in the picture turned [quarterTurns] times)
/// are mapped to a rectangle, written as PNG to [out]. Returns its size.
Future<Size> straightenPage(String picture, List<Offset> corners, int quarterTurns, String out) async {
  final codec = await ui.instantiateImageCodec(await File(picture).readAsBytes());
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  try {
    final w = image.width.toDouble(), h = image.height.toDouble();
    final src = [for (final c in corners) unturn(c, quarterTurns).scale(w, h)];
    final top = (src[1] - src[0]).distance, bottom = (src[2] - src[3]).distance;
    final left = (src[3] - src[0]).distance, right = (src[2] - src[1]).distance;
    var ow = top > bottom ? top : bottom, oh = left > right ? left : right;
    final fit = [1.0, 2400 / ow, 3200 / oh].reduce((a, b) => a < b ? a : b);
    ow = (ow * fit).roundToDouble().clamp(1, 2400);
    oh = (oh * fit).roundToDouble().clamp(1, 3200);
    final m = homography(src, [Offset.zero, Offset(ow, 0), Offset(ow, oh), Offset(0, oh)]);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, ow, oh));
    canvas.drawRect(Rect.fromLTWH(0, 0, ow, oh), Paint()..color = const Color(0xFFFFFFFF));
    canvas.transform(matrixOf(m));
    canvas.drawImage(image, Offset.zero, Paint()..filterQuality = FilterQuality.medium);
    final picture0 = recorder.endRecording();
    final result = await picture0.toImage(ow.toInt(), oh.toInt());
    picture0.dispose();
    try {
      final png = await result.toByteData(format: ui.ImageByteFormat.png);
      await File(out).writeAsBytes(png!.buffer.asUint8List(), flush: true);
    } finally {
      result.dispose();
    }
    return Size(ow, oh);
  } finally {
    image.dispose();
  }
}

/// Reads the text on straightened pages. One reader is used for every page
/// of a scan, then closed (F4-02 §3 step 4).
abstract class PageReader {
  Future<ScanPage> read(String path, Size size);
  Future<void> close();
}

class MlKitPageReader implements PageReader {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<ScanPage> read(String path, Size size) async {
    final text = await _recognizer.processImage(InputImage.fromFilePath(path));
    return ScanPage(width: size.width, height: size.height, lines: [
      for (final b in text.blocks)
        for (final l in b.lines)
          ScanLine(l.text,
              left: l.boundingBox.left,
              top: l.boundingBox.top,
              width: l.boundingBox.width,
              height: l.boundingBox.height,
              confidence: l.confidence),
    ]);
  }

  @override
  Future<void> close() => _recognizer.close();
}

/// Makes the reader for one scan; tests replace it.
final pageReaderProvider = Provider<PageReader Function()>((ref) => MlKitPageReader.new);

/// Makes the straightened page; tests replace it (the engine's PNG encoder
/// doesn't run in widget tests).
final pageStraightenerProvider = Provider<Future<Size> Function(String, List<Offset>, int, String)>((ref) => straightenPage);
