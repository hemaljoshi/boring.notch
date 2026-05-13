---
name: architecture
description: Codebase architecture patterns for the Boring Notch macOS app. Use when adding new features, creating new files, understanding code organization, designing new components, refactoring, or when the user mentions architecture, structure, patterns, MVVM, coordinator, or organization.
---

# Architecture Patterns - Boring Notch

## Core Architecture: MVVM + Coordinators + Singletons

### Entry Point Flow

```
boringNotchApp.swift
  -> Creates per-screen windows (NSScreen UUID tracking)
  -> Instantiates BoringViewModel (main state)
  -> Sets up BoringViewCoordinator.shared (navigation)
  -> ContentView.swift (main UI composition)
```

### Key Singletons (accessed via `.shared`)

| Singleton | Purpose |
|-----------|---------|
| `MusicManager.shared` | Orchestrates media controllers, audio visualizer |
| `WebcamManager.shared` | Camera capture and display |
| `BatteryStatusViewModel.shared` | Battery monitoring |
| `ShelfStateViewModel.shared` | File shelf state |
| `BoringViewCoordinator.shared` | Navigation, view transitions, sneak peek |

### ViewModel Pattern

```swift
class MyFeatureViewModel: ObservableObject {
    @Published var state: FeatureState = .idle

    // Use @MainActor for UI-bound properties
    @MainActor
    func updateUI() { ... }

    // Background work with async/await
    func fetchData() async { ... }
}
```

## Media Controller System (Protocol-Based)

All music sources implement `MediaControllerProtocol`:

```swift
protocol MediaControllerProtocol {
    var isPlaying: Bool { get }
    var currentTrack: Track? { get }
    func play()
    func pause()
    func next()
    func previous()
}
```

Implementations:
- `NowPlayingController` - System Now Playing (MPMediaPlayer)
- `AppleMusicController` - Apple Music via MusicKit
- `SpotifyController` - Spotify via AppleScript bridge
- `YouTubeMusicController` - YouTube Music via web API

`MusicManager` orchestrates these and selects the active controller based on user settings (`MediaControllerType` enum).

## Adding a New Feature

1. **Create feature directory** in `components/YourFeature/`
2. **Create ViewModel** in `models/` if state management needed
3. **Add settings** in `Constants.swift` as `Defaults.Keys`
4. **Add settings UI** section in `SettingsView.swift`
5. **Integrate** into `ContentView.swift` at the appropriate notch state
6. **Add enum cases** if needed (e.g., new `ContentType` value)

## Adding a New Media Controller

1. Create implementation file in `MediaControllers/`
2. Implement `MediaControllerProtocol`
3. Add case to `MediaControllerType` enum
4. Register in `MusicManager`'s controller selection logic
5. Add setting option in `Constants.swift` and `SettingsView.swift`

## File Organization

```
boringNotch/
├── boringNotchApp.swift       # App entry point
├── ContentView.swift          # Main UI composition (~28KB)
├── animations/                # SwiftUI animation utilities
├── components/                # Feature-specific UI
│   ├── Notch/                 # Notch rendering
│   ├── Shelf/                 # File shelf (own MVVM)
│   ├── Settings/              # Settings panels
│   ├── Webcam/                # Camera mirror
│   └── Onboarding/            # First-run experience
├── enums/                     # Type definitions
├── extensions/                # Swift/AppKit extensions
├── helpers/                   # Utility functions
├── managers/                  # Singleton managers
├── MediaControllers/          # Music source implementations
├── menu/                      # Menu bar components
├── metal/                     # GPU shaders (visualizer.metal)
├── models/                    # Data models & ViewModels
├── observers/                 # Event observers
├── private/                   # Private API wrappers (CGSSpace)
├── Providers/                 # Service provider protocols
└── XPCHelperClient/           # XPC privileged helper
```

## State Management

- **Notch state**: `BoringViewModel.notchState` (`.closed`, `.open`, `.sneakPeek`)
- **Navigation**: `BoringViewCoordinator` manages `ContentType` (Home, Shelf, etc.)
- **Settings**: `Defaults` package with typed keys in `Constants.swift`
- **Reactive updates**: `@Published` + Combine for ViewModel -> View flow

## Window Management

- One window per connected display, tracked by `NSScreen` UUID
- Windows use `SkyLightWindow` for overlay behavior
- Support for display switching, lock screen visibility
- `CGSSpace` private API for space management

## XPC Helper Pattern

```
App (regular privileges)
  -> XPCHelperClient (async communication)
    -> BoringNotchXPCHelper (privileged process)
      -> Accessibility features, keyboard brightness, etc.
```

- Communication via `AsyncXPCConnection`
- Protocol defined in `BoringNotchXPCHelperProtocol`
- Helper runs as a separate privileged process

## Concurrency Model

- Use `@MainActor` for all UI-related code
- Use `async/await` for asynchronous operations
- Use `Task` for launching concurrent work from synchronous contexts
- Use actor isolation to prevent data races
- Cancel tasks properly in `deinit` or `onDisappear`
