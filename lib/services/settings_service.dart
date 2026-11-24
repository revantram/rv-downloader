import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  static const String _keyDefaultQuality = 'default_quality';
  static const String _keyDefaultBitrate = 'default_bitrate';
  static const String _keyDownloadPath = 'download_path';
  static const String _keyAutoPaste = 'auto_paste_clipboard';
  static const String _keyNotifyDone = 'notify_on_complete';
  static const String _keyYtDlpVersion = 'cached_ytdlp_version';

  String _defaultQuality = '1080p';
  String _defaultBitrate = '320k';
  String _downloadPath = '/storage/emulated/0/Download/RV-Downloader';
  bool _autoPasteClipboard = true;
  bool _notifyOnComplete = true;
  String _cachedYtDlpVersion = 'yt-dlp Engine';

  String get defaultQuality => _defaultQuality;
  String get defaultBitrate => _defaultBitrate;
  String get downloadPath => _downloadPath;
  bool get autoPasteClipboard => _autoPasteClipboard;
  bool get notifyOnComplete => _notifyOnComplete;
  String get cachedYtDlpVersion => _cachedYtDlpVersion;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultQuality = prefs.getString(_keyDefaultQuality) ?? '1080p';
    _defaultBitrate = prefs.getString(_keyDefaultBitrate) ?? '320k';
    _downloadPath = prefs.getString(_keyDownloadPath) ?? '/storage/emulated/0/Download/RV-Downloader';
    _autoPasteClipboard = prefs.getBool(_keyAutoPaste) ?? true;
    _notifyOnComplete = prefs.getBool(_keyNotifyDone) ?? true;
    _cachedYtDlpVersion = prefs.getString(_keyYtDlpVersion) ?? 'yt-dlp Engine';
    notifyListeners();
  }

  Future<void> setDefaultQuality(String val) async {
    _defaultQuality = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultQuality, val);
    notifyListeners();
  }

  Future<void> setDefaultBitrate(String val) async {
    _defaultBitrate = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultBitrate, val);
    notifyListeners();
  }

  Future<void> setDownloadPath(String path) async {
    _downloadPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDownloadPath, path);
    notifyListeners();
  }

  Future<void> setAutoPasteClipboard(bool val) async {
    _autoPasteClipboard = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPaste, val);
    notifyListeners();
  }

  Future<void> setNotifyOnComplete(bool val) async {
    _notifyOnComplete = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifyDone, val);
    notifyListeners();
  }

  Future<void> setCachedYtDlpVersion(String ver) async {
    _cachedYtDlpVersion = ver;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyYtDlpVersion, ver);
    notifyListeners();
  }
}
