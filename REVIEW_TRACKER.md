# Code Review Tracker

> Status: IN PROGRESS
> Last updated: 2026-02-01
> Use this file across Claude Code sessions to track which fixes are done.

---

## P0 — Fix Immediately (Crashes / Data Loss)

- [x] **P0-1: DownloadView force unwrap crash** ✓ DELETED
  - Files: ~~`boringNotch/components/Live activities/DownloadView.swift`~~
  - Resolution: Deleted the entire file — it was dead code (never instantiated, no download monitoring backend). Removed from Xcode project.

- [x] **P0-2: BoringViewCoordinator force cast crash**
  - Files: `boringNotch/BoringViewCoordinator.swift`
  - Fix: Replaced `as! Data` with `guard let rawData = notification.userInfo?.first?.value as? Data`; early return with log on missing/invalid payload.

- [x] **P0-3: AnimatedFace timer leak**
  - Files: `boringNotch/components/AnimatedFace.swift`
  - Fix: Added `@State private var blinkTimer: Timer?`, assign timer in `startBlinking()`, invalidate in `onDisappear` and at start of `startBlinking()` before creating a new one.

---

## P1 — Fix Soon (Data Races / Security)

- [x] **P1-1: Add @MainActor to MusicManager**
  - Files: `boringNotch/managers/MusicManager.swift`, `boringNotch/models/Constants.swift`
  - Fix: Added `@MainActor` to `MusicManager`. `updateIdleState` Task now uses `@MainActor [weak self]`. Removed redundant `DispatchQueue.main.async` in `fetchLyricsIfAvailable` early return. Removed `destroy()` call from `deinit` (singleton never deallocated; cleanup via `destroy()` from app lifecycle). `Constants.defaultMediaController` now returns `.nowPlaying` (deprecation handled in MusicManager at runtime).

- [x] **P1-2: Add @MainActor to BatteryStatusViewModel**
  - Files: `boringNotch/models/BatteryStatusViewModel.swift`
  - Fix: Added `@MainActor` to the class. `notifyImportanChangeStatus` Task now uses `@MainActor` so coordinator call runs on main. Observer callbacks already invoked on main by BatteryActivityManager.notifyObservers (DispatchQueue.main.async).

- [x] **P1-3: BatteryActivityManager notification queue synchronization**
  - Files: `boringNotch/managers/BatteryActivityManager.swift`
  - Fix: Added `notificationQueueLock` (NSLock). All access to `notificationQueue` and `isProcessingNotifications` is now under the lock. `enqueueNotification` and `processNextNotificationLocked()` use lock/unlock discipline so IOKit callback and main-thread delivery don’t race.

- [x] **P1-4: Protect clipboard persistence**
  - Files: `boringNotch/components/Clipboard/Services/ClipboardPersistenceService.swift`, `boringNotch/components/Clipboard/Managers/ClipboardHistoryManager.swift`
  - Fix: (1) Set restrictive POSIX permissions: directory 0700, file 0600 (owner-only). Applied on init and after each save (atomic write creates new file). (2) Added `excludedBundleIDs` set with 11 password managers (1Password, Bitwarden, LastPass, Dashlane, KeePassXC, Enpass, Keeper, NordPass, RoboForm, Keychain Access). (3) Also skip any bundle ID containing "password", "keychain", or "vault". Sensitive clipboard content is no longer captured or persisted.

- [x] **P1-5: XPC helper — add connection validation**
  - Files: `BoringNotchXPCHelper/main.swift`
  - Fix: (1) On macOS 13+, `listener.setConnectionCodeSigningRequirement("identifier \"theboringteam.boringnotch\"")` so only the main app’s code signing identity can connect; system rejects others before the delegate. (2) In `listener(_:shouldAcceptNewConnection:)`, `validateConnection(_:)` checks that the connecting process’s bundle ID (via `NSRunningApplication(processIdentifier:)`) equals `theboringteam.boringnotch`; otherwise the connection is invalidated and returns false.

---

## P2 — Fix Next (Performance / Architecture)

- [x] **P2-1: Clipboard persistence — move images out of JSON**
  - Files: `ClipboardPersistenceService.swift`, `ClipboardHistoryManager.swift`, `ClipboardItem.swift`, `ClipboardHistoryView.swift`
  - Fix: (1) Changed `ClipboardItemKind.image(Data)` to `.imageFile(String)` — images stored as separate PNG files in `~/Library/Application Support/boringNotch/Clipboard/Images/`, referenced by UUID filename. JSON now contains only metadata (~KB instead of ~133MB). (2) Added debounced save with 300ms delay via `Task.sleep`, actual write dispatched to `Task.detached(priority: .utility)` (off main thread). (3) Added `NSCache<NSString, NSImage>` (limit 20) in ClipboardHistoryManager for decoded images. (4) Removed `.prettyPrinted` from JSON encoder (also fixes P2-6). (5) Image files cleaned up on item deletion and when items exceed 50 limit.

