import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' as pp;

/// Service handling downloads storage path resolution, directory picking,
/// and native file manager interaction.
class StorageService {
  const StorageService();

  /// Gets the default system downloads folder.
  Future<String> getDefaultDownloadsDirectory() async {
    try {
      final dir = await pp.getDownloadsDirectory();
      if (dir != null && await dir.exists()) {
        return dir.path;
      }
    } catch (_) {
      // Fallback below
    }

    // Platform-specific environment fallbacks
    if (io.Platform.isLinux) {
      final xdg = io.Platform.environment['XDG_DOWNLOAD_DIR'];
      if (xdg != null && xdg.isNotEmpty && await io.Directory(xdg).exists()) {
        return xdg;
      }
      final home = io.Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final downloads = io.Directory('$home/Downloads');
        if (await downloads.exists()) {
          return downloads.path;
        }
      }
    } else if (io.Platform.isWindows) {
      final userProfile = io.Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        final downloads = io.Directory('$userProfile\\Downloads');
        if (await downloads.exists()) {
          return downloads.path;
        }
      }
    }

    return io.Directory.current.path;
  }

  /// Prompts the user with a native folder picker dialog.
  Future<String?> pickDirectory({String? initialDirectory}) async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Download Folder',
      initialDirectory: initialDirectory,
    );
    return result;
  }

  /// Opens the folder containing the downloaded file in the native file manager.
  Future<void> openDirectory(String directoryPath) async {
    if (directoryPath.isEmpty) return;

    if (io.Platform.isLinux) {
      await io.Process.run('xdg-open', [directoryPath]);
    } else if (io.Platform.isWindows) {
      await io.Process.run('explorer.exe', [directoryPath]);
    } else if (io.Platform.isMacOS) {
      await io.Process.run('open', [directoryPath]);
    }
  }

  /// Reveals or opens the downloaded file with the default system viewer.
  Future<void> openFile(String filePath) async {
    if (filePath.isEmpty) return;

    final file = io.File(filePath);
    if (!await file.exists()) {
      // If file doesn't exist directly, open parent directory
      final parent = io.File(filePath).parent.path;
      await openDirectory(parent);
      return;
    }

    if (io.Platform.isLinux) {
      await io.Process.run('xdg-open', [filePath]);
    } else if (io.Platform.isWindows) {
      await io.Process.run('explorer.exe', ['/select,', filePath]);
    } else if (io.Platform.isMacOS) {
      await io.Process.run('open', ['-R', filePath]);
    }
  }

  /// Checks if a directory path exists on disk.
  Future<bool> directoryExists(String path) async {
    if (path.trim().isEmpty) return false;
    return io.Directory(path.trim()).exists();
  }

  /// Gets quick preset directories based on OS environment (e.g. Downloads, Videos, Desktop).
  Future<Map<String, String>> getQuickDirectories() async {
    final dirs = <String, String>{};
    try {
      final defaultDownloads = await getDefaultDownloadsDirectory();
      if (defaultDownloads.isNotEmpty) {
        dirs['Downloads'] = defaultDownloads;
      }

      final home = io.Platform.environment['HOME'] ?? io.Platform.environment['USERPROFILE'] ?? '';
      if (home.isNotEmpty) {
        final videos = io.Directory(io.Platform.isWindows ? '$home\\Videos' : '$home/Videos');
        if (await videos.exists()) {
          dirs['Videos'] = videos.path;
        }

        final desktop = io.Directory(io.Platform.isWindows ? '$home\\Desktop' : '$home/Desktop');
        if (await desktop.exists()) {
          dirs['Desktop'] = desktop.path;
        }

        final homeDir = io.Directory(home);
        if (await homeDir.exists()) {
          dirs['Home'] = homeDir.path;
        }
      }
    } catch (_) {
      // Ignore directory check errors
    }

    return dirs;
  }
}
