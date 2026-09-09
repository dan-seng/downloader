import 'dart:convert';
import 'dart:io' as io;
import '../models/download_archive_item.dart';

/// Service managing persistent on-disk JSON archiving of completed downloads.
class ArchiveService {
  final String? customStoragePath;

  ArchiveService({this.customStoragePath});

  /// Resolves the file path for storing the archive JSON database.
  Future<String> getStorageFilePath() async {
    final custom = customStoragePath;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }

    final home = io.Platform.environment['HOME'] ??
        io.Platform.environment['USERPROFILE'] ??
        io.Directory.current.path;

    final configDir = io.Directory('$home/.spidey_dlx');
    if (!configDir.existsSync()) {
      try {
        configDir.createSync(recursive: true);
      } catch (_) {
        return '$home/.spidey_dlx_archive.json';
      }
    }
    return '${configDir.path}/library_archive.json';
  }

  /// Loads all archived downloads from disk, refreshing live file status.
  Future<List<DownloadArchiveItem>> loadArchive() async {
    try {
      final filePath = await getStorageFilePath();
      final file = io.File(filePath);
      if (!file.existsSync()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(content) as List<dynamic>;
      final items = <DownloadArchiveItem>[];

      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          try {
            items.add(DownloadArchiveItem.fromJson(entry));
          } catch (_) {
            // Ignore malformed individual entries
          }
        }
      }

      // Sort newest first
      items.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Saves or updates a download record in the archive.
  Future<void> saveItem(DownloadArchiveItem item) async {
    try {
      final items = await loadArchive();
      // Remove any previous entry with the same ID
      items.removeWhere((existing) => existing.id == item.id);
      // Insert at the front (most recent)
      items.insert(0, item);
      await _flushToFile(items);
    } catch (_) {
      // Non-fatal persistence failure
    }
  }

  /// Deletes an archive entry and optionally purges the physical file from disk.
  Future<bool> deleteItem(String id, {bool deleteFileFromDisk = false}) async {
    try {
      final items = await loadArchive();
      final index = items.indexWhere((it) => it.id == id);
      if (index == -1) return false;

      final item = items[index];

      if (deleteFileFromDisk && item.filePath.isNotEmpty) {
        final file = io.File(item.filePath);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {
            // Ignore file deletion errors
          }
        }
      }

      items.removeAt(index);
      await _flushToFile(items);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes all records whose target media files no longer exist on disk.
  Future<int> clearMissing() async {
    try {
      final items = await loadArchive();
      final initialCount = items.length;
      items.removeWhere((it) {
        if (it.filePath.isEmpty) return true;
        return !io.File(it.filePath).existsSync();
      });
      final removed = initialCount - items.length;
      if (removed > 0) {
        await _flushToFile(items);
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }

  /// Clears the entire archive, optionally deleting physical files.
  Future<void> clearAll({bool deleteFilesFromDisk = false}) async {
    try {
      if (deleteFilesFromDisk) {
        final items = await loadArchive();
        for (final item in items) {
          if (item.filePath.isNotEmpty) {
            final file = io.File(item.filePath);
            if (file.existsSync()) {
              try {
                file.deleteSync();
              } catch (_) {}
            }
          }
        }
      }

      final filePath = await getStorageFilePath();
      final file = io.File(filePath);
      if (file.existsSync()) {
        await file.writeAsString(jsonEncode([]));
      }
    } catch (_) {}
  }

  Future<void> _flushToFile(List<DownloadArchiveItem> items) async {
    final filePath = await getStorageFilePath();
    final file = io.File(filePath);
    final jsonList = items.map((it) => it.toJson()).toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonList));
  }
}
