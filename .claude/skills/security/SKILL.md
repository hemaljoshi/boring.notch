---
name: security
description: Security best practices for macOS Swift/SwiftUI apps. Use when writing secure code, reviewing security concerns, handling user data, file access, XPC communication, keychain usage, sandboxing, entitlements, code signing, or when the user mentions security, vulnerabilities, authentication, or permissions.
---

# Security Best Practices - macOS Swift/SwiftUI

## Security-Scoped Bookmarks

When accessing user files persistently across app restarts:

- Always use `bookmarkData(options: .withSecurityScope)` to create bookmarks
- Call `startAccessingSecurityScopedResource()` before access and `stopAccessingSecurityScopedResource()` when done
- Wrap file access in a `defer` block to ensure cleanup:

```swift
guard url.startAccessingSecurityScopedResource() else { return }
defer { url.stopAccessingSecurityScopedResource() }
```

- Store bookmark data securely, not raw file paths
- Handle stale bookmarks gracefully by re-requesting access

## XPC Communication Security

- Always validate XPC connection identity using `auditToken`
- Define explicit protocol interfaces (`@objc protocol`) for XPC services
- Use `NSXPCConnection.currentConnection` to verify caller identity
- Never pass unsanitized user input through XPC boundaries
- Keep the XPC helper's privileges minimal (principle of least privilege)
- Validate all data received from XPC services before use

## Private API Usage (CGSSpace, MediaRemote)

- Isolate private API calls behind protocol abstractions for easy replacement
- Add availability checks and graceful fallbacks if private APIs change
- Document which private APIs are used and why
- Be aware that private API usage may cause App Store rejection

## UserDefaults Security (Defaults Package)

- Never store sensitive data (tokens, passwords, keys) in UserDefaults
- Use Keychain Services for credentials and secrets
- Validate values read from UserDefaults before use (they can be manually edited)
- Use the typed `Defaults.Key<T>` pattern to prevent type confusion

## AppleScript Bridge Security

- Sanitize all strings interpolated into AppleScript commands to prevent injection
- Use parameterized AppleScript where possible
- Validate AppleScript return values before casting
- Handle script execution errors gracefully

```swift
// BAD - AppleScript injection risk
let script = "tell application \"Spotify\" to set sound volume to \(userInput)"

// GOOD - Validate input first
guard let volume = Int(userInput), (0...100).contains(volume) else { return }
let script = "tell application \"Spotify\" to set sound volume to \(volume)"
```

## Network Security

- Always use HTTPS (URLSession enforces ATS by default)
- Validate SSL certificates for custom URLSession configurations
- Never log sensitive request/response data
- Use `URLSession.shared` or properly configured sessions
- Set appropriate timeout intervals
- Handle network errors without exposing internal details

## YouTube Music Auth Tokens

- Store OAuth tokens in Keychain, not UserDefaults
- Implement proper token refresh flows
- Clear tokens on sign-out
- Never log tokens or include them in error reports

## Entitlements & Sandboxing

- Request only necessary entitlements
- Document why each entitlement is needed
- Test with sandboxing enabled during development
- Use temporary exceptions sparingly and document them

## Media Key Interception

- Only intercept media keys when the app is the active media controller
- Release key interception when the app is backgrounded or closed
- Respect user preferences for key interception behavior
- Handle accessibility permission gracefully with clear user messaging

## General Principles

- Follow principle of least privilege for all system access
- Validate all external input (files, network, IPC, user input)
- Use Swift's type system to enforce security invariants
- Prefer `let` over `var` to prevent unintended mutation
- Use `@MainActor` to prevent data races in UI code
- Leverage Swift concurrency's actor isolation for thread safety
