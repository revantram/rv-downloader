import 'package:flutter/material.dart';
import '../models/download_task.dart';
import '../services/native_downloader_service.dart';
import '../utils/file_utils.dart';
import 'liquid_glass_card.dart';

class DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onDeleted;

  const DownloadTaskCard({
    super.key,
    required this.task,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Icon / Thumbnail
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: task.isAudioOnly
                      ? const Color(0xFF9333EA).withValues(alpha: 0.18)
                      : const Color(0xFF0A84FF).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: task.isAudioOnly
                        ? const Color(0xFFC084FC).withValues(alpha: 0.3)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  task.isAudioOnly
                      ? Icons.music_note_rounded
                      : Icons.play_arrow_rounded,
                  color: task.isAudioOnly
                      ? const Color(0xFFC084FC)
                      : const Color(0xFF38BDF8),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Quality badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            task.isAudioOnly
                                ? 'MP3 • ${task.audioBitrate}'
                                : task.quality.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons (Cancel / Open / Delete)
              if (task.isActive)
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.redAccent, size: 20),
                  onPressed: () =>
                      NativeDownloaderService.instance.cancelDownload(task.id),
                )
              else if (task.isDone)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.ios_share_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => NativeDownloaderService.instance
                          .shareFile(task.filePath),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded,
                          color: Color(0xFF38BDF8), size: 28),
                      onPressed: () => NativeDownloaderService.instance
                          .openFile(task.filePath),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.4), size: 20),
                  onPressed: () => NativeDownloaderService.instance
                      .deleteTask(task.id, deleteFromDisk: false),
                ),
            ],
          ),

          // Progress bar & info for active downloads
          if (task.isActive) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: task.status == DownloadStatus.starting
                    ? null
                    : (task.progress / 100.0).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.isAudioOnly
                      ? const Color(0xFFA855F7)
                      : const Color(0xFF0A84FF),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${task.progress.toStringAsFixed(1)}%${task.speed.isNotEmpty ? " • ${task.speed}" : ""}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  task.etaSeconds > 0
                      ? 'ETA: ${FileUtils.formatEta(task.etaSeconds)}'
                      : 'Connecting...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // Error line
          if (task.hasFailed && task.error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.error,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF87171),
                fontSize: 11,
              ),
            ),
          ],

          // File size on completion
          if (task.isDone && task.fileSizeBytes > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Size: ${FileUtils.formatBytes(task.fileSizeBytes)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (task.status) {
      case DownloadStatus.idle:
        return 'Ready';
      case DownloadStatus.queued:
        return 'Queued...';
      case DownloadStatus.starting:
        return 'Starting Engine...';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor() {
    switch (task.status) {
      case DownloadStatus.idle:
      case DownloadStatus.queued:
      case DownloadStatus.starting:
        return const Color(0xFFFBBF24);
      case DownloadStatus.downloading:
        return const Color(0xFF38BDF8);
      case DownloadStatus.completed:
        return const Color(0xFF34D399);
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return const Color(0xFFF87171);
    }
  }
}
