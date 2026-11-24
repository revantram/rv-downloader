import 'package:flutter/material.dart';
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
  static const String _keyIsDarkTheme = 'is_dark_theme';
  static const String _keyTeraboxCookie = 'terabox_cookie';

  String _defaultQuality = '1080p';
  String _defaultBitrate = '320k';
  String _downloadPath = '/storage/emulated/0/Download/RV-Downloader';
  bool _autoPasteClipboard = true;
  bool _notifyOnComplete = true;
  String _cachedYtDlpVersion = 'yt-dlp Engine';
  bool _isDarkTheme = true;
  String _teraboxCookie = '';

  String get defaultQuality => _defaultQuality;
  String get defaultBitrate => _defaultBitrate;
  String get downloadPath => _downloadPath;
  bool get autoPasteClipboard => _autoPasteClipboard;
  bool get notifyOnComplete => _notifyOnComplete;
  String get cachedYtDlpVersion => _cachedYtDlpVersion;
  bool get isDarkTheme => _isDarkTheme;
  String get teraboxCookie => _teraboxCookie;

  // Theme Dynamic Palette
  Color get backgroundColor => _isDarkTheme ? Colors.black : const Color(0xFFF8FAFC);
  Color get surfaceColor => _isDarkTheme ? const Color(0xFF101420) : Colors.white;
  Color get cardBackgroundColor => _isDarkTheme ? Colors.white.withValues(alpha: 0.05) : Colors.white;
  Color get cardBorderColor => _isDarkTheme ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
  Color get primaryTextColor => _isDarkTheme ? Colors.white : const Color(0xFF0F172A);
  Color get secondaryTextColor => _isDarkTheme ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF64748B);
  Color get subtleTextColor => _isDarkTheme ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF94A3B8);
  Color get dividerColor => _isDarkTheme ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
  Color get textFieldBg => _isDarkTheme ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF8FAFC);
  Color get textFieldBorder => _isDarkTheme ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1);
  Color get shadowColor => _isDarkTheme ? Colors.black.withValues(alpha: 0.45) : const Color(0xFF64748B).withValues(alpha: 0.12);
  Color get bottomNavBg => _isDarkTheme ? const Color(0xFF111624).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95);
  Color get bottomNavBorder => _isDarkTheme ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFE2E8F0);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultQuality = prefs.getString(_keyDefaultQuality) ?? '1080p';
    _defaultBitrate = prefs.getString(_keyDefaultBitrate) ?? '320k';
    _downloadPath = prefs.getString(_keyDownloadPath) ?? '/storage/emulated/0/Download/RV-Downloader';
    _autoPasteClipboard = prefs.getBool(_keyAutoPaste) ?? true;
    _notifyOnComplete = prefs.getBool(_keyNotifyDone) ?? true;
    _cachedYtDlpVersion = prefs.getString(_keyYtDlpVersion) ?? 'yt-dlp Engine';
    _isDarkTheme = prefs.getBool(_keyIsDarkTheme) ?? true;
    _teraboxCookie = prefs.getString(_keyTeraboxCookie) ?? '';
    notifyListeners();
  }

  Future<void> setTeraboxCookie(String cookie) async {
    _teraboxCookie = cookie.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTeraboxCookie, _teraboxCookie);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkTheme, _isDarkTheme);
    notifyListeners();
  }

  Future<void> setDarkTheme(bool val) async {
    _isDarkTheme = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkTheme, val);
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
