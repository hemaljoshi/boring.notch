//
//  ClipboardItem.swift
//  boringNotch
//

import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ClipboardItemKind
    let appBundleID: String?
    let createdAt: Date

    enum ClipboardItemKind: Codable, Equatable {
        case text(String)
        case imageFile(String)  // filename (UUID.png), stored separately from JSON
    }

    var preview: String {
        switch kind {
        case .text(let string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 80 {
                return String(trimmed.prefix(80)) + "..."
            }
            return trimmed
        case .imageFile:
            return "Image"
        }
    }

    var imageFilename: String? {
        if case .imageFile(let filename) = kind {
            return filename
        }
        return nil
    }
}
