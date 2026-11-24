import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/media_info.dart';
import '../services/settings_service.dart';
import '../utils/file_utils.dart';
import 'liquid_button.dart';
import 'liquid_glass_card.dart';

class FormatSelectorSheet extends StatefulWidget {
  final MediaInfo info;
  final Function({
    required String quality,
    required bool isAudioOnly,
    required String audioBitrate,
    String? customTitle,
  }) onDownload;

  const FormatSelectorSheet({
    super.key,
    required this.info,
    required this.onDownload,
  });

  @override
  State<FormatSelectorSheet> createState() => _FormatSelectorSheetState();
}

class _FormatSelectorSheetState extends State<FormatSelectorSheet> {
  late String _selectedQuality;
  late bool _isAudioOnly;
  late String _selectedBitrate;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _selectedQuality = SettingsService.instance.defaultQuality;
    _isAudioOnly = false;
    _selectedBitrate = SettingsService.instance.defaultBitrate;
    _titleController = TextEditingController(text: widget.info.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F131D).withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: pad.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Media Preview Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.info.thumbnail.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.info.thumbnail,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildThumbPlaceholder(),
                        ),
                      )
                    else
                      _buildThumbPlaceholder(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.info.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (widget.info.uploader.isNotEmpty)
                            Text(
                              widget.info.uploader,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          if (widget.info.duration.inSeconds > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Duration: ${FileUtils.formatDuration(widget.info.duration)}',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rename field
                Text(
                  'SAVE AS (FILE NAME)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Format Type Selector (Video vs Audio Only MP3)
                Text(
                  'CHOOSE FORMAT & QUALITY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTypeToggle(
                        title: 'Video',
                        icon: Icons.videocam_rounded,
                        isSelected: !_isAudioOnly,
                        onTap: () => setState(() => _isAudioOnly = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeToggle(
                        title: 'Audio (MP3)',
                        icon: Icons.music_note_rounded,
                        isSelected: _isAudioOnly,
                        onTap: () => setState(() => _isAudioOnly = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!_isAudioOnly) ...[
                  // Video Qualities
                  _buildQualityOption(
                    title: 'Full HD / Best (1080p)',
                    subtitle: 'Highest available resolution & audio merge',
                    badge: 'RECOMMENDED',
                    value: '1080p',
                    selected: _selectedQuality == '1080p',
                  ),
                  const SizedBox(height: 8),
                  _buildQualityOption(
                    title: 'High Quality (720p)',
                    subtitle: 'Crisp picture with faster download speed',
                    value: '720p',
                    selected: _selectedQuality == '720p',
                  ),
                  const SizedBox(height: 8),
                  _buildQualityOption(
                    title: 'Data Saver (360p / 480p)',
                    subtitle: 'Minimal file size for quick previews',
                    value: '360p',
                    selected: _selectedQuality == '360p',
                  ),
                ] else ...[
                  // Audio Bitrate Selection
                  Text(
                    'MP3 BITRATE (FFMPEG ENCODED)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBitratePill('320k', '320 kbps (HQ)'),
                      const SizedBox(width: 8),
                      _buildBitratePill('256k', '256 kbps'),
                      const SizedBox(width: 8),
                      _buildBitratePill('128k', '128 kbps'),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Download Button
                LiquidButton(
                  gradient: LinearGradient(
                    colors: _isAudioOnly
                        ? [const Color(0xFF9333EA), const Color(0xFF7E22CE)]
                        : [const Color(0xFF0A84FF), const Color(0xFF0066CC)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDownload(
                      quality: _selectedQuality,
                      isAudioOnly: _isAudioOnly,
                      audioBitrate: _selectedBitrate,
                      customTitle: _titleController.text.trim(),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isAudioOnly
                            ? Icons.download_rounded
                            : Icons.file_download_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isAudioOnly
                            ? 'Download MP3 Audio'
                            : 'Download Video ($_selectedQuality)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbPlaceholder() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: const Icon(Icons.movie_creation_rounded, color: Colors.white54, size: 36),
    );
  }

  Widget _buildTypeToggle({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (title.contains('Audio')
                  ? const Color(0xFF9333EA).withValues(alpha: 0.25)
                  : const Color(0xFF0A84FF).withValues(alpha: 0.25))
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (title.contains('Audio')
                    ? const Color(0xFFC084FC)
                    : const Color(0xFF38BDF8))
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption({
    required String title,
    required String subtitle,
    required String value,
    required bool selected,
    String? badge,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedQuality = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0A84FF).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF38BDF8)
                : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? const Color(0xFF38BDF8) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBitratePill(String bitrate, String label) {
    final selected = _selectedBitrate == bitrate;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBitrate = bitrate),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF9333EA).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFFC084FC)
                  : Colors.white.withValues(alpha: 0.1),
              width: selected ? 1.2 : 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
