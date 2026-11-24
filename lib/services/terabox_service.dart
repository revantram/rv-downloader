import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class TeraBoxFile {
  final String title;
  final String downloadUrl;
  final String? fastDownloadUrl;
  final String? streamUrl;
  final String? thumbnail;
  final int? sizeBytes;
  final String? sizeFormatted;

  TeraBoxFile({
    required this.title,
    required this.downloadUrl,
    this.fastDownloadUrl,
    this.streamUrl,
    this.thumbnail,
    this.sizeBytes,
    this.sizeFormatted,
  });
}

class TeraBoxResolveResult {
  final bool success;
  final bool requiresVerification;
  final String? errorMessage;
  final List<TeraBoxFile> files;
  final String originalUrl;

  TeraBoxResolveResult({
    required this.success,
    this.requiresVerification = false,
    this.errorMessage,
    this.files = const [],
    required this.originalUrl,
  });

  TeraBoxFile? get primaryFile => files.isNotEmpty ? files.first : null;
}

class TeraBoxService {
  static final TeraBoxService instance = TeraBoxService._();
  TeraBoxService._();

  static const List<String> supportedDomains = [
    'terabox.com',
    'terabox.app',
    '1024tera.com',
    '1024terabox.com',
    'teraboxapp.com',
    'teraboxlink.com',
    'terasharelink.com',
    'terasharefile.com',
    'mirrobox.com',
    'nephobox.com',
    'freeterabox.com',
    '4funbox.com',
    'momerybox.com',
  ];

  static bool isTeraBoxUrl(String url) {
    final lower = url.toLowerCase();
    return supportedDomains.any((domain) => lower.contains(domain));
  }

