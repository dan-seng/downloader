import 'package:flutter/material.dart';
import '../../../controllers/download_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/download_archive_item.dart';

/// Callback when user selects to re-download an archive item.
typedef ReDownloadCallback = void Function(String url);

/// Cyber-industrial download library and archive deck.
class ArchiveDeck extends StatelessWidget {
  final DownloadController downloadController;
  final bool isDark;
  final ReDownloadCallback onReDownload;

  const ArchiveDeck({
    super.key,
    required this.downloadController,
    required this.isDark,
    required this.onReDownload,
  });

  @override
  Widget build(BuildContext context) {
    final bgRaised = isDark ? SpideyColors.darkBgRaised : SpideyColors.lightBgRaised;
    final bgWell = isDark ? SpideyColors.darkBgPanel : SpideyColors.lightBgPanel;
    final borderColor = isDark ? SpideyColors.darkBorder : SpideyColors.lightBorder;
    final borderLit = isDark ? SpideyColors.darkBorderLit : SpideyColors.lightBorderLit;
    final textDim = isDark ? SpideyColors.darkTextDim : SpideyColors.lightTextDim;
    final textNorm = isDark ? SpideyColors.darkText : SpideyColors.lightText;
    final textHi = isDark ? SpideyColors.darkTextHi : SpideyColors.lightTextHi;

    final items = downloadController.filteredArchiveItems;
    final totalCount = downloadController.archiveItems.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Deck Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderLit),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20, color: textHi),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOWNLOAD ARCHIVE // MEDIA VAULT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textHi,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalCount PERSISTENT RECORDS ON DISK',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.6,
                            color: textDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Prune Missing Files Button
                    InkWell(
                      onTap: () => downloadController.clearMissingArchive(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgWell,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cleaning_services_outlined, size: 13, color: textDim),
                            const SizedBox(width: 6),
                            Text(
                              'PRUNE MISSING',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: textNorm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Open Downloads Directory
                    InkWell(
                      onTap: () => downloadController.openArchiveFolder(''),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgWell,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.folder_open_outlined, size: 13, color: textHi),
                            const SizedBox(width: 6),
                            Text(
                              'OPEN FOLDER',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: textHi,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search & Filter Toolbar Strip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgWell,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: bgRaised,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          onChanged: downloadController.setArchiveSearchQuery,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textHi,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search archive by title, file name, or URL...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: textDim,
                            ),
                            prefixIcon: Icon(Icons.search, size: 16, color: textDim),
                            suffixIcon: downloadController.archiveSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 14, color: textDim),
                                    onPressed: () =>
                                        downloadController.setArchiveSearchQuery(''),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Sort Dropdown
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: bgRaised,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ArchiveSort>(
                          value: downloadController.archiveSort,
                          dropdownColor: bgRaised,
                          isDense: true,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: textHi,
                          ),
                          items: ArchiveSort.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            );
                          }).toList(),
                          onChanged: (s) {
                            if (s != null) downloadController.setArchiveSort(s);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Filter Chips Strip
                Row(
                  children: [
                    Text(
                      'FILTER: ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: textDim,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...ArchiveFilter.values.map((filter) {
                      final isActive = downloadController.archiveFilter == filter;
                      int count = 0;
                      switch (filter) {
                        case ArchiveFilter.all:
                          count = downloadController.archiveItems.length;
                          break;
                        case ArchiveFilter.video:
                          count = downloadController.archiveItems
                              .where((it) => !it.isAudioOnly)
                              .length;
                          break;
                        case ArchiveFilter.audio:
                          count = downloadController.archiveItems
                              .where((it) => it.isAudioOnly)
                              .length;
                          break;
                        case ArchiveFilter.playlist:
                          count = downloadController.archiveItems
                              .where((it) => it.playlistTitle != null && it.playlistTitle!.isNotEmpty)
                              .length;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => downloadController.setArchiveFilter(filter),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isDark ? Colors.white : Colors.black)
                                  : bgRaised,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive
                                    ? (isDark ? Colors.white : Colors.black)
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              '${filter.id} ($count)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textDim,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items List
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: bgWell,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: textDim.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'NO ARCHIVED DOWNLOADS FOUND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: textDim,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    downloadController.archiveSearchQuery.isNotEmpty
                        ? 'Try clearing the search query or changing filters.'
                        : 'Downloaded media will automatically appear in this vault.',
                    style: TextStyle(
                      fontSize: 11,
                      color: textDim,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildArchiveCard(
                  context,
                  item,
                  isDark,
                  bgWell,
                  bgRaised,
                  borderColor,
                  borderLit,
                  textHi,
                  textNorm,
                  textDim,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(
    BuildContext context,
    DownloadArchiveItem item,
    bool isDark,
    Color bgWell,
    Color bgRaised,
    Color borderColor,
    Color borderLit,
    Color textHi,
    Color textNorm,
    Color textDim,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgWell,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Row: Badges & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Format Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: bgRaised,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderLit),
                    ),
                    child: Text(
                      item.formatLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: textHi,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // File Size Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: bgRaised,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      item.formattedSize,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: textNorm,
                      ),
                    ),
                  ),
                  if (item.playlistTitle != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgRaised,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        'PLAYLIST: ${item.playlistTitle!}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: textDim,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Disk Status & Date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.fileExists ? bgRaised : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: item.fileExists ? borderLit : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.fileExists ? textHi : textDim,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.fileExists ? 'ON DISK' : 'MOVED / DELETED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: item.fileExists ? textHi : textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.formattedDate,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: textDim,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Path
          Text(
            item.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textHi,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.filePath.isNotEmpty ? item.filePath : item.url,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: textDim,
            ),
          ),
          const SizedBox(height: 12),

          // Action Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Open File
                  if (item.fileExists) ...[
                    _buildActionButton(
                      icon: Icons.play_arrow_outlined,
                      label: 'OPEN FILE',
                      onTap: () => downloadController.openArchiveFile(item.filePath),
                      isDark: isDark,
                      bgRaised: bgRaised,
                      borderColor: borderLit,
                      textColor: textHi,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Open Folder
                  _buildActionButton(
                    icon: Icons.folder_open_outlined,
                    label: 'FOLDER',
                    onTap: () => downloadController.openArchiveFolder(item.filePath),
                    isDark: isDark,
                    bgRaised: bgRaised,
                    borderColor: borderColor,
                    textColor: textNorm,
                  ),
                  const SizedBox(width: 8),

                  // Re-Download Button
                  _buildActionButton(
                    icon: Icons.refresh_outlined,
                    label: 'RE-DOWNLOAD',
                    onTap: () => onReDownload(item.url),
                    isDark: isDark,
                    bgRaised: bgRaised,
                    borderColor: borderColor,
                    textColor: textNorm,
                  ),
                ],
              ),

              // Delete Menu
              PopupMenuButton<String>(
                tooltip: 'Delete Options',
                onSelected: (action) {
                  if (action == 'archive_only') {
                    downloadController.deleteArchiveItem(item.id, deleteFileFromDisk: false);
                  } else if (action == 'delete_disk') {
                    downloadController.deleteArchiveItem(item.id, deleteFileFromDisk: true);
                  }
                },
                color: bgRaised,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'archive_only',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, size: 14, color: textDim),
                        const SizedBox(width: 8),
                        Text(
                          'Remove from Archive Only',
                          style: TextStyle(fontSize: 11.5, color: textHi),
                        ),
                      ],
                    ),
                  ),
                  if (item.fileExists)
                    PopupMenuItem(
                      value: 'delete_disk',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever_outlined, size: 14, color: textHi),
                          const SizedBox(width: 8),
                          Text(
                            'Delete File from Disk',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: textHi,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: bgRaised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 13, color: textDim),
                      const SizedBox(width: 4),
                      Text(
                        'DELETE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textDim,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, size: 13, color: textDim),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color bgRaised,
    required Color borderColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: bgRaised,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
