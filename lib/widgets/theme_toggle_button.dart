import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';

class ThemeToggleButton extends StatelessWidget {
  final double size;
  const ThemeToggleButton({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final settings = SettingsService.instance;
        final isDark = settings.isDarkTheme;

        return Tooltip(
          message: isDark ? 'Switch to White Theme' : 'Switch to Black Theme',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              settings.toggleTheme();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFFE2E8F0),
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.4)
                            : const Color(0xFF64748B).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: isDark
                          ? const Icon(
                              Icons.light_mode_rounded,
                              key: ValueKey('sun'),
                              color: Color(0xFFFBBF24), // Warm amber sun
                              size: 20,
                            )
                          : const Icon(
                              Icons.dark_mode_rounded,
                              key: ValueKey('moon'),
                              color: Color(0xFF4F46E5), // Indigo moon
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