- [x] **P2-2: ContentView — reduce @ObservedObject scope**
  - Files: `boringNotch/ContentView.swift`, `boringNotch/components/Live activities/BoringBattery.swift`
  - Fix: Removed 4 `@ObservedObject` properties from ContentView: `webcamManager`, `batteryModel`, `brightnessManager`, `volumeManager`. ContentView now subscribes to only `coordinator` and `musicManager` (which are used pervasively). Extracted battery notification section into `BatteryNotificationView` in BoringBattery.swift — it owns its own `@ObservedObject` for `BatteryStatusViewModel.shared`, so battery changes only re-evaluate that small view, not all of ContentView.

- [x] **P2-3: Split NotchHomeView.swift**
  - Files: `boringNotch/components/Notch/NotchHomeView.swift`, new files under `components/Music/`
  - Fix: Split 707-line file into 6 focused files. `NotchHomeView.swift` (63 lines) keeps only the main view. Extracted into `components/Music/`: `MusicPlayerView.swift` (MusicPlayerView + AlbumArtView), `MusicControlsView.swift` (MusicControlsView + FavoriteControlButton + Array extension), `VolumeControlView.swift`, `NoMusicPlayingView.swift` (MusicApp model + knownMusicApps + NoMusicPlayingView), `MusicSliderView.swift` (MusicSliderView + CustomSlider). All added to Xcode project. Build verified.

- [x] **P2-4: Split BoringViewCoordinator responsibilities**
  - Files: `boringNotch/BoringViewCoordinator.swift`, new files `BoringViewCoordinator+SneakPeek.swift`, `BoringViewCoordinator+ExpandingView.swift`, `managers/HUDSetupManager.swift`
  - Fix: Reduced main file from 307→168 lines. (1) Extracted `HUDSetupManager` (accessibility observer, HUD replacement observer, MediaKeyInterceptor lifecycle) into standalone `@MainActor final class` singleton. (2) Moved sneak peek methods (event handling, toggle, timer) into `BoringViewCoordinator+SneakPeek.swift` extension. (3) Moved expanding view methods (toggle, auto-hide) into `BoringViewCoordinator+ExpandingView.swift` extension. Kept @Published stored properties on main class (Swift limitation). API unchanged — all `coordinator.sneakPeek`/`coordinator.expandingView` references still work. Build verified.

- [x] **P2-5: ClipboardHistoryView — cache decoded images**
  - Resolution: Fixed as part of P2-1. Added `NSCache<NSString, NSImage>` with 20-item limit in `ClipboardHistoryManager`. View calls `manager.cachedImage(for:)` instead of decoding Data on every render.

- [x] **P2-6: Remove .prettyPrinted from clipboard JSON**
  - Resolution: Fixed as part of P2-1. Removed `.prettyPrinted` from encoder. Also, images are no longer Base64-encoded in JSON at all (stored as separate files).

- [ ] **P2-7: Encrypt clipboard persistence file**
  - Files: `boringNotch/components/Clipboard/Services/ClipboardPersistenceService.swift`
  - Issue: Even with 0600 permissions, clipboard data is plaintext. Root/admin can read it, backups capture it unencrypted, disk forensics can recover it.
  - Fix: Encrypt JSON data with CryptoKit (AES-GCM). Store encryption key in user's Keychain. Decrypt on load, encrypt on save.

- [ ] **P2-8: Add user-configurable clipboard exclusion list**
  - Files: `boringNotch/components/Clipboard/Managers/ClipboardHistoryManager.swift`, `boringNotch/models/Constants.swift`, `SettingsView.swift`
  - Issue: Hardcoded `excludedBundleIDs` cannot be extended by users. Browser built-in password managers (Chrome, Safari, Firefox) not covered.
  - Fix: Add `Defaults.Key` for user-defined excluded bundle IDs. Add UI in Settings to manage the list.

---

## P3 — Improve When Possible (Maintainability / Cleanup)

- [ ] **P3-1: Delete dead code**
  - `NotchSpaceManager.swift:13-14` — unused `eventTap` and `runLoopSource` fields
  - `MusicManager.swift:566` — unused `workItem` (declared, never assigned)
  - `MusicManager.swift:608-612 vs 638-642` — duplicate `playPause()`/`togglePlay()` methods
  - `Constants.swift:93,99` — commented-out `Defaults.Keys`
  - `ContentView.swift:190-194` — commented-out Edit button

