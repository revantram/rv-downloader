import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class LiquidTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? prefixIcon;
  final VoidCallback? onClear;
  final VoidCallback? onPaste;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType keyboardType;
  final FocusNode? focusNode;

  const LiquidTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.onClear,
    this.onPaste,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.url,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final theme = SettingsService.instance;
        final isDark = theme.isDarkTheme;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: theme.textFieldBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.textFieldBorder,
                  width: 0.9,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: keyboardType,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: theme.subtleTextColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      if (value.text.isNotEmpty) {
                        return IconButton(
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 20,
                            color: theme.secondaryTextColor,
                          ),
                          onPressed: () {
                            controller.clear();
                            if (onClear != null) onClear!();
                          },
                        );
                      }
                      if (onPaste != null) {
                        return TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            backgroundColor:
                                const Color(0xFF0A84FF).withValues(alpha: isDark ? 0.18 : 0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color:
                                    const Color(0xFF0A84FF).withValues(alpha: isDark ? 0.4 : 0.25),
                                width: 0.8,
                              ),
                            ),
                          ),
                          onPressed: onPaste,
                          child: const Text(
                            'PASTE',
                            style: TextStyle(
                              color: Color(0xFF0A84FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
