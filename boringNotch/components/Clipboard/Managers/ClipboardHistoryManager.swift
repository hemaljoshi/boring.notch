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

    private init() {
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

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount
        guard currentCount != changeCount else { return }
        changeCount = currentCount

        let appBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        // Try text first
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let kind = ClipboardItem.ClipboardItemKind.text(string)
            if case .text(let existing) = items.first?.kind, existing == string {
                return // duplicate
            }
            let item = ClipboardItem(id: UUID(), kind: kind, appBundleID: appBundleID, createdAt: Date())
            addItem(item)
            return
        }

        // Try image (PNG then TIFF)
        if let imageData = pasteboard.data(forType: .png) ?? tiffToPNGData(pasteboard.data(forType: .tiff)) {
            // Cap at ~2MB
            let cappedData = imageData.count > 2_000_000 ? downscaleImageData(imageData) : imageData
            if case .image(let existing) = items.first?.kind, existing == cappedData {
                return // duplicate
            }
            let item = ClipboardItem(id: UUID(), kind: .image(cappedData), appBundleID: appBundleID, createdAt: Date())
            addItem(item)
        }
    }

    private func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        ClipboardPersistenceService.shared.save(items)
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        ClipboardPersistenceService.shared.save(items)
    }

    func clearAll() {
        items.removeAll()
        ClipboardPersistenceService.shared.save(items)
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch item.kind {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let data):
            pasteboard.setData(data, forType: .png)
        }
        // Update changeCount so the next poll doesn't re-capture this
        changeCount = pasteboard.changeCount
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
