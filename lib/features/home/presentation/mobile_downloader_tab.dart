import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controllers/download_controller.dart';
import '../../../controllers/video_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/quality_option.dart';
import 'mobile_format_bottom_sheet.dart';

extension _IterableFirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// Main downloader tab on mobile with URL input, paste action, video card, and download CTA.
class MobileDownloaderTab extends StatefulWidget {
  final VideoController videoController;
  final DownloadController downloadController;
  final VoidCallback onNavigateToDownloads;

  const MobileDownloaderTab({
    super.key,
    required this.videoController,
    required this.downloadController,
    required this.onNavigateToDownloads,
  });

  @override
  State<MobileDownloaderTab> createState() => _MobileDownloaderTabState();
}

class _MobileDownloaderTabState extends State<MobileDownloaderTab> {
  late final TextEditingController _urlController;
  final FocusNode _urlFocusNode = FocusNode();
  String? _previousVideoQualityId;

  bool get _isAudioMode =>
      widget.downloadController.selectedQuality?.isAudioOnly == true;

  void _selectMode(bool isAudio) {
    final controller = widget.downloadController;
    final current = controller.selectedQuality;
    if (current?.isAudioOnly == isAudio) return;

    final qualities = controller.availableQualities
        .where((quality) => quality.isAudioOnly == isAudio)
        .toList();

    if (isAudio) {
      _previousVideoQualityId = current?.id;
      final audioQuality = qualities.isNotEmpty
          ? qualities.first
          : QualityOption(
              id: 'audio_${controller.audioConfig.format.id}',
              label: 'Audio Only (${controller.audioConfig.format.id.toUpperCase()})',
              extension: controller.audioConfig.format.id,
              isAudioOnly: true,
              formatSpecifier: 'ba/b',
            );
      controller.selectQuality(audioQuality);
    } else {
      if (qualities.isEmpty) return;
      final quality = qualities.firstWhere(
        (quality) => quality.id == _previousVideoQualityId,
        orElse: () => qualities.first,
      );
      controller.selectQuality(quality);
    }
  }

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _urlFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _urlController.text = text;
      _analyze();
    }
  }

  void _analyze() {
    final url = _urlController.text.trim();
    if (url.isEmpty || widget.videoController.isLoading) return;
    FocusScope.of(context).unfocus();
    widget.videoController.analyzeUrl(url).then((_) {
      if (widget.videoController.currentVideo != null) {
        widget.downloadController.setVideo(widget.videoController.currentVideo);
      }
    });
  }

  Future<void> _startDownload() async {
    final video = widget.videoController.currentVideo;
    if (video == null) return;

    if (io.Platform.isAndroid) {
      final hasPerm = await widget.downloadController.checkStoragePermission();
      if (!hasPerm) {
        await widget.downloadController.requestStoragePermission();
      }
    }

    final dlCtrl = widget.downloadController;
    if (_isAudioMode) {
      if (dlCtrl.selectedQuality == null || !dlCtrl.selectedQuality!.isAudioOnly) {
        final audioQuality = dlCtrl.availableQualities.firstWhereOrNull((q) => q.isAudioOnly) ??
            QualityOption(
              id: 'audio_${dlCtrl.audioConfig.format.id}',
              label: 'Audio Only (${dlCtrl.audioConfig.format.id.toUpperCase()})',
              extension: dlCtrl.audioConfig.format.id,
              isAudioOnly: true,
              formatSpecifier: 'ba/b',
            );
        dlCtrl.selectQuality(audioQuality);
      }
    } else {
      if (dlCtrl.selectedQuality == null && dlCtrl.availableQualities.isNotEmpty) {
        dlCtrl.selectQuality(dlCtrl.availableQualities.first);
      }
    }

    dlCtrl.startDownload(video);
    widget.onNavigateToDownloads();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.videoController,
        widget.downloadController,
      ]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final bgPanel = isDark ? SpideyColors.darkBgPanel : SpideyColors.lightBgPanel;
        final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
        final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
        final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
        final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
        final activeColor = isDark ? Colors.white : Colors.black;

        final videoCtrl = widget.videoController;
        final dlCtrl = widget.downloadController;
        final currentVideo = videoCtrl.currentVideo;
        final isPlaylist = videoCtrl.isPlaylist && videoCtrl.currentPlaylist != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Storage Permission Warning Banner (if not granted)
              FutureBuilder<bool>(
                future: dlCtrl.checkStoragePermission(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == false && io.Platform.isAndroid) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Storage access needed to save to Downloads/VINX',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textHi),
                            ),
                          ),
                          TextButton(
                            onPressed: () => dlCtrl.requestStoragePermission(),
                            child: const Text('GRANT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          // Search & Paste Input Card
          Container(
            decoration: BoxDecoration(
              color: bgPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    style: TextStyle(fontSize: 14, color: textHi),
                    decoration: InputDecoration(
                      hintText: 'Paste video link or playlist...',
                      hintStyle: TextStyle(fontSize: 13.5, color: textDim),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                      prefixIcon: Icon(Icons.link_rounded, color: textDim, size: 20),
                      suffixIcon: _urlController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: textDim, size: 18),
                              onPressed: () {
                                setState(() {
                                  _urlController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _analyze(),
                  ),
                ),
                if (_urlController.text.isEmpty)
                  InkWell(
                    onTap: _pasteFromClipboard,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bgRaised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.content_paste_rounded, size: 15, color: textHi),
                          const SizedBox(width: 5),
                          Text(
                            'Paste',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: textHi,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: videoCtrl.isLoading ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: videoCtrl.isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Fetch',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
              ],
            ),
          ),

          // Error Notification Card
          if (videoCtrl.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      videoCtrl.errorMessage!,
                      style: const TextStyle(fontSize: 12.5, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Main Video / Media Card (when loaded)
          if (currentVideo != null && !isPlaylist) ...[
            Container(
              decoration: BoxDecoration(
                color: bgPanel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 16:9 Thumbnail with Duration Badge
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (currentVideo.thumbnail != null && currentVideo.thumbnail!.isNotEmpty)
                            Image.network(
                              currentVideo.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: bgRaised,
                                child: Icon(Icons.videocam_rounded, size: 48, color: textDim),
                              ),
                            )
                          else
                            Container(
                              color: bgRaised,
                              child: Icon(Icons.videocam_rounded, size: 48, color: textDim),
                            ),
                          if (currentVideo.formattedDuration.isNotEmpty)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currentVideo.formattedDuration,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Title & Metadata
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentVideo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textHi,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_rounded, size: 14, color: textDim),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                currentVideo.uploader ?? 'Unknown Channel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: textDim),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Quality & Format Picker Selector Card
                        InkWell(
                          onTap: () async {
                            _dismissKeyboard();
                            await MobileFormatBottomSheet.show(
                              context: context,
                              availableQualities: dlCtrl.availableQualities,
                              selectedQuality: dlCtrl.selectedQuality,
                              audioConfig: dlCtrl.audioConfig,
                              isAudioMode: _isAudioMode,
                              onQualitySelected: dlCtrl.selectQuality,
                              onAudioConfigSelected: (cfg) {
                                _selectMode(true);
                                dlCtrl.updateAudioConfig(cfg);
                              },
                              onModeChanged: _selectMode,
                            );
                            if (mounted) _dismissKeyboard();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgRaised,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: activeColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isAudioMode
                                        ? Icons.headphones_rounded
                                        : Icons.high_quality_rounded,
                                    size: 20,
                                    color: textHi,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isAudioMode ? 'Format: Audio' : 'Format: Video',
                                        style: TextStyle(fontSize: 11, color: textDim),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isAudioMode
                                            ? '${dlCtrl.audioConfig.format.id.toUpperCase()} · ${dlCtrl.audioConfig.bitrate.id.toUpperCase()}'
                                            : (dlCtrl.selectedQuality?.label ?? 'Best Available'),
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: textHi,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: bgPanel,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Change',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: textHi,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textDim),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Prominent Download CTA Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startDownload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeColor,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download_rounded, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _isAudioMode
                                        ? 'Download Audio (${dlCtrl.audioConfig.format.id.toUpperCase()})'
                                        : 'Download Video (${dlCtrl.selectedQuality?.height != null ? "${dlCtrl.selectedQuality!.height}p" : "MP4"})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isPlaylist) ...[
            // Playlist Batch Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgPanel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.playlist_play_rounded, size: 28, color: textHi),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              videoCtrl.currentPlaylist!.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textHi,
                              ),
                            ),
                            Text(
                              '${videoCtrl.currentPlaylist!.totalCount} tracks · ${videoCtrl.currentPlaylist!.uploader ?? ""}',
                              style: TextStyle(fontSize: 12, color: textDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      dlCtrl.startBatchDownload(
                        videoCtrl.currentPlaylist!,
                        quality: dlCtrl.selectedQuality,
                      );
                      widget.onNavigateToDownloads();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Download Selected Tracks (${videoCtrl.currentPlaylist!.selectedCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Clean Placeholder / Supported Formats Section
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: bgRaised,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      size: 36,
                      color: textDim,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ready to Download',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textHi,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paste any YouTube, YouTube Music, or Shorts link\nabove to fetch high-res video and audio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textDim,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Platform Pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPlatformChip('YouTube 4K', Icons.video_library_outlined, textDim, bgRaised, borderColor),
                      _buildPlatformChip('YouTube Music', Icons.music_note_outlined, textDim, bgRaised, borderColor),
                      _buildPlatformChip('Playlists', Icons.queue_music_outlined, textDim, bgRaised, borderColor),
                      _buildPlatformChip('Shorts', Icons.bolt_outlined, textDim, bgRaised, borderColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  },
);
  }

  Widget _buildPlatformChip(String label, IconData icon, Color textDim, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textDim),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textDim),
          ),
        ],
      ),
    );
  }
}
