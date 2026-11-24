class MediaFormat {
  final String formatId;
  final String formatNote;
  final String ext;
  final String vcodec;
  final String acodec;
  final int filesize;
  final int fps;
  final int height;
  final int width;
  final int tbr;

  const MediaFormat({
    required this.formatId,
    required this.formatNote,
    required this.ext,
    required this.vcodec,
    required this.acodec,
    required this.filesize,
    required this.fps,
    required this.height,
    required this.width,
    required this.tbr,
  });

  bool get isAudioOnly => vcodec == 'none' && acodec != 'none';
  bool get isVideoOnly => acodec == 'none' && vcodec != 'none';

  factory MediaFormat.fromMap(Map<dynamic, dynamic> map) {
    return MediaFormat(
      formatId: map['formatId']?.toString() ?? '',
      formatNote: map['formatNote']?.toString() ?? '',
      ext: map['ext']?.toString() ?? '',
      vcodec: map['vcodec']?.toString() ?? '',
      acodec: map['acodec']?.toString() ?? '',
      filesize: (map['filesize'] as num?)?.toInt() ?? 0,
      fps: (map['fps'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      width: (map['width'] as num?)?.toInt() ?? 0,
      tbr: (map['tbr'] as num?)?.toInt() ?? 0,
    );
  }
}

class MediaInfo {
  final String id;
  final String title;
  final Duration duration;
  final String thumbnail;
  final String uploader;
  final String webpageUrl;
  final String description;
  final List<MediaFormat> formats;

  const MediaInfo({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnail,
    required this.uploader,
    required this.webpageUrl,
    required this.description,
    required this.formats,
  });

  factory MediaInfo.fromMap(Map<dynamic, dynamic> map) {
    final rawFormats = map['formats'] as List? ?? [];
    final formatsList = rawFormats
        .whereType<Map<dynamic, dynamic>>()
        .map((f) => MediaFormat.fromMap(f))
        .toList();

    return MediaInfo(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Media',
      duration: Duration(seconds: (map['duration'] as num?)?.toInt() ?? 0),
      thumbnail: map['thumbnail']?.toString() ?? '',
      uploader: map['uploader']?.toString() ?? '',
      webpageUrl: map['webpageUrl']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      formats: formatsList,
    );
  }
}
