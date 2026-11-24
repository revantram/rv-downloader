enum SupportedPlatform {
  youtube,
  instagram,
  terabox,
  tiktok,
  twitter,
  reddit,
  facebook,
  generic,
}

class UrlDetector {
  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  /// Extracts the first valid HTTP/HTTPS URL from any shared text
  static String? extractUrl(String rawText) {
    if (rawText.trim().isEmpty) return null;
    final match = _urlRegex.firstMatch(rawText);
    return match?.group(0)?.trim();
  }

  /// Identifies the platform of the given URL
  static SupportedPlatform identifyPlatform(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('terabox') ||
        lower.contains('1024tera') ||
        lower.contains('teraboxapp') ||
        lower.contains('4funbox') ||
        lower.contains('mirrobox')) {
      return SupportedPlatform.terabox;
    }
    if (lower.contains('instagram.com') || lower.contains('instagr.am')) {
      return SupportedPlatform.instagram;
    }
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return SupportedPlatform.youtube;
    }
    if (lower.contains('tiktok.com')) {
      return SupportedPlatform.tiktok;
    }
    if (lower.contains('twitter.com') || lower.contains('x.com')) {
      return SupportedPlatform.twitter;
    }
    if (lower.contains('reddit.com') || lower.contains('redd.it')) {
      return SupportedPlatform.reddit;
    }
    if (lower.contains('facebook.com') || lower.contains('fb.watch')) {
      return SupportedPlatform.facebook;
    }
    return SupportedPlatform.generic;
  }

  static String getPlatformName(SupportedPlatform platform) {
    switch (platform) {
      case SupportedPlatform.youtube:
        return 'YouTube';
      case SupportedPlatform.instagram:
        return 'Instagram';
      case SupportedPlatform.terabox:
        return 'TeraBox';
      case SupportedPlatform.tiktok:
        return 'TikTok';
      case SupportedPlatform.twitter:
        return 'X / Twitter';
      case SupportedPlatform.reddit:
        return 'Reddit';
      case SupportedPlatform.facebook:
        return 'Facebook';
      case SupportedPlatform.generic:
        return 'Web Media';
    }
  }

  static String getPlatformIcon(SupportedPlatform platform) {
    switch (platform) {
      case SupportedPlatform.youtube:
        return '▶️';
      case SupportedPlatform.instagram:
        return '📸';
      case SupportedPlatform.terabox:
        return '📦';
      case SupportedPlatform.tiktok:
        return '🎵';
      case SupportedPlatform.twitter:
        return '🐦';
      case SupportedPlatform.reddit:
        return '🤖';
      case SupportedPlatform.facebook:
        return '👥';
      case SupportedPlatform.generic:
        return '🌐';
    }
  }
}
