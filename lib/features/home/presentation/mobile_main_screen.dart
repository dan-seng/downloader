import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../controllers/video_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'mobile_downloader_tab.dart';
import 'mobile_downloads_tab.dart';
import 'mobile_library_tab.dart';
import 'mobile_settings_tab.dart';

/// Root native mobile container with Material 3 Bottom Navigation Bar and dedicated mobile tabs.
class MobileMainScreen extends StatefulWidget {
  final VideoController videoController;
  final DownloadController downloadController;
  final ValueNotifier<ThemeMode>? themeModeNotifier;

  const MobileMainScreen({
    super.key,
    required this.videoController,
    required this.downloadController,
    this.themeModeNotifier,
  });

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _currentIndex = 0;
  bool _hasPromptedPermission = false;

  @override
  void initState() {
    super.initState();
    if (io.Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkStartupStoragePermission();
      });
    }
  }

  Future<void> _checkStartupStoragePermission() async {
    if (_hasPromptedPermission || !mounted) return;
    _hasPromptedPermission = true;

    final hasPermission = await widget.downloadController.checkStoragePermission();
    if (!hasPermission && mounted) {
      _showStoragePermissionDialog();
    }
  }

  void _showStoragePermissionDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final activeColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: bgRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: borderColor),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder_shared_rounded, size: 24, color: activeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Storage Access Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textHi,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VINX saves your downloads directly to your device\'s public Downloads folder (/storage/emulated/0/Download/VINX).',
              style: TextStyle(fontSize: 13.5, color: textHi, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Granting storage permission allows downloaded videos and music to immediately appear in your Gallery, Files, and media players.',
              style: TextStyle(fontSize: 12.5, color: textDim, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Later', style: TextStyle(color: textDim)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final granted = await widget.downloadController.requestStoragePermission();
              if (mounted && granted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✓ Storage access granted! Saving to Downloads/VINX'),
                    backgroundColor: Colors.green.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Grant Access', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleTheme() {
    final notifier = widget.themeModeNotifier;
    if (notifier == null) return;

    if (notifier.value == ThemeMode.dark) {
      notifier.value = ThemeMode.light;
    } else if (notifier.value == ThemeMode.light) {
      notifier.value = ThemeMode.dark;
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      notifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgDeep = isDark ? SpideyColors.darkBgDeep : SpideyColors.lightBgDeep;
    final bgPanel = isDark ? SpideyColors.darkBgPanel : SpideyColors.lightBgPanel;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final activeColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgPanel,
        elevation: 0,
        titleSpacing: 16,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VINX',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: textHi,
                  ),
                ),
                Text(
                  'MEDIA DOWNLOADER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: textDim,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.themeModeNotifier != null)
            IconButton(
              onPressed: _toggleTheme,
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
                color: textHi,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            MobileDownloaderTab(
              videoController: widget.videoController,
              downloadController: widget.downloadController,
              onNavigateToDownloads: () => _navigateToIndex(1),
            ),
            MobileDownloadsTab(
              downloadController: widget.downloadController,
              onNavigateToDownloader: () => _navigateToIndex(0),
            ),
            MobileLibraryTab(
              downloadController: widget.downloadController,
              onReDownload: (url) {
                widget.videoController.analyzeUrl(url);
                _navigateToIndex(0);
              },
            ),
            MobileSettingsTab(
              downloadController: widget.downloadController,
              themeModeNotifier: widget.themeModeNotifier,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgPanel,
          border: Border(top: BorderSide(color: borderColor, width: 0.8)),
        ),
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: widget.downloadController,
            builder: (context, _) {
              final activeCount = widget.downloadController.activeTasks.length;
              final archiveCount = widget.downloadController.archiveItems.length;

              return NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _navigateToIndex,
                backgroundColor: bgPanel,
                elevation: 0,
                indicatorColor: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.download_outlined, color: textDim),
                    selectedIcon: Icon(Icons.download_rounded, color: textHi),
                    label: 'Downloader',
                  ),
                  NavigationDestination(
                    icon: activeCount > 0
                        ? Badge(
                            label: Text('$activeCount'),
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.hourglass_bottom_outlined, color: textDim),
                          )
                        : Icon(Icons.hourglass_bottom_outlined, color: textDim),
                    selectedIcon: activeCount > 0
                        ? Badge(
                            label: Text('$activeCount'),
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.hourglass_bottom_rounded, color: textHi),
                          )
                        : Icon(Icons.hourglass_bottom_rounded, color: textHi),
                    label: 'Downloads',
                  ),
                  NavigationDestination(
                    icon: archiveCount > 0
                        ? Badge(
                            label: Text('$archiveCount'),
                            backgroundColor: isDark ? Colors.white24 : Colors.black26,
                            child: Icon(Icons.video_library_outlined, color: textDim),
                          )
                        : Icon(Icons.video_library_outlined, color: textDim),
                    selectedIcon: archiveCount > 0
                        ? Badge(
                            label: Text('$archiveCount'),
                            backgroundColor: isDark ? Colors.white24 : Colors.black26,
                            child: Icon(Icons.video_library_rounded, color: textHi),
                          )
                        : Icon(Icons.video_library_rounded, color: textHi),
                    label: 'Library',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined, color: textDim),
                    selectedIcon: Icon(Icons.settings_rounded, color: textHi),
                    label: 'Settings',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
