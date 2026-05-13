//
//  HUDSetupManager.swift
//  boringNotch
//
//  Extracted from BoringViewCoordinator.swift — handles HUD replacement setup,
//  accessibility authorization, and MediaKeyInterceptor lifecycle.
//

import Combine
import Defaults
import Foundation

@MainActor
final class HUDSetupManager {
    static let shared = HUDSetupManager()

    private var accessibilityObserver: Any?
    private var hudReplacementCancellable: AnyCancellable?
    private var hudEnableTask: Task<Void, Never>?

    private init() {}

    /// Call once during app startup (from BoringViewCoordinator.init or app entry point).
    func setup() {
        // Observe changes to accessibility authorization and react accordingly
        accessibilityObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name.accessibilityAuthorizationChanged,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if Defaults[.hudReplacement] {
                    await MediaKeyInterceptor.shared.start(promptIfNeeded: false)
                }
            }
        }

        // Observe changes to hudReplacement
        hudReplacementCancellable = Defaults.publisher(.hudReplacement)
            .sink { [weak self] change in
                Task { @MainActor in
                    guard let self = self else { return }

                    self.hudEnableTask?.cancel()
                    self.hudEnableTask = nil

                    if change.newValue {
                        self.hudEnableTask = Task { @MainActor in
                            let granted = await XPCHelperClient.shared.ensureAccessibilityAuthorization(promptIfNeeded: true)
                            if Task.isCancelled { return }

                            if granted {
                                await MediaKeyInterceptor.shared.start()
                            } else {
                                Defaults[.hudReplacement] = false
                            }
                        }
                    } else {
                        MediaKeyInterceptor.shared.stop()
                    }
                }
            }

        // Initial HUD state check
        Task { @MainActor in
            if Defaults[.hudReplacement] {
                let authorized = await XPCHelperClient.shared.isAccessibilityAuthorized()
                if !authorized {
                    Defaults[.hudReplacement] = false
                } else {
                    await MediaKeyInterceptor.shared.start(promptIfNeeded: false)
                }
            }
        }
    }
}
