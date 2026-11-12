import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Removes sensitive temporary files from the app cache so that
/// financial exports and receipt photos are not left on the device.
class TempFileCleaner {
  TempFileCleaner._();

  /// Name prefixes of the export files this app creates.
  static const _exportPrefixes = ['finance_tracker_', 'Tax receipts YA'];

  /// Leftover camera photos from image_picker (the app keeps its own copy).
  static const _imageExtensions = ['.jpg', '.jpeg', '.png', '.heic'];

  /// Deletes one file if it exists. Used right after a share finishes.
  static Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignore: a failed delete must not crash the app.
    }
  }

  /// Deletes leftover exports and camera photos from the cache, including
  /// the copies the share_plus package keeps in cache/share_plus.
  /// Called when the app starts and when the user logs out.
  static Future<void> purgeSensitiveCache() async {
    try {
      final cache = await getTemporaryDirectory();
      await for (final entity in cache.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last.toLowerCase();
        final isExport = _exportPrefixes.any((p) => name.startsWith(p.toLowerCase()));
        final isPhoto = _imageExtensions.any(name.endsWith);
        if (isExport || isPhoto) {
          await deleteFile(entity);
        }
      }
    } catch (_) {
      // Ignore: cleanup is best-effort and must not block the app.
    }
  }
}