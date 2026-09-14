import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/speed_limit.dart';

/// Dedicated mobile settings and engine status screen.
class MobileSettingsTab extends StatelessWidget {
  final DownloadController downloadController;
  final ValueNotifier<ThemeMode>? themeModeNotifier;

  const MobileSettingsTab({
    super.key,
    required this.downloadController,
    this.themeModeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgPanel = isDark ? SpideyColors.darkBgPanel : SpideyColors.lightBgPanel;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final activeColor = isDark ? Colors.white : Colors.black;

    final dlCtrl = downloadController;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings & Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textHi,
            ),
          ),
          const SizedBox(height: 14),

          // Storage Location Section
          _buildSectionCard(
            context,
            isDark,
            title: 'Download Directory',
            icon: Icons.folder_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dlCtrl.downloadDirectory.isNotEmpty
                      ? dlCtrl.downloadDirectory
                      : '/storage/emulated/0/Download/VINX',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textHi,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved files appear in your phone Gallery and media players.',
                  style: TextStyle(fontSize: 11.5, color: textDim),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => dlCtrl.pickDirectory(),
                  icon: const Icon(Icons.drive_file_move_outlined, size: 16),
                  label: const Text('Change Location', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textHi,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            bgPanel: bgPanel,
            borderColor: borderColor,
            textHi: textHi,
            activeColor: activeColor,
          ),

          const SizedBox(height: 14),

          // Speed Throttling Section
          _buildSectionCard(
            context,
            isDark,
            title: 'Download Speed Limiter',
            icon: Icons.speed_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cap bandwidth usage when on cellular or shared networks.',
                  style: TextStyle(fontSize: 11.5, color: textDim),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSpeedChip(SpeedLimit.unlimited, dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
                    _buildSpeedChip(SpeedLimit.mbps15, dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
                    _buildSpeedChip(SpeedLimit.mbps10, dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
                    _buildSpeedChip(SpeedLimit.mbps5, dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
                    _buildSpeedChip(SpeedLimit.mbps2, dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
                  ],
                ),
              ],
            ),
            bgPanel: bgPanel,
            borderColor: borderColor,
            textHi: textHi,
            activeColor: activeColor,
          ),

          const SizedBox(height: 14),

          // Appearance Section
          if (themeModeNotifier != null)
            _buildSectionCard(
              context,
              isDark,
              title: 'Appearance',
              icon: Icons.palette_outlined,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier!,
                builder: (context, currentTheme, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildThemeChoice(
                          'Dark',
                          ThemeMode.dark,
                          Icons.dark_mode_rounded,
                          currentTheme == ThemeMode.dark,
                          () => themeModeNotifier!.value = ThemeMode.dark,
                          isDark,
                          activeColor,
                          bgRaised,
                          borderColor,
                          textHi,
                          textDim,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeChoice(
                          'Light',
                          ThemeMode.light,
                          Icons.light_mode_rounded,
                          currentTheme == ThemeMode.light,
                          () => themeModeNotifier!.value = ThemeMode.light,
                          isDark,
                          activeColor,
                          bgRaised,
                          borderColor,
                          textHi,
                          textDim,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeChoice(
                          'System',
                          ThemeMode.system,
                          Icons.brightness_auto_rounded,
                          currentTheme == ThemeMode.system,
                          () => themeModeNotifier!.value = ThemeMode.system,
                          isDark,
                          activeColor,
                          bgRaised,
                          borderColor,
                          textHi,
                          textDim,
                        ),
                      ),
                    ],
                  );
                },
              ),
              bgPanel: bgPanel,
              borderColor: borderColor,
              textHi: textHi,
              activeColor: activeColor,
            ),

          const SizedBox(height: 14),

          // Standalone Mobile Engine Info Card
          _buildSectionCard(
            context,
            isDark,
            title: 'Engine & Pipeline',
            icon: Icons.memory_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pure Dart Standalone Engine (Active)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textHi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '100% on-device extraction pipeline. Operates without cloud backends, root access, or desktop terminal binaries.',
                  style: TextStyle(fontSize: 11.5, color: textDim, height: 1.35),
                ),
              ],
            ),
            bgPanel: bgPanel,
            borderColor: borderColor,
            textHi: textHi,
            activeColor: activeColor,
          ),

          const SizedBox(height: 20),

          // App Version & Credits
          Center(
            child: Column(
              children: [
                Text(
                  'VINX Mobile v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textDim,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ultra-Fast Native Media Downloader',
                  style: TextStyle(fontSize: 10.5, color: textDim),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required IconData icon,
    required Widget child,
    required Color bgPanel,
    required Color borderColor,
    required Color textHi,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: textHi),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: textHi,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSpeedChip(
    SpeedLimit limit,
    DownloadController dlCtrl,
    bool isDark,
    Color activeColor,
    Color bgRaised,
    Color border,
    Color textHi,
    Color textDim,
  ) {
    final isSelected = dlCtrl.speedLimit == limit;

    return InkWell(
      onTap: () => dlCtrl.setSpeedLimit(limit),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : bgRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : border,
          ),
        ),
        child: Text(
          limit.shortLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : textHi,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeChoice(
    String label,
    ThemeMode mode,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
    Color activeColor,
    Color bgRaised,
    Color border,
    Color textHi,
    Color textDim,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : textDim,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : textHi,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
