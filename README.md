# 🌊 RV Downloader - Personal Media Downloader

**RV Downloader** is a private, standalone Android / Flutter media downloader application engineered strictly for personal offline use. It is powered by native **yt-dlp** and **FFmpeg** running on-device, paired with an Apple iOS-inspired transparent **Liquid Glass** aesthetic and true **OLED Black** dark theme.

---

## ⚡ Core Highlights

- **Embedded yt-dlp & FFmpeg Engine**: Runs directly on Android using native JNI / Python environment. Supports links from **TeraBox**, **Instagram** (Reels/Posts), **YouTube** (Videos/Shorts), **TikTok**, **X / Twitter**, **Reddit**, **Facebook**, and thousands of extractable sites.
- **In-App yt-dlp One-Tap Updater**: When platforms alter their extraction rules, update the underlying yt-dlp engine directly from in-app Settings without reinstalling the APK.
- **Format & Quality Engine**:
  * 🌟 **Full HD (1080p)**: Best video stream merged with highest bitrate audio via FFmpeg.
  * ⚡ **High Quality (720p)**: Fast, crisp video for everyday streaming.
  * 💾 **Data Saver (360p / 480p)**: Low bandwidth, minimal storage footprint.
  * 🎵 **MP3 Audio Extraction**: Direct FFmpeg audio conversion with user-configurable bitrates (320 kbps Studio HQ, 256 kbps, 192 kbps, 128 kbps).
- **Real-Time Download Dashboard**: Live percentage progress bar, download speed (MB/s), estimated time remaining (ETA), and cancel controls.
- **Local Media Storage Manager**: Built-in library with search, file size tracking, direct playback via Android default media players, and system share sheet integration.
- **Auto-Paste & Share Sheet Receiver**: Automatically detects links from your clipboard on open or receives links directly when sharing from Instagram, YouTube, or browsers.
- **Apple iOS Liquid Glass UI**: Frosted glass blur, specular gradient highlights, tactile spring bounce feedback, and `#000000` deep OLED dark theme.

---

## 🛠️ GitHub Actions Build Workflow (No PC Required)

The repository includes a ready-to-use GitHub Actions workflow (`.github/workflows/build.yml`) that builds an installable ARM64 Android APK automatically.

### Download & Test:
1. Every push or manual workflow dispatch automatically triggers **Build RV Downloader APK**.
2. Download the ready-to-install **`RV-Downloader-arm64.apk`** from GitHub Releases or Workflow Artifacts directly onto your phone.
