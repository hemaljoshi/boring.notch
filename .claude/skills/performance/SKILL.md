---
name: performance
description: Performance optimization guidelines for macOS Swift/SwiftUI apps with Metal shaders, audio visualization, and real-time UI updates. Use when optimizing rendering, reducing CPU/memory usage, improving animation smoothness, fixing lag, or when the user mentions performance, speed, memory, battery drain, or optimization.
---

# Performance Optimization - macOS Swift/SwiftUI with Metal

## SwiftUI View Performance

- Use `@StateObject` for owned objects, `@ObservedObject` for passed objects - never create `@StateObject` in a computed property
- Break large views into smaller subviews to minimize re-render scope
- Use `EquatableView` or custom `Equatable` conformance to prevent unnecessary redraws
- Avoid expensive computations in `body` - use cached/precomputed values
- Use `LazyVStack`/`LazyHStack` for scrollable content
- Prefer `@ViewBuilder` methods over `AnyView` type erasure

```swift
// BAD - entire view redraws on any change
struct LargeView: View {
    @ObservedObject var vm: BoringViewModel
    var body: some View {
        // 500 lines of UI
    }
}

// GOOD - only affected subviews redraw
struct LargeView: View {
    @ObservedObject var vm: BoringViewModel
    var body: some View {
        HeaderSection(state: vm.notchState)
        MediaSection(music: vm.musicManager)
        ShelfSection(shelf: vm.shelfVM)
    }
}
```

## Metal Shader Performance (visualizer.metal)

- Minimize per-fragment branching in fragment shaders
- Use `half` precision where full `float` precision isn't needed
- Batch draw calls - avoid per-frame buffer recreation
- Use triple buffering for smooth animation
- Profile with Metal System Trace in Instruments

## Audio Visualizer Optimization

- Use vDSP/Accelerate framework for FFT and signal processing
- Process audio data on a background queue, publish results to main
- Throttle visualization updates to display refresh rate (not faster)
- Use `CADisplayLink` for frame-synced updates
- Reuse audio buffers instead of allocating per callback

## Timer & Animation Management

- Cancel timers and Combine subscriptions in `deinit` / `onDisappear`
- Use `Task` with proper cancellation instead of raw timers where possible
- Debounce rapid state changes (hover events, slider updates)
- Use `withAnimation` sparingly - avoid animating expensive layout changes

```swift
// Debounce hover events
private var hoverTask: Task<Void, Never>?

func onHover(_ hovering: Bool) {
    hoverTask?.cancel()
    hoverTask = Task {
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }
        await MainActor.run { self.isHovering = hovering }
    }
}
```

## Memory Management

- Use `[weak self]` in closures that capture `self` in long-lived contexts
- Avoid retain cycles in Combine subscriptions (use `[weak self]` or `.store(in:)`)
- Release security-scoped resources promptly with `defer`
- Use `autoreleasepool` in tight loops processing Objective-C objects
- Profile with Instruments Allocations to find leaks

## Image & Thumbnail Performance

- Cache album art and file thumbnails - don't regenerate on every view update
- Use appropriate image sizes (don't load full-res when thumbnail suffices)
- Use `NSImage.preparingThumbnail(of:)` for efficient thumbnailing
- Load images asynchronously off the main thread
- Consider `NSCache` for automatic memory-pressure eviction

## Combine Pipeline Optimization

- Use `.receive(on: DispatchQueue.main)` only at the end of the pipeline
- Use `.debounce` and `.throttle` to limit high-frequency publishers
- Use `.removeDuplicates()` to prevent redundant updates
- Prefer `.sink` with `[weak self]` over `.assign(to:)` for optional self

## Multi-Display Performance

- Only update windows for visible/active displays
- Use display sleep/wake notifications to pause rendering on sleeping displays
- Share resources (album art, state) across display windows rather than duplicating

## Background Processing

- Use `Task.detached` for CPU-intensive work that doesn't need actor isolation
- Use appropriate QoS levels: `.userInteractive` for UI, `.utility` for background work
- Avoid blocking the main actor with synchronous work
- Profile with Time Profiler to identify main thread bottlenecks

## Battery Impact

- Reduce polling frequency when on battery power
- Pause non-essential animations when the app is not visible
- Use system notifications instead of polling for state changes
- Minimize wake-ups from timers and network requests
