import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
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
                        color: Colors.white.withValues(alpha: 0.6),
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
                            const Color(0xFF0A84FF).withValues(alpha: 0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color:
                                const Color(0xFF0A84FF).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                      ),
                      onPressed: onPaste,
                      child: const Text(
                        'PASTE',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
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
  }
}
