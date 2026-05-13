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
        case image(Data)
    }

    var preview: String {
        switch kind {
        case .text(let string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 80 {
                return String(trimmed.prefix(80)) + "..."
            }
            return trimmed
        case .image:
            return "Image"
        }
    }
}
