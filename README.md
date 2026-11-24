# 🌊 LiquidDL - Personal Media Downloader

**LiquidDL** is a private, standalone Android / Flutter media downloader application engineered strictly for personal offline use. It is powered by native **yt-dlp** and **FFmpeg** running on-device, paired with an Apple iOS-inspired transparent **Liquid Glass** aesthetic and true **OLED Black** dark theme.

---

## ⚡ Core Highlights

- **Embedded yt-dlp & FFmpeg Engine**: Runs directly on Android using native JNI / Python environment. Supports links from **TeraBox**, **Instagram** (Reels/Posts), **YouTube** (Videos/Shorts), **TikTok**, **X / Twitter**, **Reddit**, **Facebook**, and thousands of extractable sites.
- **In-App yt-dlp One-Tap Updater**: When platforms alter their extraction rules, update the underlying yt-dlp engine directly from in-app Settings without reinstalling the APK.
- **Format & Quality Engine**:
  - 🌟 **Full HD (1080p)**: Best video stream merged with highest bitrate audio via FFmpeg.
  - ⚡ **High Quality (720p)**: Fast, crisp video for everyday streaming.
  - 💾 **Data Saver (360p / 480p)**: Low bandwidth, minimal storage footprint.
  - 🎵 **MP3 Audio Extraction**: Direct FFmpeg audio conversion with user-configurable bitrates (320 kbps Studio HQ, 256 kbps, 192 kbps, 128 kbps).
- **Real-Time Download Dashboard**: Live percentage progress bar, download speed (MB/s), estimated time remaining (ETA), and cancel controls.
- **Local Media Storage Manager**: Built-in library with search, file size tracking, direct playback via Android default media players, and system share sheet integration.
- **Auto-Paste & Share Sheet Receiver**: Automatically detects links from your clipboard on open or receives links directly when sharing from Instagram, YouTube, or browsers.
- **Apple iOS Liquid Glass UI**: Frosted glass blur, specular gradient highlights, tactile spring bounce feedback, and `#000000` deep OLED dark theme.

---

## 🛠️ GitHub Actions Build Workflow (No PC Required)

The repository includes a ready-to-use GitHub Actions workflow (`.github/workflows/build.yml`) that builds an installable ARM64 Android APK automatically.

### How to Build Your APK:
1. Push this folder to your GitHub repository (e.g. `liquid-dl`).
2. Go to the **Actions** tab on your GitHub repository.
3. Select **Build LiquidDL APK** and tap **Run workflow** (or simply push a commit).
4. When the build finishes, download the **`LiquidDL-arm64.apk`** from the Workflow Artifacts or Releases page directly onto your phone and install it!

---

## 📁 Project Architecture

```
liquid_downloader/
├── .github/workflows/build.yml     # Automated GitHub Actions APK compiler
├── android_overrides/              # Native Android manifests, Kotlin bridge, and signing keys
│   ├── AndroidManifest.xml         # Storage permissions, FileProvider, native library extraction
│   ├── MainActivity.kt             # yt-dlp & FFmpeg MethodChannel & EventChannel bridge
│   ├── patch_android.py            # Automatic build.gradle configuration script
│   ├── mirror.gradle               # Reliable maven repository mirror fallbacks
│   └── keystore/release.jks        # Permanent release keystore for APK signing
├── lib/
│   ├── main.dart                   # Root container with floating Liquid Glass navigation
│   ├── models/
│   │   ├── download_task.dart      # Download queue task representation
│   │   └── media_info.dart         # Video metadata & format representation
│   ├── screens/
│   │   ├── home_screen.dart        # Main Downloader Hub & Live Queue
│   │   ├── library_screen.dart     # Offline Media Storage Manager & Player
│   │   └── settings_screen.dart    # yt-dlp Updater & Quality Preferences
│   ├── services/
│   │   ├── native_downloader_service.dart # MethodChannel / EventChannel controller
│   │   ├── settings_service.dart          # Persistent user settings
│   │   └── storage_service.dart           # Local file scanner & disk space tracker
│   ├── utils/
│   │   ├── file_utils.dart         # File size & time formatters
│   │   └── url_detector.dart       # Platform classifier (TeraBox, IG, YT, etc.)
│   └── widgets/
│       ├── download_task_card.dart # Active & completed download card
│       ├── format_selector_sheet.dart # Quality & MP3 bitrate bottom sheet
│       ├── liquid_button.dart      # iOS spring bounce tactile button
│       ├── liquid_glass_card.dart  # Frosted glass container with specular borders
│       └── liquid_text_field.dart  # Glass URL input with auto-paste
└── pubspec.yaml
```

---

## 🔒 Privacy Notice
This software is intended strictly for private personal use and archiving of legally accessible personal media.