- [ ] **P3-2: Fix naming convention violations**
  - `BoringViewCoordinator.swift:23` — `struct sneakPeek` should be `SneakPeek`
  - `BoringViewCoordinator.swift:255` — property `sneakPeek` shadows type name
  - `Constants.swift:22` — `let UUID: UUID` should be `let id: UUID`
  - `Constants.swift:15` — global `bundleIdentifier` shadows common property name

- [ ] **P3-3: VolumeManager — cleanup audio listeners**
  - Files: `boringNotch/managers/VolumeManager.swift:181-221`
  - Issue: 4 `AudioObjectAddPropertyListenerBlock` calls, zero removals, no `deinit`.
  - Fix: Store listener references, add `deinit` that calls `AudioObjectRemovePropertyListenerBlock`.

- [ ] **P3-4: Fix @ObservedObject misuse in MusicManager**
  - Files: `boringNotch/managers/MusicManager.swift:49`
  - Issue: `@ObservedObject var coordinator` in a class (not a View) — does nothing.
  - Fix: Change to `let coordinator = BoringViewCoordinator.shared` or pass as dependency.

- [ ] **P3-5: Extract AppleScript helpers**
  - Files: `SpotifyController.swift:165-168`, `AppleMusicController.swift:156-159`
  - Issue: Duplicate `executeCommand(_ command:)` helper in both controllers.
  - Fix: Extract into a shared `AppleScriptMediaController` base or protocol extension.

- [ ] **P3-6: Move Defaults.Keys closer to features**
  - Files: `boringNotch/models/Constants.swift`
  - Issue: 208-line file that every feature must modify. Merge conflict magnet.
  - Fix: Each feature defines its own `Defaults.Keys` extension (e.g., Shelf keys in Shelf module).

- [ ] **P3-7: Centralize Notification.Name definitions**
  - Files: `boringNotchApp.swift:598-604`, `Constants.swift:40-42`, `SharingStateManager.swift:12-14`
  - Issue: Notification names scattered across 3+ files.
  - Fix: Single `Notification+Extensions.swift` file.

- [ ] **P3-8: Add input sanitization to AppleScriptHelper**
  - Files: `boringNotch/helpers/AppleScriptHelper.swift:12-26`
  - Issue: No sanitization layer on raw string input. Currently safe (numeric inputs), but pattern invites future injection.
  - Fix: Add validation/escaping for string inputs before NSAppleScript execution.

- [ ] **P3-9: XML-escape URLs in webloc generation**
  - Files: `boringNotch/components/Shelf/Services/TemporaryFileStorageService.swift:232-242`
  - Issue: URL `absoluteString` interpolated into XML without escaping `&`, `<`, `>`.
  - Fix: Use `XMLElement` or manually escape special characters.

- [ ] **P3-10: Sanitize URL host used as filename**
  - Files: `boringNotch/components/Shelf/Services/TemporaryFileStorageService.swift:98-99`
  - Issue: `url.host` used directly as filename without sanitization.
  - Fix: Strip path separators and special filesystem characters.

- [ ] **P3-11: Add clipboard auto-purge setting**
  - Files: `boringNotch/components/Clipboard/Managers/ClipboardHistoryManager.swift`, `Constants.swift`, `SettingsView.swift`
  - Issue: Old clipboard items persist indefinitely (up to 50 items). A password copied months ago remains in the file.
  - Fix: Add setting for auto-purge interval (e.g., "Delete items older than 7 days"). Run purge on app launch and periodically.

- [ ] **P3-12: Add sensitive pattern detection for clipboard**
  - Files: `boringNotch/components/Clipboard/Managers/ClipboardHistoryManager.swift`
  - Issue: No content-based filtering. API keys, tokens, and high-entropy strings (likely passwords) are captured.
  - Fix: Add opt-in regex filtering for common sensitive patterns (AWS keys `AKIA...`, GitHub tokens `ghp_...`, high-entropy strings). Skip or redact matches.

- [ ] **P3-13: Add option to disable clipboard image capture**
  - Files: `boringNotch/components/Clipboard/Managers/ClipboardHistoryManager.swift`, `Constants.swift`, `SettingsView.swift`
  - Issue: Screenshots of sensitive content (bank accounts, private chats, password manager UI) are captured and persisted.
  - Fix: Add setting to disable image capture entirely, or limit image retention to shorter duration than text.

---

## Notes

- **Private API usage** (CGSSpace, CoreBrightness, DisplayServices): These are architectural decisions that prevent App Store submission. Documented as known risk, not tracked as fixable items.
- **YouTube Music HTTP**: Uses localhost only. Low practical risk but noted. Consider Unix domain socket if rearchitected.
- **No test suite**: Adding tests is a separate initiative. DI refactoring (removing hard-coded singletons) is a prerequisite.
