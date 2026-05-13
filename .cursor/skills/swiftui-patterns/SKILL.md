---
name: swiftui-patterns
description: SwiftUI and AppKit frontend patterns for macOS notch app development. Use when building UI components, creating views, handling animations, managing view state, working with SwiftUI modifiers, layout, drag-and-drop, or when the user mentions UI, views, layout, animation, design, or SwiftUI.
---

# Frontend Patterns - SwiftUI/AppKit macOS

## SwiftUI View Structure

Follow the existing MVVM pattern:

```swift
struct MyComponent: View {
    @ObservedObject var viewModel: MyViewModel
    @Default(.someSetting) var someSetting  // Defaults package for settings

    var body: some View {
        // Keep body focused, extract subviews for complexity
    }
}
```

- Use `@Default(.key)` property wrapper for reading user settings (from the Defaults package)
- Use `@ObservedObject` for ViewModels passed from parent views
- Use `@StateObject` only when the view owns the object's lifecycle
- Use `@EnvironmentObject` for shared singletons like `BoringViewModel`

## Notch-Specific UI Patterns

The app renders in the macOS notch area with specific constraints:

- Views must account for the notch cutout shape
- Use `NotchState` enum (`.closed`, `.open`, `.sneakPeek`) to adapt layouts
- Animations should be smooth and non-jarring for the always-visible notch
- Respect `WindowHeightMode` for different content heights

```swift
switch viewModel.notchState {
case .closed:
    CompactNotchView()
case .open:
    ExpandedNotchView()
case .sneakPeek:
    SneakPeekView()
}
```

## Animation Patterns

- Use `withAnimation(.smooth)` for state transitions
- Leverage the Pow library for advanced effects (already a dependency)
- Keep animations under 300ms for responsive feel
- Use `.transition()` modifiers for view insertion/removal

```swift
// Existing pattern - smooth notch expansion
withAnimation(.smooth) {
    viewModel.notchState = .open
}
```

## Drag and Drop (Shelf System)

Follow the existing Shelf pattern in `components/Shelf/`:

- Use `onDrop(of:)` modifier with `UniformTypeIdentifiers`
- Create security-scoped bookmarks for dropped files
- Use `ShelfDropService` for drop handling logic
- Generate thumbnails via `ThumbnailService`

## AppKit Integration

When SwiftUI isn't sufficient, use SwiftUI Introspect (already a dependency):

```swift
.introspect(.window, on: .macOS(.v14, .v15)) { window in
    window.level = .floating
    window.collectionBehavior = [.canJoinAllSpaces]
}
```

For custom windows:
- Use `SkyLightWindow` package for notch overlay windows
- Configure `NSWindow` properties for always-on-top, click-through behavior
- Handle per-screen window management via `NSScreen` UUID tracking

## Settings UI

Settings are defined in `Constants.swift` as `Defaults.Keys`:

```swift
// Adding a new setting
extension Defaults.Keys {
    static let myNewSetting = Key<Bool>("myNewSetting", default: true)
}
```

Then use in views with `@Default(.myNewSetting) var myNewSetting`.

Settings UI lives in `SettingsView.swift` - follow existing section patterns.

## Component Organization

- Place new UI components in `components/` subdirectory
- Each major feature gets its own folder (e.g., `Shelf/`, `Webcam/`, `Onboarding/`)
- Keep ViewModels in `models/` directory
- Shared UI extensions go in `extensions/`

## Lottie Animations

Use Lottie for complex animations (already a dependency):

```swift
import Lottie

LottieView(animation: .named("animationName"))
    .looping()
    .frame(width: 40, height: 40)
```

Place animation JSON files in the appropriate bundle location.

## Accessibility

- Add accessibility labels to interactive elements
- Support VoiceOver navigation
- Respect system accessibility settings (reduce motion, increase contrast)
- Use semantic colors that adapt to system appearance