  static String? extractSurl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('surl')) {
        return uri.queryParameters['surl'];
      }
      final segments = uri.pathSegments;
      final sIndex = segments.indexOf('s');
      if (sIndex != -1 && sIndex + 1 < segments.length) {
        return segments[sIndex + 1];
      }
      final sharingIndex = segments.indexOf('sharing');
      if (sharingIndex != -1 && uri.queryParameters.containsKey('surl')) {
        return uri.queryParameters['surl'];
      }
      // Check last segment
      if (segments.isNotEmpty) {
        final last = segments.last;
        if (last.length >= 10 && !last.contains('.')) {
          return last;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Attempts to resolve a TeraBox link to direct download URLs
  Future<TeraBoxResolveResult> resolve(String url) async {
    final cleanUrl = url.trim();
    final surl = extractSurl(cleanUrl);
    debugPrint('Resolving TeraBox URL: $cleanUrl (surl: $surl)');

    // 1. Try public resolver endpoint 1: tbx-proxy
    if (surl != null && surl.isNotEmpty) {
      try {
        final res = await _tryTbxProxy(surl, cleanUrl);
        if (res != null && res.success) return res;
      } catch (e) {
        debugPrint('TeraBox Proxy error: $e');
      }
    }

    // 2. Try resolver endpoint 2: teraboxdl / api
    try {
      final res = await _tryPublicApi(cleanUrl);
      if (res != null && res.success) return res;
    } catch (e) {
      debugPrint('TeraBox Public API error: $e');
    }

    // 3. Try direct ndus cookie resolution if configured by user
    final userCookie = SettingsService.instance.teraboxCookie;
    if (userCookie.isNotEmpty && surl != null) {
      try {
        final res = await _tryUserCookie(surl, userCookie, cleanUrl);
        if (res != null && res.success) return res;
      } catch (e) {
        debugPrint('TeraBox Cookie resolver error: $e');
      }
    }

    // 4. Default: Verification required / Protected link
    return TeraBoxResolveResult(
      success: false,
      requiresVerification: true,
      originalUrl: cleanUrl,
      errorMessage:
          'TeraBox requires security verification (Cloudflare/Login) or is private.',
    );
  }

  Future<TeraBoxResolveResult?> _tryTbxProxy(String surl, String originalUrl) async {
    final cleanSurl = surl.startsWith('1') ? surl.substring(1) : surl;
    final uri = Uri.parse(
        'https://tbx-proxy.shakir-ansarii075.workers.dev/?mode=resolve&surl=$cleanSurl');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['list'] is List) {
        final list = data['list'] as List;
        final files = <TeraBoxFile>[];
        for (final item in list) {
          if (item is Map) {
            final dlink = item['dlink']?.toString() ??
                item['download_link']?.toString() ??
                '';
            if (dlink.isNotEmpty) {
              files.add(TeraBoxFile(
                title: item['server_filename']?.toString() ?? 'TeraBox File',
                downloadUrl: dlink,
                fastDownloadUrl: item['fast_download_link']?.toString(),
                streamUrl: item['stream_url']?.toString(),
                thumbnail: item['thumbs']?['url3']?.toString() ??
                    item['thumbnail']?.toString(),
                sizeBytes: int.tryParse(item['size']?.toString() ?? ''),
              ));
            }
          }
        }
        if (files.isNotEmpty) {
          return TeraBoxResolveResult(
            success: true,
            files: files,
            originalUrl: originalUrl,
          );
        }
      }
    }
    return null;
  }

  Future<TeraBoxResolveResult?> _tryPublicApi(String url) async {
    final encoded = Uri.encodeComponent(url);
    final apis = [
      'https://teraboxdl.site/api?url=$encoded',
      'https://alphaapis.org/terabox/v3/dl?url=$encoded',
    ];

    for (final api in apis) {
      try {
        final response =
            await http.get(Uri.parse(api)).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map) {
            final dlink = data['download_link']?.toString() ??
                data['dlink']?.toString() ??
                data['downloadUrl']?.toString() ??
                data['url']?.toString() ??
                (data['data'] is Map ? data['data']['downloadLink']?.toString() : null);

            if (dlink != null && dlink.startsWith('http')) {
              return TeraBoxResolveResult(
                success: true,
                files: [
                  TeraBoxFile(
                    title: data['title']?.toString() ??
                        data['filename']?.toString() ??
                        data['fileName']?.toString() ??
                        'TeraBox Media',
                    downloadUrl: dlink,
                    thumbnail: data['thumbnail']?.toString() ??
                        data['thumbs']?.toString(),
                  ),
                ],
                originalUrl: url,
              );
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<TeraBoxResolveResult?> _tryUserCookie(
      String surl, String ndus, String originalUrl) async {
    final cleanSurl = surl.startsWith('1') ? surl.substring(1) : surl;
    final pageUri =
        Uri.parse('https://dm.terabox.app/sharing/link?surl=$cleanSurl');
    final pageResp = await http.get(pageUri, headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Cookie': 'ndus=$ndus',
    }).timeout(const Duration(seconds: 8));

    if (pageResp.statusCode == 200) {
      final match = RegExp(r'fn%28%22(.*?)%22%29').firstMatch(pageResp.body);
      if (match != null) {
        final jsToken = match.group(1);
        final listUri = Uri.parse(
            'https://dm.terabox.app/share/list?app_id=250528&jsToken=$jsToken&shorturl=$cleanSurl&root=1');
        final listResp = await http.get(listUri, headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': pageUri.toString(),
          'Cookie': 'ndus=$ndus',
        }).timeout(const Duration(seconds: 8));

        if (listResp.statusCode == 200) {
          final data = jsonDecode(listResp.body);
          if (data is Map && data['errno'] == 0 && data['list'] is List) {
            final files = <TeraBoxFile>[];
            for (final item in data['list'] as List) {
              if (item is Map) {
                final dlink = item['dlink']?.toString() ?? '';
                if (dlink.isNotEmpty) {
                  files.add(TeraBoxFile(
                    title: item['server_filename']?.toString() ?? 'TeraBox File',
                    downloadUrl: dlink,
                    sizeBytes: int.tryParse(item['size']?.toString() ?? ''),
                  ));
                }
              }
            }
            if (files.isNotEmpty) {
              return TeraBoxResolveResult(
                success: true,
                files: files,
                originalUrl: originalUrl,
              );
            }
          }
        }
      }
    }
    return null;
  }
}
