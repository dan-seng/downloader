import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/audio_config.dart';
import '../../../models/quality_option.dart';

/// Modal bottom sheet for choosing download quality and formats on mobile.
/// Implemented as a StatefulWidget for instantaneous, stutter-free local responsiveness.
class MobileFormatBottomSheet extends StatefulWidget {
  final List<QualityOption> availableQualities;
  final QualityOption? selectedQuality;
  final AudioConfig audioConfig;
  final bool isAudioMode;
  final ValueChanged<QualityOption> onQualitySelected;
  final ValueChanged<AudioConfig> onAudioConfigSelected;
  final ValueChanged<bool> onModeChanged;

  const MobileFormatBottomSheet({
    super.key,
    required this.availableQualities,
    required this.selectedQuality,
    required this.audioConfig,
    required this.isAudioMode,
    required this.onQualitySelected,
    required this.onAudioConfigSelected,
    required this.onModeChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required List<QualityOption> availableQualities,
    required QualityOption? selectedQuality,
    required AudioConfig audioConfig,
    required bool isAudioMode,
    required ValueChanged<QualityOption> onQualitySelected,
    required ValueChanged<AudioConfig> onAudioConfigSelected,
    required ValueChanged<bool> onModeChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MobileFormatBottomSheet(
        availableQualities: availableQualities,
        selectedQuality: selectedQuality,
        audioConfig: audioConfig,
        isAudioMode: isAudioMode,
        onQualitySelected: onQualitySelected,
        onAudioConfigSelected: onAudioConfigSelected,
        onModeChanged: onModeChanged,
      ),
    );
  }

  @override
  State<MobileFormatBottomSheet> createState() => _MobileFormatBottomSheetState();
}

class _MobileFormatBottomSheetState extends State<MobileFormatBottomSheet> {
  late bool _isAudioMode;
  late QualityOption? _selectedQuality;
  late AudioConfig _audioConfig;

  @override
  void initState() {
    super.initState();
    _isAudioMode = widget.isAudioMode;
    _selectedQuality = widget.selectedQuality;
    _audioConfig = widget.audioConfig;
  }

  void _switchMode(bool isAudio) {
    if (_isAudioMode != isAudio) {
      setState(() {
        _isAudioMode = isAudio;
      });
      widget.onModeChanged(isAudio);
    }
  }

  void _selectQuality(QualityOption quality) {
    setState(() {
      _selectedQuality = quality;
    });
    widget.onQualitySelected(quality);
  }

  void _selectAudioConfig(AudioConfig config) {
    setState(() {
      _audioConfig = config;
    });
    widget.onAudioConfigSelected(config);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgPanel = isDark ? SpideyColors.darkBgPanel : SpideyColors.lightBgPanel;
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final activeColor = isDark ? Colors.white : Colors.black;

    final videoQualities = widget.availableQualities.where((q) => !q.isAudioOnly).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bgPanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Quality & Format',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: textHi,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textDim),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Video vs Audio Segmented Switch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _switchMode(false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isAudioMode ? activeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                size: 17,
                                color: !_isAudioMode
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textDim,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Video (MP4)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !_isAudioMode
                                      ? (isDark ? Colors.black : Colors.white)
                                      : textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _switchMode(true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isAudioMode ? activeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.headphones_rounded,
                                size: 17,
                                color: _isAudioMode
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textDim,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Audio (MP3)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isAudioMode
                                      ? (isDark ? Colors.black : Colors.white)
                                      : textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Options List
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _isAudioMode
                    ? _buildAudioOptions(context, isDark, textHi, textNorm, textDim, borderColor, bgRaised)
                    : _buildVideoOptions(context, isDark, videoQualities, textHi, textNorm, textDim, borderColor, bgRaised),
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Confirm Selection',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoOptions(
    BuildContext context,
    bool isDark,
    List<QualityOption> qualities,
    Color textHi,
    Color textNorm,
    Color textDim,
    Color borderColor,
    Color bgRaised,
  ) {
    if (qualities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No video formats available for this media.',
            style: TextStyle(color: textDim, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: qualities.map((q) {
        final isSelected = _selectedQuality?.id == q.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _selectQuality(q),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                    : bgRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : borderColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : textDim,
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: textHi,
                          ),
                        ),
                        if (q.height != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${q.height}p · ${q.extension.toUpperCase()} container',
                              style: TextStyle(fontSize: 11.5, color: textDim),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (q.formattedSize.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        q.formattedSize,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textNorm,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAudioOptions(
    BuildContext context,
    bool isDark,
    Color textHi,
    Color textNorm,
    Color textDim,
    Color borderColor,
    Color bgRaised,
  ) {
    final formats = [
      (AudioFormat.mp3, AudioBitrate.kbps320, 'MP3 · 320 kbps', 'Studio High Quality (Recommended)'),
      (AudioFormat.mp3, AudioBitrate.kbps256, 'MP3 · 256 kbps', 'High Quality / Balanced'),
      (AudioFormat.mp3, AudioBitrate.kbps192, 'MP3 · 192 kbps', 'Standard / Podcasts'),
      (AudioFormat.m4a, AudioBitrate.kbps256, 'M4A · AAC', 'Apple & Mobile Native Audio'),
      (AudioFormat.flac, AudioBitrate.vbr, 'FLAC · Lossless', 'Audiophile Uncompressed Audio'),
    ];

    return Column(
      children: formats.map((item) {
        final format = item.$1;
        final bitrate = item.$2;
        final title = item.$3;
        final subtitle = item.$4;

        final isSelected = _audioConfig.format == format && _audioConfig.bitrate == bitrate;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              _selectAudioConfig(_audioConfig.copyWith(
                format: format,
                bitrate: bitrate,
              ));
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                    : bgRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : borderColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : textDim,
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: textHi,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: TextStyle(fontSize: 11.5, color: textDim),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      format.id.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textNorm,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
