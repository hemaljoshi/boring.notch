//
//  ClipboardPersistenceService.swift
//  boringNotch
//

import Foundation

final class ClipboardPersistenceService {
    static let shared = ClipboardPersistenceService()

    private let fileURL: URL
    let directoryURL: URL
    private let imagesDirectoryURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fm = FileManager.default

    private init() {
        let support = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        directoryURL = (support ?? fm.temporaryDirectory)
            .appendingPathComponent("boringNotch", isDirectory: true)
            .appendingPathComponent("Clipboard", isDirectory: true)
        imagesDirectoryURL = directoryURL.appendingPathComponent("Images", isDirectory: true)
        try? fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
        fileURL = directoryURL.appendingPathComponent("items.json")
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        setRestrictivePermissions()
    }

    // MARK: - Item Metadata (JSON)

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
            setRestrictivePermissions()
        } catch {
            print("Failed to save clipboard items: \(error.localizedDescription)")
        }
    }

    // MARK: - Image Files

    func saveImage(_ data: Data, filename: String) {
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        } catch {
            print("Failed to save clipboard image \(filename): \(error.localizedDescription)")
        }
    }

    func loadImage(filename: String) -> Data? {
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    func deleteImage(filename: String) {
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        try? fm.removeItem(at: url)
    }

    func deleteAllImages() {
        guard let files = try? fm.contentsOfDirectory(atPath: imagesDirectoryURL.path) else { return }
        for file in files {
            try? fm.removeItem(at: imagesDirectoryURL.appendingPathComponent(file))
        }
    }

    // MARK: - Permissions

    private func setRestrictivePermissions() {
        try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)
        try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: imagesDirectoryURL.path)
        if fm.fileExists(atPath: fileURL.path) {
            try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        }
    }
}
