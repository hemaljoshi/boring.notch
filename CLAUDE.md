# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Boring Notch is a macOS app (Swift/SwiftUI) that transforms the MacBook notch into a dynamic, interactive element featuring music controls, calendar/reminders, system HUD replacements (volume/brightness), file shelf with AirDrop, webcam mirror, and battery status.

**Requirements:** macOS 14 Sonoma+, Xcode 16+

## Build Commands

```bash
# Build via command line
xcodebuild -scheme boringNotch -configuration Release build | xcpretty

# Open in Xcode (then Cmd+R to run)
open boringNotch.xcodeproj
```

There is no test suite in this project. CI runs build-only validation via GitHub Actions.

## Branch Strategy

- **`dev`** is the base branch for all code contributions (not `main`)
- Feature branches: `feature/{name}` or `fix/{name}`
- Translations go through Crowdin, not PRs

## Architecture

### Core Pattern: MVVM + Coordinators

- **`boringNotchApp.swift`** - App entry point, sets up windows per-screen
- **`BoringViewModel`** - Main view model managing notch state (open/closed/sneak peek)
- **`BoringViewCoordinator.shared`** - Navigation coordinator handling view transitions (Home, Shelf) and sneak peek animations
- **`ContentView.swift`** - Main UI composition (large file, ~28KB)

### Media Controller System (Protocol-Based)

`MediaControllerProtocol` defines the interface for all music sources. Implementations:
- `NowPlayingController` - System Now Playing (MPMediaPlayer)
- `AppleMusicController` - Apple Music via MusicKit
- `SpotifyController` - Spotify via AppleScript bridge
- `YouTubeMusicController` - YouTube Music via web API (split into Auth/Networking/Models files)

`MusicManager` orchestrates these controllers and manages the audio visualizer.

### Manager Singletons

Key singletons accessed via `.shared`: `MusicManager`, `WebcamManager`, `BatteryStatusViewModel`, `ShelfStateViewModel`, `BoringViewCoordinator`

### Settings & Configuration

- **`Constants.swift`** - All user-facing settings as `Defaults.Keys` (uses the `Defaults` package)
- **`SettingsView.swift`** - Settings UI (~73KB, largest file)
- Enums: `MediaControllerType`, `NotchState`, `ContentType`, `WindowHeightMode`, `HideNotchOption`

### Shelf System (File Management)

Complete drag-drop file system in `components/Shelf/` with its own MVVM structure:
- `ShelfStateViewModel` / `ShelfItemViewModel`
- Services: `ShelfDropService`, `ShelfPersistenceService`, `ThumbnailService`, `QuickShareService`, `QuickLookService`
- Uses security-scoped bookmarks for persistent file access

### System Integration

- **XPC Helper** (`XPCHelperClient/`) - Separate privileged process for accessibility features
- **Metal shader** (`metal/visualizer.metal`) - GPU-accelerated audio visualizer
- **`MediaKeyInterceptor`** - Global media key capture
- **`FullscreenMediaDetection`** - Detects fullscreen video playback
- **`CGSSpace.swift`** (private API) - Window space management

### Key Dependencies (SPM)

Sparkle (auto-updates), LaunchAtLogin, Defaults (UserDefaults wrapper), KeyboardShortcuts, Lottie (animations), MediaRemoteAdapter (Now Playing), AsyncXPCConnection, MacroVisionKit (screen recording detection), SkyLightWindow

### Window Management

The app creates one notch window per connected display, tracked by screen UUID (`NSScreen+UUID.swift`). Supports automatic display switching and lock screen visibility.

## Code Review Tracker

A full project review was conducted (2026-02-01). Two reference files exist at the project root:

- **`REVIEW_TRACKER.md`** — Actionable checklist of all findings (P0-P3) with checkboxes. Read this first to see what's pending.
- **`REVIEW_REPORT.md`** — Full detailed analysis with architecture narrative, code snippets, performance calculations, security deep-dives, and singleton thread-safety tables. Read this when you need context for a specific fix.

When working on fixes:
1. Read `REVIEW_TRACKER.md` to find the next pending item
2. Read the relevant section in `REVIEW_REPORT.md` for detailed context
3. Implement the fix
4. Build-verify with `xcodebuild -scheme boringNotch -configuration Debug build`
5. Mark the item `[x]` in `REVIEW_TRACKER.md`
