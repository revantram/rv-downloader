import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/file_utils.dart';
import 'native_downloader_service.dart';
import 'settings_service.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String tagName;
  final String releaseName;
  final String changelog;
  final String downloadUrl;
  final int apkSizeBytes;
  final int remoteBuild;

  const UpdateInfo({
    required this.hasUpdate,
    this.tagName = '',
    this.releaseName = '',
    this.changelog = '',
    this.downloadUrl = '',
    this.apkSizeBytes = 0,
    this.remoteBuild = 0,
  });
}

class UpdateService {
  static final UpdateService instance = UpdateService._();
  UpdateService._();

  static const String currentVersion = '1.0.8';
  static const int currentBuild = 9;
  static const String repoOwner = 'revantram';
  static const String repoName = 'rv-downloader';

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  Future<UpdateInfo> checkForUpdate() async {
    _isChecking = true;
    try {
      final uri = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final resp = await http.get(uri, headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final tagName = data['tag_name']?.toString() ?? '';
        final releaseName = data['name']?.toString() ?? 'Latest Release';
        final changelog = data['body']?.toString() ?? '';
        final assets = (data['assets'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];

        // Pick ARM64 APK or generic APK
        Map<String, dynamic>? apkAsset = assets.firstWhere(
          (a) => a['name']?.toString().contains('arm64') == true && a['name']?.toString().endsWith('.apk') == true,
          orElse: () => assets.firstWhere(
            (a) => a['name']?.toString().endsWith('.apk') == true,
            orElse: () => <String, dynamic>{},
          ),
        );

        final downloadUrl = apkAsset['browser_download_url']?.toString() ?? '';
        final apkSize = (apkAsset['size'] as num?)?.toInt() ?? 0;

        // Parse remote build number from tag (e.g., v1.0.8-b9 -> build 9)
        int remoteBuild = 0;
        final bMatch = RegExp(r'-b(\d+)').firstMatch(tagName);
        if (bMatch != null) {
          remoteBuild = int.tryParse(bMatch.group(1) ?? '0') ?? 0;
        }

        final isNewer = remoteBuild > currentBuild || _isVersionGreater(tagName, currentVersion);

        return UpdateInfo(
          hasUpdate: isNewer && downloadUrl.isNotEmpty,
          tagName: tagName,
          releaseName: releaseName,
          changelog: changelog,
          downloadUrl: downloadUrl,
          apkSizeBytes: apkSize,
          remoteBuild: remoteBuild,
        );
      }
    } catch (e) {
      debugPrint('Check for update error: $e');
    } finally {
      _isChecking = false;
    }

    return const UpdateInfo(hasUpdate: false);
  }

  bool _isVersionGreater(String remoteTag, String localVer) {
    try {
      final cleanTag = remoteTag.replaceAll(RegExp(r'[^0-9.]'), '');
      final rParts = cleanTag.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final lParts = localVer.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> checkAndShowUpdateDialog(BuildContext context, {bool showToastIfLatest = true}) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Quick indicator
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
            ),
            SizedBox(width: 14),
            Text(
              'अपडेट की जांच हो रही है (Checking for updates)...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2638),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final info = await checkForUpdate();
    if (!context.mounted) return;

    if (info.hasUpdate) {
      _showUpdateModal(context, info);
    } else {
      if (showToastIfLatest) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '✅ आप पहले से ही नवीनतम संस्करण (v$currentVersion • Build $currentBuild) पर हैं!',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF065F46),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUpdateModal(BuildContext context, UpdateInfo info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdateDownloadSheet(info: info),
    );
  }
}

class _UpdateDownloadSheet extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDownloadSheet({required this.info});

  @override
  State<_UpdateDownloadSheet> createState() => _UpdateDownloadSheetState();
}

class _UpdateDownloadSheetState extends State<_UpdateDownloadSheet> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startInAppDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'डाउनलोड शुरू हो रहा है...';
    });

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.info.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? widget.info.apkSizeBytes;
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/RV-Downloader-Update.apk');
      if (targetFile.existsSync()) targetFile.deleteSync();

      final sink = targetFile.openWrite();
      int downloaded = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() {
            _progress = (downloaded / contentLength).clamp(0.0, 1.0);
            _statusText = '${FileUtils.formatBytes(downloaded)} / ${FileUtils.formatBytes(contentLength)} (${(_progress * 100).toStringAsFixed(0)}%)';
          });
        }
      }

      await sink.flush();
      await sink.close();

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _statusText = 'डाउनलोड पूरा हुआ! इंस्टॉलर खुल रहा है...';
        });
      }

      // Invoke Android package installer via native FileProvider
      await Future.delayed(const Duration(milliseconds: 400));
      final installed = await NativeDownloaderService.instance.installApk(targetFile.path);

      if (!installed && mounted) {
        // Fallback: try openFile
        await NativeDownloaderService.instance.openFile(targetFile.path);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'डाउनलोड विफल: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = SettingsService.instance;
    final isDark = theme.isDarkTheme;
    final sizeFormatted = widget.info.apkSizeBytes > 0
        ? FileUtils.formatBytes(widget.info.apkSizeBytes)
        : '25 MB';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101420) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE2E8F0),
          width: 0.9,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.paddingOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'नया अपडेट उपलब्ध है!',
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.info.releaseName} (${widget.info.tagName})',
                      style: const TextStyle(
                        color: Color(0xFF0A84FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sizeFormatted,
                  style: const TextStyle(
                    color: Color(0xFF0A84FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Changelog Box
          if (widget.info.changelog.isNotEmpty) ...[
            Text(
              'नया क्या है (WHAT\'S NEW)',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.info.changelog,
                  style: TextStyle(
                    color: theme.primaryTextColor.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Download Progress Bar (if in-app download running)
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A84FF)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _statusText,
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_progress > 0)
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF0A84FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Actions
          if (!_isDownloading) ...[
            // In-App Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _startInAppDownload,
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'इन-ऐप अपडेट करें (In-App Update)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Browser download fallback
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.secondaryTextColor,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      NativeDownloaderService.instance.openUrl(widget.info.downloadUrl);
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: const Text('ब्राउज़र से डाउनलोड करें'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('बाद में (Later)', style: TextStyle(color: theme.secondaryTextColor)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
