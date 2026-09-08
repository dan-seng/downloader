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
}
