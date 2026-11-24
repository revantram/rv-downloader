import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 22,
    this.blurSigma = 24,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final theme = SettingsService.instance;
        final isDark = theme.isDarkTheme;

        final defaultBg = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white;
        final defaultBorder = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFE2E8F0);
        final defaultShadow = isDark
            ? Colors.black.withValues(alpha: 0.45)
            : const Color(0xFF64748B).withValues(alpha: 0.12);

        Widget card = ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor ?? defaultBg,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor ?? defaultBorder,
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: defaultShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );

        if (onTap != null) {
          card = Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              splashColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFF0A84FF).withValues(alpha: 0.08),
              highlightColor: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFF0A84FF).withValues(alpha: 0.04),
              child: card,
            ),
          );
        }

        if (margin != EdgeInsets.zero) {
          card = Padding(padding: margin, child: card);
        }

        return card;
      },
    );
  }
}
