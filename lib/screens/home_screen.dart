import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/download_task.dart';
import '../models/media_info.dart';
import '../services/native_downloader_service.dart';
import '../services/settings_service.dart';
import '../utils/url_detector.dart';
import '../widgets/download_task_card.dart';
import '../widgets/format_selector_sheet.dart';
import '../widgets/liquid_button.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/liquid_text_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _urlController = TextEditingController();
  bool _isFetching = false;
  String? _detectedPlatformName;
  String? _detectedPlatformIcon;
  SupportedPlatform _platform = SupportedPlatform.generic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _urlController.addListener(_onUrlChanged);
    _checkInitialClipboardAndIntent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingSharedIntent();
    }
  }

  Future<void> _checkInitialClipboardAndIntent() async {
    await _checkPendingSharedIntent();
    if (_urlController.text.isEmpty &&
        SettingsService.instance.autoPasteClipboard) {
      _pasteFromClipboard();
    }
  }

  Future<void> _checkPendingSharedIntent() async {
    final shared = await NativeDownloaderService.instance.getPendingSharedText();
    if (shared != null && shared.isNotEmpty) {
      final extracted = UrlDetector.extractUrl(shared);
      if (extracted != null) {
        setState(() {
          _urlController.text = extracted;
        });
        _inspectMedia();
      }
    }
  }

  void _onUrlChanged() {
    final text = _urlController.text.trim();
    if (text.isNotEmpty) {
      final plat = UrlDetector.identifyPlatform(text);
      setState(() {
        _platform = plat;
        _detectedPlatformName = UrlDetector.getPlatformName(plat);
        _detectedPlatformIcon = UrlDetector.getPlatformIcon(plat);
      });
    } else {
      setState(() {
        _detectedPlatformName = null;
        _detectedPlatformIcon = null;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      final extracted = UrlDetector.extractUrl(text);
      if (extracted != null) {
        setState(() {
          _urlController.text = extracted;
        });
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> _inspectMedia() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showToast('Please paste a media URL');
      return;
    }

    setState(() => _isFetching = true);

    try {
      final info = await NativeDownloaderService.instance.fetchMediaInfo(url);
      if (!mounted) return;

      if (info != null) {
        _openFormatSelector(info);
      } else {
        _showToast('Failed to retrieve video details');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _quickDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showToast('Please paste a media URL');
      return;
    }

    final quality = SettingsService.instance.defaultQuality;
    final bitrate = SettingsService.instance.defaultBitrate;
    final isAudio = quality.contains('audio') || quality.contains('mp3');

    await NativeDownloaderService.instance.startDownload(
      url: url,
      title: 'Downloading media...',
      quality: quality,
      isAudioOnly: isAudio,
      audioBitrate: bitrate,
    );

    _urlController.clear();
    _showToast('Download started in background');
  }

  void _openFormatSelector(MediaInfo info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FormatSelectorSheet(
        info: info,
        onDownload: ({
          required String quality,
          required bool isAudioOnly,
          required String audioBitrate,
          String? customTitle,
        }) async {
          await NativeDownloaderService.instance.startDownload(
            url: info.webpageUrl.isNotEmpty ? info.webpageUrl : _urlController.text.trim(),
            title: info.title,
            thumbnail: info.thumbnail,
            quality: quality,
            isAudioOnly: isAudioOnly,
            audioBitrate: audioBitrate,
            customTitle: customTitle,
          );
          _urlController.clear();
          _showToast('Added to download queue');
        },
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E2638),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(dynamic error) {
    String cleanMessage = error.toString();
    if (error is PlatformException) {
      cleanMessage = error.message ?? error.code;
    }

    if (cleanMessage.contains('HTTP Error 403') || cleanMessage.contains('Forbidden')) {
      cleanMessage = 'Access was restricted by the platform. The media might be private or requires an account login.';
    } else if (cleanMessage.contains('Unsupported URL') || cleanMessage.contains('is not a valid URL')) {
      cleanMessage = 'This URL does not appear to contain downloadable media or is not supported.';
    } else if (cleanMessage == 'fg' || cleanMessage.contains('instance not initialized')) {
      cleanMessage = 'yt-dlp engine is loading its native components. Please wait a moment and try again.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131824),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 26),
            SizedBox(width: 10),
            Text('Download Notice',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            cleanMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              NativeDownloaderService.instance.updateEngine();
            },
            child: const Text('Update Engine', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black, // Pure OLED Black
      body: Stack(
        children: [
          // Subtle Ambient Background Glows
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A84FF).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9333EA).withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'RV ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Downloader',
                                  style: TextStyle(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Personal Media Downloader powered by yt-dlp',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Engine Status Capsule
                        ListenableBuilder(
                          listenable: NativeDownloaderService.instance,
                          builder: (context, _) {
                            final ver = NativeDownloaderService.instance.engineVersion;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ver.split(' ').first,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                ),

                // URL Input Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LiquidGlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'DOWNLOAD MEDIA',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (_detectedPlatformName != null) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A84FF)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.4),
                                      width: 0.7,
                                    ),
                                  ),
                                  child: Text(
                                    '$_detectedPlatformIcon $_detectedPlatformName',
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Text input
                          LiquidTextField(
                            controller: _urlController,
                            hintText:
                                'Paste TeraBox, Instagram, YouTube, TikTok link...',
                            prefixIcon: Icon(
                              Icons.link_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 22,
                            ),
                            onPaste: _pasteFromClipboard,
                            onSubmitted: (_) => _inspectMedia(),
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: LiquidButton(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
                                  ),
                                  isLoading: _isFetching,
                                  onTap: _inspectMedia,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.tune_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Quality Options',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: LiquidButton(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  onTap: _quickDownload,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.bolt_rounded,
                                          color: Color(0xFF38BDF8), size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        'Quick DL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Tasks List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DOWNLOAD QUEUE & ACTIVITY',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        ListenableBuilder(
                          listenable: NativeDownloaderService.instance,
                          builder: (context, _) {
                            final tasks = NativeDownloaderService.instance.tasks;
                            if (tasks.isEmpty) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () => NativeDownloaderService.instance
                                  .clearCompletedTasks(),
                              child: Text(
                                'Clear finished',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // Tasks Sliver List
                ListenableBuilder(
                  listenable: NativeDownloaderService.instance,
                  builder: (context, _) {
                    final tasks = NativeDownloaderService.instance.tasks;

                    if (tasks.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_download_outlined,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No active downloads',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Paste a link above to start downloading media',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = tasks[index];
                          return DownloadTaskCard(task: task);
                        },
                        childCount: tasks.length,
                      ),
                    );
                  },
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
