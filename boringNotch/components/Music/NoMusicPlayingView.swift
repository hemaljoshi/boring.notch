//
//  NoMusicPlayingView.swift
//  boringNotch
//
//  Extracted from NotchHomeView.swift
//

import AppKit
import Defaults
import SwiftUI

struct MusicApp: Identifiable {
    enum LaunchType {
        case native(bundleID: String)
        case web(url: URL, assetIcon: String)
    }
    let id: String
    let name: String
    let launchType: LaunchType
}

let knownMusicApps: [MusicApp] = [
    // Major streaming services
    MusicApp(id: "com.apple.Music", name: "Music", launchType: .native(bundleID: "com.apple.Music")),
    MusicApp(id: "com.spotify.client", name: "Spotify", launchType: .native(bundleID: "com.spotify.client")),
    MusicApp(id: "com.github.th-ch.youtube-music", name: "YT Music", launchType: .native(bundleID: "com.github.th-ch.youtube-music")),
    MusicApp(id: "com.tidal.desktop", name: "Tidal", launchType: .native(bundleID: "com.tidal.desktop")),
    MusicApp(id: "com.deezer.deezer-desktop", name: "Deezer", launchType: .native(bundleID: "com.deezer.deezer-desktop")),
    MusicApp(id: "com.amazon.music", name: "Amazon", launchType: .native(bundleID: "com.amazon.music")),
    MusicApp(id: "com.soundcloud.desktop", name: "SoundCloud", launchType: .native(bundleID: "com.soundcloud.desktop")),
    // Alternative clients
    MusicApp(id: "tv.plex.plexamp", name: "Plexamp", launchType: .native(bundleID: "tv.plex.plexamp")),
    MusicApp(id: "sh.cider.classic", name: "Cider", launchType: .native(bundleID: "sh.cider.classic")),
    // Web fallbacks
    MusicApp(id: "web.youtube.music", name: "YT Music", launchType: .web(
        url: URL(string: "https://music.youtube.com")!,
        assetIcon: "YouTubeMusic"
    )),
]

struct NoMusicPlayingView: View {
    @Default(.hiddenQuickLaunchApps) private var hiddenQuickLaunchApps

    private var installedApps: [MusicApp] {
        var result: [MusicApp] = []
        var coveredNames: Set<String> = []
        for app in knownMusicApps {
            switch app.launchType {
            case .native(let bundleID):
                if NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil {
                    result.append(app)
                    coveredNames.insert(app.name)
                }
            case .web:
                if !coveredNames.contains(app.name) {
                    result.append(app)
                }
            }
        }
        return Array(result.filter { !hiddenQuickLaunchApps.contains($0.id) }.prefix(3))
    }

    var body: some View {
        Group {
            if installedApps.isEmpty {
                fallbackView
            } else {
                quickLaunchView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fallbackView: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 28))
                .foregroundStyle(.gray.opacity(0.5))
            Text("No music playing")
                .font(.subheadline)
                .foregroundStyle(.gray.opacity(0.7))
        }
    }

    private var quickLaunchView: some View {
        VStack(spacing: 8) {
            Text("Open a music app")
                .font(.subheadline)
                .foregroundStyle(.gray.opacity(0.7))
            HStack(spacing: 14) {
                ForEach(installedApps) { app in
                    Button {
                        launchApp(app)
                    } label: {
                        VStack(spacing: 4) {
                            appIcon(for: app)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 36, height: 36)
                            Text(app.name)
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                                .frame(width: 48)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func appIcon(for app: MusicApp) -> Image {
        switch app.launchType {
        case .native(let bundleID):
            return AppIcon(for: bundleID)
        case .web(_, let assetIcon):
            return Image(assetIcon)
        }
    }

    private func launchApp(_ app: MusicApp) {
        switch app.launchType {
        case .native(let bundleID):
            let workspace = NSWorkspace.shared
            guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) else { return }
            let configuration = NSWorkspace.OpenConfiguration()
            workspace.openApplication(at: appURL, configuration: configuration, completionHandler: nil)
        case .web(let url, _):
            NSWorkspace.shared.open(url)
        }
    }
}
