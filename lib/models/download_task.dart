enum DownloadStatus {
  idle,
  queued,
  starting,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String url;
  String title;
  final String thumbnail;
  final String quality; // "best", "1080p", "720p", "480p", "360p", "audio_mp3"
  final bool isAudioOnly;
  final String audioBitrate;
  DownloadStatus status;
  double progress; // 0.0 to 100.0
  int etaSeconds;
  String speed;
  String filePath;
  String error;
  final DateTime createdAt;
  int fileSizeBytes;

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.thumbnail = '',
    this.quality = '1080p',
    this.isAudioOnly = false,
    this.audioBitrate = '320k',
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.etaSeconds = 0,
    this.speed = '',
    this.filePath = '',
    this.error = '',
    DateTime? createdAt,
    this.fileSizeBytes = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.starting ||
      status == DownloadStatus.downloading;

  bool get isDone => status == DownloadStatus.completed;
  bool get hasFailed => status == DownloadStatus.failed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'thumbnail': thumbnail,
        'quality': quality,
        'isAudioOnly': isAudioOnly,
        'audioBitrate': audioBitrate,
        'status': status.name,
        'progress': progress,
        'etaSeconds': etaSeconds,
        'speed': speed,
        'filePath': filePath,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    DownloadStatus s = DownloadStatus.idle;
    try {
      s = DownloadStatus.values.byName(json['status']?.toString() ?? 'idle');
    } catch (_) {}

    return DownloadTask(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Media',
      thumbnail: json['thumbnail']?.toString() ?? '',
      quality: json['quality']?.toString() ?? '1080p',
      isAudioOnly: json['isAudioOnly'] == true,
      audioBitrate: json['audioBitrate']?.toString() ?? '320k',
      status: s,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      etaSeconds: (json['etaSeconds'] as num?)?.toInt() ?? 0,
      speed: json['speed']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      error: json['error']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
