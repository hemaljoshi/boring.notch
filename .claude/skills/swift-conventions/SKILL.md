---
name: swift-conventions
description: Code quality standards and conventions for the Boring Notch Swift/SwiftUI macOS project. Use when writing new code, reviewing code, refactoring, or when the user mentions code quality, conventions, style, formatting, naming, best practices, or Swift idioms.
---

# Code Quality Standards - Boring Notch

## Swift Style Conventions

### Naming

- **Types**: `UpperCamelCase` - `BoringViewModel`, `ShelfStateViewModel`
- **Functions/Properties**: `lowerCamelCase` - `updateNotchState()`, `isPlaying`
- **Constants**: `lowerCamelCase` - `static let defaultHeight = 32.0`
- **Enums**: `UpperCamelCase` type, `lowerCamelCase` cases - `enum NotchState { case open, closed }`
- **Protocols**: Descriptive names, often ending in `-able`, `-ing`, or `-Protocol` - `MediaControllerProtocol`
- **Boolean properties**: Use `is`/`has`/`should` prefix - `isPlaying`, `hasNotch`, `shouldAnimate`

### File Naming

- Match the primary type name: `BoringViewModel.swift`
- Extensions: `NSScreen+UUID.swift` (Type+Extension.swift pattern)
- Group related types in feature directories

### Code Organization Within Files

```swift
// 1. Imports
import SwiftUI
import Defaults

// 2. Type declaration
class MyViewModel: ObservableObject {
    // 3. Published/public properties
    @Published var state: State = .idle

    // 4. Private properties
    private var cancellables = Set<AnyCancellable>()

    // 5. Initialization
    init() { }

    // 6. Public methods
    func doSomething() { }

    // 7. Private methods
    private func helper() { }
}
```

## Swift Best Practices

### Type Safety

- Use enums over raw strings for state (existing: `NotchState`, `ContentType`, `MediaControllerType`)
- Use `Defaults.Key<T>` for type-safe settings
- Prefer `let` over `var` - use immutable values by default
- Use optionals explicitly - avoid force-unwrapping (`!`) except for IBOutlets

### Error Handling

- Use `do/catch` for recoverable errors
- Use `guard` for early returns and unwrapping
- Log errors meaningfully, don't silently swallow them
- Use `Result` type for async operations that can fail

```swift
// Preferred guard pattern
guard let window = NSApp.mainWindow else { return }

// Preferred optional chaining
musicManager?.currentTrack?.title ?? "Unknown"
```

### Concurrency

- Mark UI-updating code with `@MainActor`
- Use structured concurrency (`async/await`) over completion handlers
- Cancel tasks in `deinit` to prevent leaks
- Use `Task { @MainActor in }` for main-thread work from background contexts

```swift
// Good pattern
@MainActor
class MyViewModel: ObservableObject {
    @Published var data: [Item] = []

    func load() {
        Task {
            let items = await fetchItems()  // runs off main
            self.data = items               // @MainActor ensures main thread
        }
    }

    nonisolated func fetchItems() async -> [Item] {
        // Background work
    }
}
```

### Combine Usage

- Store subscriptions in `Set<AnyCancellable>` with `.store(in: &cancellables)`
- Use `[weak self]` in `.sink` closures
- Chain operators for clean data flow
- Use `.removeDuplicates()` to prevent redundant updates

### SwiftUI View Guidelines

- Keep `body` computed properties focused and readable
- Extract complex subviews into separate `View` structs
- Use `@ViewBuilder` for conditional content
- Prefer composition over inheritance (SwiftUI is struct-based)

## Defaults Package Conventions

Settings follow this pattern in `Constants.swift`:

```swift
extension Defaults.Keys {
    // Group by feature with clear naming
    static let featureName_settingName = Key<Type>("featureName_settingName", default: value)
}
```

## Common Anti-Patterns to Avoid

- **God views**: Break up views over ~200 lines into subviews
- **Force unwrapping**: Use `guard let` or optional chaining instead
- **Stringly-typed code**: Use enums and typed keys
- **Massive ViewModels**: Split by feature responsibility
- **Blocking main thread**: Use `async/await` for I/O and heavy computation
- **Unused imports**: Remove imports that aren't needed
- **Magic numbers**: Use named constants or computed properties

## Commit & PR Conventions

- Branch from `dev` (not `main`) for all contributions
- Feature branches: `feature/{name}` or `fix/{name}`
- Keep commits focused on single changes
- CI runs build-only validation (no tests)
