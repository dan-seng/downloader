# Video Downloader — Desktop Application

## 1. Project Overview

Build a professional, cross-platform desktop video downloader application for:

* Windows
* Linux

The application must be a **real desktop application**, not a web application or browser-based downloader.

### Core technology

* **Flutter + Dart** — desktop UI and application
* **yt-dlp** — video information and download engine
* **FFmpeg** — media processing, merging video/audio, and format conversion when required

The end user should only install our application.

The user must NOT be required to manually install:

* Python
* yt-dlp
* FFmpeg
* Node.js
* Any other runtime dependency

The required binaries will eventually be bundled with the application.

---

# 2. Product Goal

The application should provide a clean and modern desktop experience where a user can:

1. Paste a supported video URL.
2. Analyze the URL.
3. See video information.
4. Select video/audio quality and format.
5. Select a download location.
6. Start the download.
7. See real-time progress.
8. Cancel downloads.
9. View completed downloads.
10. Manage download history.

The application should feel like a polished desktop product rather than a developer tool.

---

# 3. Initial MVP

Do NOT attempt to implement every feature immediately.

The first working vertical slice should be:

```text
Paste URL
    ↓
Analyze
    ↓
yt-dlp
    ↓
Video metadata
    ↓
Display information
    ↓
Select quality
    ↓
Download
    ↓
Progress
    ↓
Completed file
```

The MVP should prioritize reliability and clean architecture over excessive features.

---

# 4. Architecture

Use a layered and feature-oriented architecture.

Recommended structure:

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── theme/
│
├── models/
│   ├── video_info.dart
│   ├── video_format.dart
│   └── download_task.dart
│
├── services/
│   ├── ytdlp_service.dart
│   ├── ffmpeg_service.dart
│   ├── download_service.dart
│   └── process_service.dart
│
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   └── widgets/
│   │
│   ├── downloads/
│   │   ├── presentation/
│   │   └── widgets/
│   │
│   └── settings/
│       ├── presentation/
│       └── widgets/
│
├── controllers/
│   ├── video_controller.dart
│   └── download_controller.dart
│
└── main.dart

assets/
└── binaries/
    ├── linux/
    │   ├── yt-dlp
    │   └── ffmpeg
    │
    └── windows/
        ├── yt-dlp.exe
        └── ffmpeg.exe
```

The exact structure can be adjusted if there is a strong architectural reason.

Do not introduce unnecessary complexity.

---

# 5. Separation of Responsibilities

The Flutter UI must NOT directly execute yt-dlp commands.

Use this flow:

```text
UI
 ↓
Controller
 ↓
Service
 ↓
Process Manager
 ↓
yt-dlp
```

For example:

```text
HomeScreen
    ↓
VideoController
    ↓
YtDlpService
    ↓
ProcessService
    ↓
yt-dlp
```

This separation is important because we will later replace the development yt-dlp executable with the bundled production executable.

---

# 6. yt-dlp Integration

During development, yt-dlp may be accessed from the system PATH.

Example:

```dart
Process.start(
  'yt-dlp',
  arguments,
);
```

However, production MUST NOT depend on the user having yt-dlp installed.

Eventually the application should resolve the executable dynamically:

```text
Development:
system PATH → yt-dlp

Production:
application bundle → yt-dlp
```

Do not hardcode absolute paths such as:

```text
/home/user/yt-dlp
C:\Users\User\yt-dlp.exe
```

The application must work for different users and installation locations.

---

# 7. FFmpeg Integration

FFmpeg should also eventually be bundled with the application.

The architecture should allow:

```text
yt-dlp
   ↓
FFmpeg
   ↓
Final media file
```

yt-dlp should be configured to use the bundled FFmpeg executable when necessary.

Do not assume FFmpeg is globally installed on the user's computer.

---

# 8. Video Information Model

Do not pass raw:

```dart
Map<String, dynamic>
```

through the entire application.

Parse yt-dlp's JSON response into strongly typed models.

Example:

```dart
class VideoInfo {
  final String id;
  final String title;
  final String? thumbnail;
  final Duration? duration;
  final String? uploader;
  final List<VideoFormat> formats;

  const VideoInfo({
    required this.id,
    required this.title,
    this.thumbnail,
    this.duration,
    this.uploader,
    required this.formats,
  });
}
```

Formats should have their own model:

```dart
class VideoFormat {
  final String formatId;
  final String? extension;
  final int? width;
  final int? height;
  final double? fps;
  final String? videoCodec;
  final String? audioCodec;
  final int? fileSize;

  const VideoFormat({
    required this.formatId,
    this.extension,
    this.width,
    this.height,
    this.fps,
    this.videoCodec,
    this.audioCodec,
    this.fileSize,
  });
}
```

The models can evolve as the application develops.

---

# 9. Download Architecture

Downloads should be represented by a model.

Example:

```dart
enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String url;
  final String title;

  DownloadStatus status;

  double progress;
  double? speed;
  Duration? eta;

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.speed,
    this.eta,
  });
}
```

The download system should eventually support:

* Queueing
* Progress tracking
* Cancellation
* Multiple downloads
* Error handling
* Completion events

Do not implement concurrent downloading until the basic single-download flow is stable.

---

# 10. Progress Tracking

The application should not wait for the entire yt-dlp process to finish before updating the UI.

Use yt-dlp's machine-readable/newline output where appropriate and parse progress information.

The UI should be able to display:

```text
Downloading...

