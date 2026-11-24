import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/native_downloader_service.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';

class DeveloperOptionsCard extends StatelessWidget {
  const DeveloperOptionsCard({super.key});

  static const String developerName = 'रेवंतराम भाती';
  static const String developerEmail = 'revantrambhati@gmail.com';
  static const String developerPhone = '+91 8696663615';
  static const String developerPhoneRaw = '918696663615';

  void _handleEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: developerEmail));
    HapticFeedback.selectionClick();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ईमेल कॉपी हो गया: revantrambhati@gmail.com', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1E2638),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    NativeDownloaderService.instance.openUrl('mailto:$developerEmail');
  }

  void _handlePhone(BuildContext context) {
    HapticFeedback.selectionClick();
    final theme = SettingsService.instance;
    final isDark = theme.isDarkTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131824) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(ctx).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'डेवलपर से संपर्क करें ($developerPhone)',
              style: TextStyle(
                color: theme.primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 22),
              ),
              title: Text('WhatsApp पर मैसेज करें', style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w600)),
              subtitle: Text('+91 8696663615', style: TextStyle(color: theme.secondaryTextColor, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                NativeDownloaderService.instance.openUrl('https://wa.me/$developerPhoneRaw');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_rounded, color: Color(0xFF0A84FF), size: 22),
              ),
              title: Text('डायरेक्ट कॉल करें', style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w600)),
              subtitle: Text('+91 8696663615', style: TextStyle(color: theme.secondaryTextColor, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                NativeDownloaderService.instance.openUrl('tel:$developerPhoneRaw');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.copy_rounded, color: theme.primaryTextColor, size: 22),
              ),
              title: Text('नंबर कॉपी करें', style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(const ClipboardData(text: developerPhone));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('मोबाइल नंबर कॉपी हो गया!', style: TextStyle(color: Colors.white)),
                    backgroundColor: Color(0xFF1E2638),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final theme = SettingsService.instance;
        final isDark = theme.isDarkTheme;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111726) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : const Color(0xFF64748B).withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'डेवलपर ऑप्शन एवं अपडेट',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                  // APK Version Badge in Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'APK v${UpdateService.currentVersion}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDivider(isDark),

              // Row 1: मुख्य डेवलपर व संचालक
              _buildInfoRow(
                isDark: isDark,
                label: 'मुख्य डेवलपर व संचालक:',
                valueWidget: Text(
                  developerName,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildDivider(isDark),

              // Row 2: डेवलपर ईमेल
              _buildInfoRow(
                isDark: isDark,
                label: 'डेवलपर ईमेल (Gmail):',
                valueWidget: InkWell(
                  onTap: () => _handleEmail(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail_rounded, color: Color(0xFF2563EB), size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            developerEmail,
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF2563EB),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildDivider(isDark),

              // Row 3: डेवलपर मोबाइल नंबर
              _buildInfoRow(
                isDark: isDark,
                label: 'डेवलपर मोबाइल नंबर:',
                valueWidget: InkWell(
                  onTap: () => _handlePhone(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded, color: Color(0xFF16A34A), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          developerPhone,
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chat_bubble_rounded, color: Color(0xFF22C55E), size: 15),
                      ],
                    ),
                  ),
                ),
              ),
              _buildDivider(isDark),

              // Row 4: एपीके संस्करण
              _buildInfoRow(
                isDark: isDark,
                label: 'एपीके संस्करण (APK Version):',
                valueWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3B82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${UpdateService.currentVersion} (बिल्ड कोड: ${UpdateService.currentBuild})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _buildDivider(isDark),

              // Row 5: क्लाउड डेटाबेस
              _buildInfoRow(
                isDark: isDark,
                label: 'क्लाउड डेटाबेस:',
                valueWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF22C55E),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GitHub Releases कनेक्टेड',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Bottom Prominent Button: अपडेट की जांच करें (Check for Updates)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    shadowColor: const Color(0xFF1D4ED8).withValues(alpha: 0.45),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    UpdateService.instance.checkAndShowUpdateDialog(context);
                  },
                  icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'अपडेट की जांच करें (Check for Updates)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required bool isDark,
    required String label,
    required Widget valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFF1F5F9),
    );
  }
}
