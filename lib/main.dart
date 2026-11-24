import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';
import 'services/native_downloader_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge to edge immersive display with transparent bars
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Core Services
  await SettingsService.instance.init();
  await NativeDownloaderService.instance.init();

  runApp(const RVDownloaderApp());
}

class RVDownloaderApp extends StatelessWidget {
  const RVDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RV Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF0A84FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF101420),
          background: Colors.black,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const RootNavigationContainer(),
    );
  }
}

class RootNavigationContainer extends StatefulWidget {
  const RootNavigationContainer({super.key});

  @override
  State<RootNavigationContainer> createState() =>
      _RootNavigationContainerState();
}

class _RootNavigationContainerState extends State<RootNavigationContainer> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestStoragePermissions();
  }

  Future<void> _requestStoragePermissions() async {
    try {
      await [
        Permission.storage,
        Permission.videos,
        Permission.audio,
        Permission.notification,
      ].request();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // Floating iOS Liquid Glass Bottom Navigation Bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111624).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.cloud_download_rounded,
                        activeIcon: Icons.cloud_download_rounded,
                        label: 'Downloader',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.folder_rounded,
                        activeIcon: Icons.folder_rounded,
                        label: 'Storage',
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.settings_rounded,
                        activeIcon: Icons.settings_rounded,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
          if (index == 1) {
            StorageService.instance.refresh();
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0A84FF).withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withValues(alpha: 0.45),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