██████████████░░░░░░ 72%

72%
8.4 MB/s
ETA: 00:31
```

The implementation must account for:

* stdout
* stderr
* process exit codes
* process termination
* malformed/unexpected output

Never assume every line emitted by yt-dlp is a progress line.

---

# 11. Process Management

Create a reusable process abstraction.

The application should be able to:

```text
start process
    ↓
listen to stdout
    ↓
listen to stderr
    ↓
track exit code
    ↓
cancel/kill process
```

Do not scatter `Process.start()` calls throughout the UI.

Process management belongs in the service layer.

---

# 12. Error Handling

Errors should be handled gracefully.

Examples:

### Invalid URL

```text
Invalid URL
Please enter a valid supported video URL.
```

### Network failure

```text
Unable to connect.
Check your internet connection and try again.
```

### Unsupported URL

```text
This URL is not supported.
```

### Download failure

```text
Download failed.
Please try again.
```

Do not expose raw stack traces or confusing developer errors to normal users.

Developer logs may contain detailed errors.

---

# 13. UI/UX

The application should have a modern desktop interface.

Primary screens:

```text
Home
Downloads
History
Settings
```

### Home

The home screen should focus on:

* URL input
* Analyze button
* Video preview
* Title
* Duration
* Quality selection
* Format selection
* Download location
* Download button

Example conceptual layout:

```text
┌─────────────────────────────────────────────┐
│ Video Downloader                     ⚙     │
├─────────────────────────────────────────────┤
│                                             │
│ Paste video URL                             │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ https://example.com/video...            │ │
│ └─────────────────────────────────────────┘ │
│                         [ Analyze ]          │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ Thumbnail       Video Title             │ │
│ │                 Duration: 12:42         │ │
│ │                 Uploader: Example       │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ Quality: [1080p ▼]                          │
│ Format:  [MP4 ▼]                            │
│                                             │
│ Save to: ~/Downloads                 [📁]   │
│                                             │
│                  [ Download ]               │
└─────────────────────────────────────────────┘
```

Do not copy this exact visual design. Use it as a functional reference.

---

# 14. Desktop UX Requirements

The application should behave like a desktop application.

Support:

* Resizable window
* Proper window sizing
* Keyboard shortcuts where useful
* Native file/folder picker
* Native desktop notifications where appropriate
* Proper application menus where useful
* Responsive layout for different desktop resolutions
* Dark/light theme support

Avoid mobile-first UI patterns that make the desktop application feel like a stretched phone application.

---

# 15. State Management

Use a predictable state-management approach.

Do not put large amounts of application logic inside widgets.

The UI should primarily:

```text
display state
    ↓
send user actions
    ↓
react to state changes
```

Controllers/services should contain the actual application logic.

Choose a lightweight state-management solution unless complexity genuinely requires something larger.

Do not add packages simply because they are popular.

---

# 16. Dependencies

Keep dependencies minimal.

Before adding a package:

1. Determine whether Flutter/Dart already provides the functionality.
2. Determine whether the package is actually necessary.
3. Check whether it works on Windows and Linux.
4. Consider whether it is actively maintained.
5. Consider whether the package increases application complexity.

Avoid dependency bloat.

---

# 17. Security

Do not execute arbitrary shell commands constructed from user input.

Never do:

```dart
Process.run('sh', ['-c', userInput]);
```

Instead pass arguments directly to the process:

```dart
Process.start(
  executable,
  [
    '--some-option',
    userProvidedUrl,
  ],
);
```

Validate URLs before passing them to the download engine.

Never use shell interpolation for user-controlled values.

---

# 18. File Handling

Downloads should use user-selected directories.

Do not hardcode:

```text
/home/user/Downloads
```

or:

```text
C:\Users\User\Downloads
```

Use platform-appropriate APIs.

The user should be able to select a destination through a native folder picker.

---

# 19. Platform Support

The initial targets are:

```text
Windows
Linux
```

Avoid platform-specific code unless necessary.

When platform-specific behavior is unavoidable, isolate it.

For example:

```text
services/
    process_service.dart

platform/
    windows/
    linux/
```

The application should detect the current platform and select the appropriate bundled binaries.

Conceptually:

```dart
if (Platform.isWindows) {
  // use yt-dlp.exe
} else if (Platform.isLinux) {
  // use yt-dlp
}
```

Do not make assumptions about specific Linux distributions.

---

# 20. Bundled Binary Strategy

Production packaging must include:

```text
Windows:
yt-dlp.exe
ffmpeg.exe

Linux:
yt-dlp
ffmpeg
```

The application must locate the binaries relative to the installed application.

Do not require the user to configure PATH manually.

The implementation should eventually include:

```text
BinaryManager
    ↓
detect platform
    ↓
resolve application binary directory
    ↓
