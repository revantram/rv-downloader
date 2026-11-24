import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/download_task.dart';
import '../models/media_info.dart';
import 'settings_service.dart';

class NativeDownloaderService extends ChangeNotifier {
  static final NativeDownloaderService instance = NativeDownloaderService._();
  NativeDownloaderService._();

  static const MethodChannel _methodChannel =
      MethodChannel('com.rvbhati.rvdownloader/engine');
  static const EventChannel _eventChannel =
      EventChannel('com.rvbhati.rvdownloader/progress_events');

  final List<DownloadTask> _tasks = [];
  StreamSubscription? _eventSubscription;
  bool _isInitialized = false;
  String _engineVersion = 'Initializing...';
  bool _isUpdatingEngine = false;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  List<DownloadTask> get activeTasks =>
      _tasks.where((t) => t.isActive).toList();
  List<DownloadTask> get completedTasks =>
      _tasks.where((t) => t.isDone).toList();

  bool get isInitialized => _isInitialized;
  String get engineVersion => _engineVersion;
  bool get isUpdatingEngine => _isUpdatingEngine;

  Future<void> init() async {
    await _loadHistoryFromDisk();
    _listenToEvents();

    try {
      final res = await _methodChannel.invokeMethod('initEngine');
      if (res is Map) {
        _isInitialized = true;
        _engineVersion = res['version']?.toString() ?? 'yt-dlp Core';
        SettingsService.instance.setCachedYtDlpVersion(_engineVersion);
      }
    } catch (e) {
      debugPrint('Native engine init warning: $e');
      _engineVersion = SettingsService.instance.cachedYtDlpVersion;
    }
    notifyListeners();
  }

  void _listenToEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          _handleProgressEvent(Map<String, dynamic>.from(event));
        }
      },
      onError: (err) {
        debugPrint('Engine EventChannel error: $err');
      },
    );
  }

  void _handleProgressEvent(Map<String, dynamic> data) {
    final taskId = data['taskId']?.toString();
    if (taskId == null) return;

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    final statusStr = data['status']?.toString() ?? '';
    final progress = (data['progress'] as num?)?.toDouble() ?? task.progress;
    final eta = (data['eta'] as num?)?.toInt() ?? task.etaSeconds;
    final line = data['line']?.toString() ?? '';
    final filePath = data['filePath']?.toString();
    final error = data['error']?.toString();

    task.progress = progress.clamp(0.0, 100.0);
    task.etaSeconds = eta;

    final speedMatch = RegExp(r'at\s+([0-9.]+[KMG]?i?B/s)', caseSensitive: false)
        .firstMatch(line);
    if (speedMatch != null) {
      task.speed = speedMatch.group(1) ?? '';
    }

    if (statusStr == 'starting') {
      task.status = DownloadStatus.starting;
    } else if (statusStr == 'downloading') {
      task.status = DownloadStatus.downloading;
    } else if (statusStr == 'completed') {
      task.status = DownloadStatus.completed;
      task.progress = 100.0;
      task.speed = '';
      task.etaSeconds = 0;
      if (filePath != null && filePath.isNotEmpty) {
        task.filePath = filePath;
        try {
          final f = File(filePath);
          if (f.existsSync()) {
            task.fileSizeBytes = f.lengthSync();
            final name = f.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
            if (name.isNotEmpty && !name.startsWith('media_')) {
              task.title = name;
            }
          }
        } catch (_) {}
      }
      _saveHistoryToDisk();
    } else if (statusStr == 'failed') {
      task.status = DownloadStatus.failed;
      task.error = error ?? 'Download failed';
      _saveHistoryToDisk();
    } else if (statusStr == 'cancelled') {
      task.status = DownloadStatus.cancelled;
      _saveHistoryToDisk();
    }

    notifyListeners();
  }

  Future<MediaInfo?> fetchMediaInfo(String url) async {
    try {
      final res = await _methodChannel.invokeMethod('fetchInfo', {'url': url});
      if (res is Map) {
        return MediaInfo.fromMap(res);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<String> startDownload({
    required String url,
    required String title,
    String thumbnail = '',
    String quality = '1080p',
    bool isAudioOnly = false,
    String audioBitrate = '320k',
    String? customTitle,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final targetDir = SettingsService.instance.downloadPath;

    final task = DownloadTask(
      id: taskId,
      url: url,
      title: customTitle?.trim().isNotEmpty == true ? customTitle!.trim() : title,
      thumbnail: thumbnail,
      quality: quality,
      isAudioOnly: isAudioOnly,
      audioBitrate: audioBitrate,
      status: DownloadStatus.queued,
    );

    _tasks.insert(0, task);
    notifyListeners();
    await _saveHistoryToDisk();

    try {
      await _methodChannel.invokeMethod('startDownload', {
        'taskId': taskId,
        'url': url,
        'quality': quality,
        'isAudioOnly': isAudioOnly,
        'audioBitrate': audioBitrate,
        'customTitle': customTitle,
        'targetDir': targetDir,
      });
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      notifyListeners();
      await _saveHistoryToDisk();
    }

    return taskId;
  }

  Future<bool> cancelDownload(String taskId) async {
    try {
      final res = await _methodChannel.invokeMethod('cancelDownload', {'taskId': taskId});
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index].status = DownloadStatus.cancelled;
        notifyListeners();
        await _saveHistoryToDisk();
      }
      return res == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> openFile(String path) async {
    try {
      final res = await _methodChannel.invokeMethod('openFile', {'path': path});
      return res == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> shareFile(String path) async {
    try {
      final res = await _methodChannel.invokeMethod('shareFile', {'path': path});
      return res == true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPendingSharedText() async {
    try {
      final res = await _methodChannel.invokeMethod('getPendingSharedText');
      return res as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateEngine() async {
    _isUpdatingEngine = true;
    notifyListeners();
    try {
      final res = await _methodChannel.invokeMethod('updateEngine');
      if (res is Map) {
        final newVer = res['version']?.toString();
        if (newVer != null && newVer.isNotEmpty) {
          _engineVersion = newVer;
          await SettingsService.instance.setCachedYtDlpVersion(newVer);
        }
        return Map<String, dynamic>.from(res);
      }
      return {'status': 'UNKNOWN'};
    } finally {
      _isUpdatingEngine = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId, {bool deleteFromDisk = false}) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      if (deleteFromDisk && task.filePath.isNotEmpty) {
        try {
          final f = File(task.filePath);
          if (f.existsSync()) {
            f.deleteSync();
          }
        } catch (_) {}
      }
      _tasks.removeAt(index);
      notifyListeners();
      await _saveHistoryToDisk();
    }
  }

  Future<void> clearCompletedTasks() async {
    _tasks.removeWhere((t) => t.isDone || t.hasFailed || t.status == DownloadStatus.cancelled);
    notifyListeners();
    await _saveHistoryToDisk();
  }

  Future<File> _getHistoryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/rv_downloader_tasks_v1.json');
  }

  Future<void> _loadHistoryFromDisk() async {
    try {
      final file = await _getHistoryFile();
      if (!file.existsSync()) return;
      final raw = await file.readAsString();
      if (raw.isEmpty) return;
      final list = jsonDecode(raw) as List?;
      if (list == null) return;

      _tasks.clear();
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _tasks.add(DownloadTask.fromJson(item));
        }
      }
    } catch (e) {
      debugPrint('History load error: $e');
    }
  }

  Future<void> _saveHistoryToDisk() async {
    try {
      final file = await _getHistoryFile();
      final data = _tasks.map((t) => t.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('History save error: $e');
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
