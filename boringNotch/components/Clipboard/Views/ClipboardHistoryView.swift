//
//  ClipboardHistoryView.swift
//  boringNotch
//

import SwiftUI

struct ClipboardHistoryView: View {
    @StateObject private var manager = ClipboardHistoryManager.shared

    var body: some View {
        Group {
            if manager.items.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text("Clipboard history empty")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemsList: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(manager.items) { item in
                        ClipboardItemCard(item: item, manager: manager)
                            .onTapGesture {
                                manager.copyToClipboard(item)
                            }
                            .contextMenu {
                                Button("Copy") {
                                    manager.copyToClipboard(item)
                                }
                                Button("Delete", role: .destructive) {
                                    manager.delete(item)
                                }
                            }
                    }
                }
                .padding(.horizontal, 4)
            }

            Button {
                manager.clearAll()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear all")
        }
    }
}

private struct ClipboardItemCard: View {
    let item: ClipboardItem
    let manager: ClipboardHistoryManager
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch item.kind {
            case .text(let string):
                Text(string.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.caption2)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
            case .imageFile:
                if let nsImage = manager.cachedImage(for: item) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(4)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                if let bundleID = item.appBundleID,
                   let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                    let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 10, height: 10)
                }
                Text(item.createdAt, style: .relative)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .frame(width: 120, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .secondarySystemFill).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            Group {
                if copied {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                }
            }
        )
        .contentShape(Rectangle())
    }
}