verify binary exists
    ↓
verify executable permissions where necessary
    ↓
return executable path
```

For Linux, account for executable permissions when packaging the binary.

---

# 21. Logging

Implement application logging.

Logs should help diagnose:

* yt-dlp failures
* FFmpeg failures
* network errors
* process errors
* unexpected states

Do not display verbose logs in the normal UI.

Consider a developer/debug log file.

Never log sensitive information unnecessarily.

---

# 22. Testing Strategy

Important components should be testable independently.

Prioritize tests for:

* URL validation
* yt-dlp JSON parsing
* VideoInfo parsing
* VideoFormat parsing
* Download state transitions
* Progress parsing
* Error handling

Services should be designed so that process execution can eventually be mocked.

---

# 23. Development Phases

Follow these phases.

## Phase 1 — Project Foundation

* Flutter Windows/Linux project
* Clean folder structure
* Theme
* Basic navigation
* Basic Home screen
* Basic Downloads screen
* Basic Settings screen

## Phase 2 — yt-dlp Integration

First use the system-installed yt-dlp during development.

Implement:

```text
URL
 ↓
YtDlpService
 ↓
yt-dlp
 ↓
JSON
 ↓
VideoInfo
```

Verify that video metadata can be displayed.

## Phase 3 — Format Selection

Display useful formats.

Allow selection based on:

* Resolution
* Extension
* Audio availability
* Video/audio combination

Do not expose every confusing yt-dlp format directly to normal users.

Convert technical format data into user-friendly choices.

Example:

```text
1080p — MP4
720p — MP4
480p — MP4
360p — MP4
Audio — MP3
```

## Phase 4 — Download Engine

Implement:

* Download
* Progress
* Speed
* ETA
* Cancellation
* Success/failure state

## Phase 5 — Bundled Binaries

Add:

```text
yt-dlp
FFmpeg
```

for:

* Windows
* Linux

Make sure users do not need to install them separately.

## Phase 6 — Download History

Persist:

* Title
* URL
* File path
* Date
* Status

Use a lightweight local persistence solution.

## Phase 7 — Download Queue

Add:

* Queue
* Pause/cancel
* Multiple tasks
* Retry failed downloads

## Phase 8 — Production Polish

Add:

* Error UX
* Notifications
* Settings
* Theme
* Application icon
* Version information
* Packaging
* Windows installer
* Linux package/AppImage

---

# 24. Coding Rules

Follow these rules throughout development.

### Keep widgets small

Avoid huge files such as:

```text
home_screen.dart → 1000+ lines
```

Break UI into reusable widgets.

### Keep business logic outside widgets

Bad:

```dart
onPressed: () {
  // 100 lines of download logic
}
```

Prefer:

```dart
onPressed: controller.startDownload,
```

### Prefer strong typing

Avoid excessive:

```dart
dynamic
Map<String, dynamic>
```

outside the JSON parsing boundary.

### Handle failures

Never silently swallow exceptions.

Avoid:

```dart
catch (_) {}
```

### Avoid premature abstraction

Do not create interfaces, repositories, factories, or layers without a real reason.

### Keep code readable

Prefer simple code over clever code.

---

# 25. Git Practices

Use meaningful commits.

Examples:

```text
feat: add video metadata service
feat: add video format selection
feat: implement download progress
feat: add download history
fix: handle yt-dlp process failure
refactor: extract download controller
```

Do not make massive commits containing unrelated changes.

---

# 26. Important Product Constraint

This application is intended to download content from supported services where the user has the right or permission to download it.

Do not design features specifically intended to bypass:

* DRM
* paywalls
* access controls
* authentication restrictions
* other technical protections

The application should rely on yt-dlp's supported functionality.

---

# 27. Current Task

Do NOT implement the entire application immediately.

Start with:

### Task 1

Inspect the existing Flutter project.

Determine:

* Current Flutter version
* Current platform support
* Existing dependencies
* Existing project structure

Then create the initial clean architecture.

### Task 2

Create:

```text
VideoInfo
VideoFormat
```

models.

### Task 3

Create:

```text
ProcessService
YtDlpService
```

### Task 4

Implement:

```text
URL
 ↓
yt-dlp --dump-single-json
 ↓
parse JSON
 ↓
VideoInfo
```

### Task 5

Create a simple temporary UI that allows:

```text
Enter URL
 ↓
Analyze
 ↓
Display title
 ↓
Display thumbnail
 ↓
Display duration
```

Do not spend significant time polishing the UI yet.

The priority is proving that the Flutter application can reliably communicate with yt-dlp.

---

# 28. Development Principle

Build the application incrementally.

After every major feature:

1. Run the application.
2. Test the feature.
3. Check for errors.
4. Fix problems.
5. Only then move to the next feature.

Do not modify large portions of the project without testing.

When making architectural decisions, explain the reasoning briefly before implementing them.

If an existing implementation conflicts with this specification, inspect it first and preserve working functionality unless there is a clear reason to change it.

The final product should be:

**Fast, simple, reliable, polished, cross-platform, and genuinely desktop-native in its user experience.**
