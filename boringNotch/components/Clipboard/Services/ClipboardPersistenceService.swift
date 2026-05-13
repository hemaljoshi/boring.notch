//
//  ClipboardPersistenceService.swift
//  boringNotch
//

import Foundation

final class ClipboardPersistenceService {
    static let shared = ClipboardPersistenceService()

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let fm = FileManager.default
        let support = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = (support ?? fm.temporaryDirectory)
            .appendingPathComponent("boringNotch", isDirectory: true)
            .appendingPathComponent("Clipboard", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("items.json")
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        if let items = try? decoder.decode([ClipboardItem].self, from: data) {
            return items
        }
        return []
    }

    func save(_ items: [ClipboardItem]) {
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save clipboard items: \(error.localizedDescription)")
        }
    }
}
