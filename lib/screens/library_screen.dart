import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../utils/file_utils.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/liquid_text_field.dart';
import '../widgets/theme_toggle_button.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0; // 0: All, 1: Videos, 2: Audio

  @override
  void initState() {
    super.initState();
    StorageService.instance.refresh();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MediaStorageItem> _getFilteredItems(List<MediaStorageItem> all) {
    List<MediaStorageItem> filtered = all;
    if (_selectedFilterIndex == 1) {
      filtered = filtered.where((i) => i.isVideo).toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = filtered.where((i) => i.isAudio).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((i) => i.name.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final theme = SettingsService.instance;
        final isDark = theme.isDarkTheme;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Media Storage',
                            style: TextStyle(
                              color: theme.primaryTextColor,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ListenableBuilder(
                            listenable: StorageService.instance,
                            builder: (context, _) {
                              final count = StorageService.instance.items.length;
                              final totalSize = FileUtils.formatBytes(
                                  StorageService.instance.totalSizeBytes);
                              return Text(
                                '$count Files • $totalSize Total',
                                style: TextStyle(
                                  color: theme.secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const ThemeToggleButton(),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded, color: theme.secondaryTextColor),
                            onPressed: () => StorageService.instance.refresh(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: LiquidTextField(
                    controller: _searchController,
                    hintText: 'Search offline files...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.secondaryTextColor,
                      size: 20,
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),

                // Filter Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('All Media', 0, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Videos Only', 1, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('MP3 Audio', 2, isDark),
                    ],
                  ),
                ),

                // Files List
                Expanded(
                  child: ListenableBuilder(
                    listenable: StorageService.instance,
                    builder: (context, _) {
                      if (StorageService.instance.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0A84FF),
                          ),
                        );
                      }

                      final filtered = _getFilteredItems(StorageService.instance.items);

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 54,
                                color: theme.subtleTextColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No downloaded media found',
                                style: TextStyle(
                                  color: theme.primaryTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Completed downloads will appear here',
                                style: TextStyle(
                                  color: theme.secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 90),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildStorageItemCard(item, theme, isDark);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0A84FF).withValues(alpha: isDark ? 0.22 : 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0A84FF))
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStorageItemCard(MediaStorageItem item, SettingsService theme, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');
    final formattedDate = dateFormat.format(item.modifiedAt);

    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      onTap: () => StorageService.instance.openItem(item),
      child: Row(
        children: [
          // Media Thumbnail Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.isAudio
                  ? const Color(0xFF9333EA).withValues(alpha: isDark ? 0.18 : 0.12)
                  : const Color(0xFF0A84FF).withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.isAudio
                    ? const Color(0xFFC084FC).withValues(alpha: 0.3)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Icon(
              item.isAudio ? Icons.music_note_rounded : Icons.videocam_rounded,
              color: item.isAudio ? const Color(0xFFC084FC) : const Color(0xFF38BDF8),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      FileUtils.formatBytes(item.sizeBytes),
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' • $formattedDate',
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Menu
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: theme.secondaryTextColor, size: 20),
            onPressed: () => StorageService.instance.shareItem(item),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: theme.secondaryTextColor, size: 20),
            onPressed: () => _confirmDelete(item, theme),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MediaStorageItem item, SettingsService theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.cardBorderColor,
            width: 0.8,
          ),
        ),
        title: Text('Delete File', style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${item.name}" from your phone storage?',
          style: TextStyle(color: theme.secondaryTextColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.secondaryTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              StorageService.instance.deleteItem(item);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
