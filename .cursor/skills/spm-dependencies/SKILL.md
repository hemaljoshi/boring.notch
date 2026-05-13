---
name: spm-dependencies
description: Dependency management best practices for Swift Package Manager (SPM) in the Boring Notch macOS project. Use when adding, updating, or removing dependencies, resolving package conflicts, or when the user mentions packages, SPM, dependencies, libraries, or third-party code.
---

# Dependency Management - Swift Package Manager

## Current Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| AsyncXPCConnection | 1.3.0 | XPC inter-process communication |
| Defaults | 9.0.6 | Type-safe UserDefaults wrapper |
| KeyboardShortcuts | 2.4.0 | Global hotkey registration |
| LaunchAtLogin-Modern | 1.1.0 | Login item management |
| Lottie-SPM | 4.5.2 | JSON-based animations |
| MacroVisionKit | 0.2.0 | Screen recording detection |
| Pow | 1.0.5 | Advanced SwiftUI animations |
| SkyLightWindow | 1.0.0 | Custom window management |
| Sparkle | 2.8.0 | Auto-update framework |
| Swift Collections | 1.3.0 | Extended data structures |
| SwiftUI Introspect | 1.3.0 | Access underlying AppKit views |

Custom framework: `MediaRemoteAdapter.framework` (bundled, not SPM)

## Adding New Dependencies

1. Add via Xcode: File > Add Package Dependencies
2. Or edit the project's package dependencies in the `.xcodeproj`
3. Pin to specific versions (not ranges) for reproducible builds
4. Update `Package.resolved` and commit it

## Guidelines

- **Prefer Apple frameworks** over third-party when functionality overlaps
- **Evaluate maintenance status** before adding new dependencies (last commit, open issues, Swift version support)
- **Minimize dependency count** - each dependency adds build time and potential breakage
- **Use exact version pinning** for stability
- **Check license compatibility** - this project should avoid copyleft licenses
- **Audit transitive dependencies** - check what each package pulls in

## Updating Dependencies

```bash
# Resolve packages
xcodebuild -resolvePackageDependencies

# Update specific package in Xcode
# File > Packages > Update to Latest Package Versions
```

- Test thoroughly after updates, especially for Sparkle (update mechanism) and SkyLightWindow (window behavior)
- Check changelogs for breaking changes
- Update one package at a time to isolate issues

## MediaRemoteAdapter Framework

This is a bundled framework (not SPM):
- Located at `mediaremote-adapter/MediaRemoteAdapter.framework`
- Provides access to the private MediaRemote API
- Must be embedded in the app bundle
- Cannot be updated via SPM - requires manual framework replacement

## Build Dependencies (CI/CD)

- `xcpretty` - Xcode output formatting (Ruby gem)
- `dmgbuild` - DMG creation (Python package, installed in venv)
- `semver` - Version parsing (Python package)
- `extract_version.py` - Custom build script

These are not Swift dependencies but are needed for the build pipeline.
