import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/download_archive_item.dart';

/// Dedicated mobile media vault and download library screen.
class MobileLibraryTab extends StatefulWidget {
  final DownloadController downloadController;
  final ValueChanged<String> onReDownload;

  const MobileLibraryTab({
    super.key,
    required this.downloadController,
    required this.onReDownload,
  });

  @override
  State<MobileLibraryTab> createState() => _MobileLibraryTabState();
}

class _MobileLibraryTabState extends State<MobileLibraryTab> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.downloadController.archiveSearchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.downloadController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final bgPanel = isDark ? SpideyColors.darkBgPanel : SpideyColors.lightBgPanel;
        final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
        final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
        final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;
        final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
        final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
        final activeColor = isDark ? Colors.white : Colors.black;

        final dlCtrl = widget.downloadController;
        final items = dlCtrl.filteredArchiveItems;
        final totalCount = dlCtrl.archiveItems.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Header & Storage Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Media Vault',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textHi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalCount saved on device',
                    style: TextStyle(fontSize: 11.5, color: textDim),
                  ),
                ],
              ),
              if (totalCount > 0)
                IconButton(
                  icon: Icon(Icons.cleaning_services_outlined, size: 20, color: textDim),
                  tooltip: 'Prune missing files',
                  onPressed: () => dlCtrl.clearMissingArchive(),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: bgPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13.5, color: textHi),
              decoration: InputDecoration(
                hintText: 'Search downloaded media...',
                hintStyle: TextStyle(fontSize: 13, color: textDim),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: textDim),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 16, color: textDim),
                        onPressed: () {
                          _searchController.clear();
                          dlCtrl.setArchiveSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                isDense: true,
              ),
              onChanged: (q) {
                dlCtrl.setArchiveSearchQuery(q);
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 12),

          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(ArchiveFilter.all, 'All', dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
                const SizedBox(width: 8),
                _buildFilterChip(ArchiveFilter.video, 'Videos', dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
                const SizedBox(width: 8),
                _buildFilterChip(ArchiveFilter.audio, 'Audio', dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
                const SizedBox(width: 8),
                _buildFilterChip(ArchiveFilter.playlist, 'Playlists', dlCtrl, isDark, activeColor, bgRaised, borderColor, textHi, textDim),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Items List
          if (items.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildArchiveCard(context, isDark, item, dlCtrl, textHi, textNorm, textDim, borderColor, bgPanel, bgRaised, activeColor);
              },
            )
          else
            _buildEmptyLibraryState(context, isDark, textHi, textDim, bgPanel, bgRaised, borderColor),
          ],
        ),
      );
    },
  );
}

  Widget _buildFilterChip(
    ArchiveFilter filter,
    String label,
    DownloadController dlCtrl,
    bool isDark,
    Color activeColor,
    Color bgRaised,
    Color border,
    Color textHi,
    Color textDim,
  ) {
    final isSelected = dlCtrl.archiveFilter == filter;

    return InkWell(
      onTap: () {
        dlCtrl.setArchiveFilter(filter);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : bgRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : border,
          ),
        ),
        child: Text(
          label,
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

  Widget _buildArchiveCard(
    BuildContext context,
    bool isDark,
    DownloadArchiveItem item,
    DownloadController dlCtrl,
    Color textHi,
    Color textNorm,
    Color textDim,
    Color borderColor,
    Color bgPanel,
    Color bgRaised,
    Color activeColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => dlCtrl.openArchiveFile(item.filePath),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(
                    item.isAudioOnly ? Icons.headphones_rounded : Icons.videocam_rounded,
                    size: 22,
                    color: textHi,
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: textHi,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            item.formatLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textNorm),
                          ),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(fontSize: 11, color: textDim)),
                          const SizedBox(width: 8),
                          Text(
                            item.formattedSize,
                            style: TextStyle(fontSize: 11, color: textDim),
                          ),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(fontSize: 11, color: textDim)),
                          const SizedBox(width: 8),
                          Text(
                            '${item.completedAt.month}/${item.completedAt.day}',
                            style: TextStyle(fontSize: 11, color: textDim),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions Popup
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: textDim),
                  color: bgRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor),
                  ),
                  onSelected: (action) {
                    if (action == 'open') {
                      dlCtrl.openArchiveFile(item.filePath);
                    } else if (action == 'folder') {
                      dlCtrl.openArchiveFolder(item.filePath);
                    } else if (action == 'share') {
                      dlCtrl.shareArchiveFile(item.filePath);
                    } else if (action == 'redownload') {
                      widget.onReDownload(item.url);
                    } else if (action == 'delete') {
                      dlCtrl.deleteArchiveItem(item.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Play / Open'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'folder',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Show in Files'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Share File'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'redownload',
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Re-download'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLibraryState(
    BuildContext context,
    bool isDark,
    Color textHi,
    Color textDim,
    Color bgPanel,
    Color bgRaised,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgRaised,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.folder_special_outlined, size: 28, color: textDim),
          ),
          const SizedBox(height: 14),
          Text(
            'Media Vault is Empty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textHi,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Downloaded videos and audio tracks will be indexed here so you can access or play them anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textDim, height: 1.4),
          ),
        ],
      ),
    );
  }
}
