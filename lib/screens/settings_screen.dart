import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/native_downloader_service.dart';
import '../services/settings_service.dart';
import '../widgets/liquid_button.dart';
import '../widgets/liquid_glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pathController.text = SettingsService.instance.downloadPath;
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _updateEngine() async {
    try {
      final res = await NativeDownloaderService.instance.updateEngine();
      if (!mounted) return;
      final status = res['status']?.toString() ?? 'DONE';
      final ver = res['version']?.toString() ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'ALREADY_UP_TO_DATE'
                ? 'yt-dlp engine is already up to date!'
                : 'yt-dlp engine successfully updated to $ver',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E2638),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (e is PlatformException) {
        errorMsg = e.message ?? e.code;
      }
      if (errorMsg == 'fg') {
        errorMsg = 'Engine updating component is ready. Please retry in a few seconds.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Engine status: $errorMsg',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF2E1C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;

    return Scaffold(
      backgroundColor: Colors.black, // Pure OLED
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
          children: [
            // Title
            const Text(
              'Settings & Engine',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customize your download engine and preferences',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),

            // yt-dlp Section
            _buildSectionHeader('CORE YT-DLP ENGINE'),
            const SizedBox(height: 8),
            LiquidGlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'yt-dlp Version',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ListenableBuilder(
                        listenable: NativeDownloaderService.instance,
                        builder: (context, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A84FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              NativeDownloaderService.instance.engineVersion,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When download links fail or video platforms change their extractors, tap below to pull the latest official yt-dlp release on the fly.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListenableBuilder(
                    listenable: NativeDownloaderService.instance,
                    builder: (context, _) {
                      return LiquidButton(
                        isLoading: NativeDownloaderService.instance.isUpdatingEngine,
                        onTap: _updateEngine,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.system_update_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Update yt-dlp Extractor Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Defaults Section
            _buildSectionHeader('DEFAULT QUALITY PREFERENCES'),
            const SizedBox(height: 8),
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                children: [
                  ListenableBuilder(
                    listenable: settings,
                    builder: (context, _) {
                      return _buildDropdownRow(
                        title: 'Default Video Quality',
                        value: settings.defaultQuality,
                        items: const [
                          DropdownMenuItem(value: '1080p', child: Text('1080p (Full HD)')),
                          DropdownMenuItem(value: '720p', child: Text('720p (High Quality)')),
                          DropdownMenuItem(value: '360p', child: Text('360p (Data Saver)')),
                        ],
                        onChanged: (val) {
                          if (val != null) settings.setDefaultQuality(val);
                        },
                      );
                    },
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  ListenableBuilder(
                    listenable: settings,
                    builder: (context, _) {
                      return _buildDropdownRow(
                        title: 'Default MP3 Bitrate',
                        value: settings.defaultBitrate,
                        items: const [
                          DropdownMenuItem(value: '320k', child: Text('320 kbps (Studio HQ)')),
                          DropdownMenuItem(value: '256k', child: Text('256 kbps (High Quality)')),
                          DropdownMenuItem(value: '192k', child: Text('192 kbps (Standard)')),
                          DropdownMenuItem(value: '128k', child: Text('128 kbps (Compact)')),
                        ],
                        onChanged: (val) {
                          if (val != null) settings.setDefaultBitrate(val);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Automation & Storage
            _buildSectionHeader('AUTOMATION & STORAGE'),
            const SizedBox(height: 8),
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                children: [
                  ListenableBuilder(
                    listenable: settings,
                    builder: (context, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Auto-paste link from clipboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Automatically detects copied links when app opens',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        value: settings.autoPasteClipboard,
                        activeColor: const Color(0xFF0A84FF),
                        onChanged: (val) => settings.setAutoPasteClipboard(val),
                      );
                    },
                  ),
                  const Divider(color: Colors.white12, height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Download Directory Path',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Public folder on device storage accessible to gallery & players',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 0.8,
                          ),
                        ),
                        child: TextField(
                          controller: _pathController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          onSubmitted: (val) => settings.setDownloadPath(val.trim()),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy & Personal Note
            _buildSectionHeader('APPLICATION INFO'),
            const SizedBox(height: 8),
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RV Downloader - Personal Media Downloader',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built strictly for private personal offline backup use. Powered by native yt-dlp Python engine.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.3+4 • Architecture ARM64-v8a',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildDropdownRow({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF161B27),
          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w700),
          underline: const SizedBox.shrink(),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
