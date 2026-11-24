import 'dart:io';
import 'package:flutter/foundation.dart';
import 'native_downloader_service.dart';
import 'settings_service.dart';

class MediaStorageItem {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
  final bool isVideo;
  final bool isAudio;

  const MediaStorageItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.isVideo,
    required this.isAudio,
  });
}

class StorageService extends ChangeNotifier {
  static final StorageService instance = StorageService._();
  StorageService._();

  List<MediaStorageItem> _items = [];
  bool _isLoading = false;

  List<MediaStorageItem> get items => List.unmodifiable(_items);
  List<MediaStorageItem> get videoItems =>
      _items.where((i) => i.isVideo).toList();
  List<MediaStorageItem> get audioItems =>
      _items.where((i) => i.isAudio).toList();
  bool get isLoading => _isLoading;

  int get totalSizeBytes => _items.fold<int>(0, (sum, i) => sum + i.sizeBytes);

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dir = Directory(SettingsService.instance.downloadPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final entities = dir.listSync();
      final List<MediaStorageItem> list = [];

      for (final e in entities) {
        if (e is File) {
          final lower = e.path.toLowerCase();
          final isVid = lower.endsWith('.mp4') ||
              lower.endsWith('.mkv') ||
              lower.endsWith('.webm') ||
              lower.endsWith('.mov') ||
              lower.endsWith('.avi');
          final isAud = lower.endsWith('.mp3') ||
              lower.endsWith('.m4a') ||
              lower.endsWith('.aac') ||
              lower.endsWith('.flac') ||
              lower.endsWith('.opus') ||
              lower.endsWith('.wav');

          if (isVid || isAud) {
            final stat = e.statSync();
            final name = e.uri.pathSegments.lastWhere(
              (seg) => seg.isNotEmpty,
              orElse: () => 'Media',
            );

            list.add(MediaStorageItem(
              path: e.path,
              name: name,
              sizeBytes: stat.size,
              modifiedAt: stat.modified,
              isVideo: isVid,
              isAudio: isAud,
            ));
          }
        }
      }

      // Sort newest first
      list.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      _items = list;
    } catch (e) {
      debugPrint('Storage scan error: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(MediaStorageItem item) async {
    try {
      final f = File(item.path);
      if (f.existsSync()) {
        f.deleteSync();
      }
      _items.removeWhere((i) => i.path == item.path);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to delete file: $e');
      return false;
    }
  }

  Future<void> openItem(MediaStorageItem item) async {
    await NativeDownloaderService.instance.openFile(item.path);
  }

  Future<void> shareItem(MediaStorageItem item) async {
    await NativeDownloaderService.instance.shareFile(item.path);
  }
}
