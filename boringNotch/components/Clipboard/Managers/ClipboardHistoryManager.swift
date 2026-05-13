//
//  ClipboardHistoryManager.swift
//  boringNotch
//

import AppKit
import Combine
import Defaults

@MainActor
final class ClipboardHistoryManager: ObservableObject {
    static let shared = ClipboardHistoryManager()

    @Published private(set) var items: [ClipboardItem] = []
    private var changeCount: Int = 0
    private var pollTimer: Timer?
    private let maxItems = 50
    private var enabledCancellable: AnyCancellable?
    private var saveTask: Task<Void, Never>?

    /// Bundle IDs of password managers and sensitive apps whose clipboard content should not be captured.
    private let excludedBundleIDs: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword-osx",
        "com.agilebits.onepassword7",
        "com.1password.browser-support",
        "com.bitwarden.desktop",
        "com.lastpass.LastPass",
        "com.dashlane.Dashlane",
        "org.keepassxc.keepassxc",
        "io.enpass.Enpass",
        "com.callpod.keeperFill",
        "com.nordpass.macos.NordPass",
        "com.siber.roboform",
        "com.apple.keychainaccess",
    ]

    /// Cache for decoded images to avoid repeated disk reads
    private let imageCache = NSCache<NSString, NSImage>()

    private init() {
        imageCache.countLimit = 20
        items = ClipboardPersistenceService.shared.load()
        changeCount = NSPasteboard.general.changeCount

        enabledCancellable = Defaults.publisher(.enableClipboardHistory)
            .sink { [weak self] change in
                Task { @MainActor in
                    guard let self = self else { return }
                    if change.newValue {
                        self.startMonitoring()
                    } else {
                        self.stopMonitoring()
                    }
                }
            }

        if Defaults[.enableClipboardHistory] {
            startMonitoring()
        }
    }

    func startMonitoring() {
        guard pollTimer == nil else { return }
        changeCount = NSPasteboard.general.changeCount
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Image Cache

    func cachedImage(for item: ClipboardItem) -> NSImage? {
        guard let filename = item.imageFilename else { return nil }
        let cacheKey = filename as NSString

        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        guard let data = ClipboardPersistenceService.shared.loadImage(filename: filename),
              let image = NSImage(data: data) else { return nil }

        imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    // MARK: - Pasteboard Monitoring

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount
        guard currentCount != changeCount else { return }
        changeCount = currentCount

        let appBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        if let bundleID = appBundleID {
            if excludedBundleIDs.contains(bundleID) {
                return
            }
            let lowercased = bundleID.lowercased()
            if lowercased.contains("password") || lowercased.contains("keychain") || lowercased.contains("vault") {
                return
            }
        }

        // Try text first
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            if case .text(let existing) = items.first?.kind, existing == string {
                return
            }
            let item = ClipboardItem(id: UUID(), kind: .text(string), appBundleID: appBundleID, createdAt: Date())
            addItem(item)
            return
        }

        // Try image (PNG then TIFF)
        if let imageData = pasteboard.data(forType: .png) ?? tiffToPNGData(pasteboard.data(forType: .tiff)) {
            let cappedData = imageData.count > 2_000_000 ? downscaleImageData(imageData) : imageData

            // Deduplicate: compare against most recent image file
            if let lastFilename = items.first?.imageFilename,
               let lastData = ClipboardPersistenceService.shared.loadImage(filename: lastFilename),
               lastData == cappedData {
                return
            }

            let filename = "\(UUID().uuidString).png"
            ClipboardPersistenceService.shared.saveImage(cappedData, filename: filename)

            // Pre-populate cache
            if let nsImage = NSImage(data: cappedData) {
                imageCache.setObject(nsImage, forKey: filename as NSString)
            }

            let item = ClipboardItem(id: UUID(), kind: .imageFile(filename), appBundleID: appBundleID, createdAt: Date())
            addItem(item)
        }
    }

    // MARK: - Item Management

    private func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            let removed = Array(items.suffix(from: maxItems))
            items = Array(items.prefix(maxItems))
            // Clean up image files for removed items
            for old in removed {
                if let filename = old.imageFilename {
                    imageCache.removeObject(forKey: filename as NSString)
                    ClipboardPersistenceService.shared.deleteImage(filename: filename)
                }
            }
        }
        debounceSave()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        if let filename = item.imageFilename {
            imageCache.removeObject(forKey: filename as NSString)
            ClipboardPersistenceService.shared.deleteImage(filename: filename)
        }
        debounceSave()
    }

    func clearAll() {
        items.removeAll()
        imageCache.removeAllObjects()
        ClipboardPersistenceService.shared.deleteAllImages()
        debounceSave()
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch item.kind {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .imageFile(let filename):
            if let data = ClipboardPersistenceService.shared.loadImage(filename: filename) {
                pasteboard.setData(data, forType: .png)
            }
        }
        changeCount = pasteboard.changeCount
    }

    // MARK: - Debounced Persistence

    private func debounceSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard let self = self, !Task.isCancelled else { return }
            let snapshot = self.items
            Task.detached(priority: .utility) {
                ClipboardPersistenceService.shared.save(snapshot)
            }
        }
    }

    // MARK: - Image Helpers

    private func tiffToPNGData(_ tiffData: Data?) -> Data? {
        guard let tiffData = tiffData,
              let imageRep = NSBitmapImageRep(data: tiffData) else { return nil }
        return imageRep.representation(using: .png, properties: [:])
    }

    private func downscaleImageData(_ data: Data) -> Data {
        guard let imageRep = NSBitmapImageRep(data: data) else { return data }
        let maxDim: CGFloat = 800
        let width = CGFloat(imageRep.pixelsWide)
        let height = CGFloat(imageRep.pixelsHigh)
        let scale = min(maxDim / width, maxDim / height, 1.0)
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)
        guard let resized = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: newWidth,
            pixelsHigh: newHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return data }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: resized)
        imageRep.draw(in: NSRect(x: 0, y: 0, width: newWidth, height: newHeight))
        NSGraphicsContext.restoreGraphicsState()

        return resized.representation(using: .png, properties: [:]) ?? data
    }
}
