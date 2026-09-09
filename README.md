# VINX ⚡

An ultra-fast, minimalist desktop media extraction and audio mastering suite built with **Flutter Desktop**, powered by **yt-dlp** and **FFmpeg**.

Designed with a high-contrast industrial monochrome aesthetic (`#FAF9F6` porcelain light / `#111111` stealth dark), real-time process telemetry, precision clipping, audiophile format transcoding, and a persistent local library vault.

---

## Features

- 🎬 **Multi-Source Media Extraction**: Inspects and downloads video/audio streams across hundreds of platforms supported by `yt-dlp` (YouTube, Twitter/X, Vimeo, SoundCloud, Reddit, etc.).
- 📑 **Batch Playlist Deck**: Flat playlist inspector with selective track checkboxes, live per-item download indicators, and automated batch sequencing.
- 🎵 **Audiophile Audio Engine**:
  - Transcode to **FLAC** (Lossless), **WAV** (Uncompressed PCM), **OPUS** (High Efficiency), **MP3** (up to 320 kbps), and **M4A / AAC**.
  - Automatic ID3 / Vorbis metadata tagging (Artist, Title, Album) and thumbnail album art embedding.
- ✂️ **Precision Time Range Trimmer**: Non-destructive start/end timestamp clipping (`hh:mm:ss`) using stream copy before disk write.
- 🎚️ **Bandwidth Throttle & Off-Peak Scheduler**:
  - Bandwidth caps: Unlimited, 500 KB/s, 1 MB/s, 2.5 MB/s, 5 MB/s, 10 MB/s.
  - Off-peak schedule delay: Immediate, +1h, +2h, +4h, +8h.
- 🗄️ **Persistent Archive Vault**:
  - Local JSON storage tracking downloaded media, file sizes, format codecs, and completion timestamps.
  - Instant search, format filter chips (*All / Video / Audio / Playlist*), and quick actions (*Open Folder*, *Play File*, *Delete from Disk*).
- 🔔 **Native Desktop Notifications**: OS-level desktop alerts via `notify-send` when downloads or batch jobs finish.
- 🎛️ **Vintage Analog & Telemetry Deck**:
  - Live animated reel spinners and retro needle VU meter responding to download activity.
  - Collapsible terminal log console capturing stdout/stderr from underlying `yt-dlp` and `ffmpeg` processes.
  - Buttery smooth animated theme toggle with spring physics.

---

## 🚀 Pre-Built Standalone Binaries (No Setup Required)

If you just want to run the app without installing Flutter or building from source:

1. Go to the [**Releases**](https://github.com/dan-seng/downloader/releases) page or download the latest automated build from [**GitHub Actions**](https://github.com/dan-seng/downloader/actions).
2. **Windows (`.exe`)**:
   - Download `VINX-windows-x64.zip`.
   - Extract the folder and double-click `video_downloader.exe`.
3. **Linux**:
   - Download `VINX-linux-x64.tar.gz`.
   - Extract and run `./video_downloader`.
4. **First Launch**:
   - If `yt-dlp` is not already installed on your system, click the **"INSTALL ENGINE"** button inside the app to automatically fetch the official standalone engine. No terminal required!

---

## Prerequisites

Before building or running the application, make sure the following system tools are installed on your system.

### 1. Engine Dependencies

`VINX` executes `yt-dlp`, `ffmpeg`, and `notify-send` directly on the host system:

- **Debian / Ubuntu / Linux Mint**:
  ```bash
  sudo apt update
  sudo apt install -y yt-dlp ffmpeg libnotify-bin
  ```

- **Fedora / RHEL**:
  ```bash
  sudo dnf install -y yt-dlp ffmpeg libnotify
  ```

- **Arch Linux / Manjaro**:
  ```bash
  sudo pacman -S yt-dlp ffmpeg libnotify
  ```

> **Tip**: For the latest YouTube extraction updates, ensure `yt-dlp` is up-to-date:
> ```bash
> yt-dlp -U
> ```

### 2. Flutter Desktop Toolchain

To build from source, install the Flutter SDK (>= 3.12.0) and Linux desktop build tools:

```bash
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
```

Verify your environment with:
```bash
flutter doctor
```

---

## Installation & Setup

### 1. Clone the Repository

```bash
git clone git@github.com:dan-seng/downloader.git
cd downloader
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Run in Development Mode

Launch the application directly on Linux desktop:

```bash
flutter run -d linux
```

---

## Building a Release Binary

To compile an optimized, standalone release executable for Linux:

```bash
flutter build linux --release
```

The compiled release bundle will be located at:
```
build/linux/x64/release/bundle/
```

### Running the Release Application

You can execute the binary directly or create a desktop shortcut:

```bash
cd build/linux/x64/release/bundle
./video_downloader
```

---

## Running Tests & Static Analysis

The project includes an extensive test suite covering unit models, services, controllers, and widget integration:

```bash
# Run all automated tests (109+ tests)
flutter test

# Run Dart code analyzer
flutter analyze
```

---

## Architecture & Code Structure

```
lib/
├── controllers/
│   └── download_controller.dart        # Main app state controller & batch coordinator
├── core/
│   └── theme/
│       └── app_theme.dart              # Custom monochrome light & dark theme palettes
├── features/
│   ├── archive/
│   │   └── presentation/
│   │       └── archive_deck.dart       # Persistent download history vault UI & filters
│   ├── downloads/
│   │   └── widgets/
│   │       └── vu_meter.dart           # Analog retro VU needle meter
│   └── home/
│       ├── presentation/
│       │   └── home_screen.dart        # Main dashboard, URL input & controls
│       └── widgets/
│           ├── reel_spinner.dart       # Cassette reel indicator
│           └── terminal_log_console.dart # Collapsible live process log console
├── models/
│   ├── audio_config.dart               # Audio codecs, bitrates, and metadata presets
│   ├── download_archive_item.dart      # Persistent archive record model
│   ├── playlist_info.dart              # Playlist & track parser
│   ├── quality_option.dart             # Video stream resolution descriptors
│   ├── speed_limit.dart                # Bandwidth throttle & schedule delay presets
│   └── time_range_clip.dart            # Non-destructive timestamp clipping range
└── services/
    ├── archive_service.dart            # Local JSON disk persistence service
    ├── download_service.dart           # yt-dlp & ffmpeg process management engine
    ├── notification_service.dart       # Linux desktop OS notification dispatcher
    ├── storage_service.dart            # Default download directory & settings storage
    └── url_validator.dart              # URL sanitation & argument injection protection
```

---

## License & Disclaimer

This software is for personal archival and educational purposes. Ensure you comply with the terms of service of the content platforms and respect intellectual property rights.
