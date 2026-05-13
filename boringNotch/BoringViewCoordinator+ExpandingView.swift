//
//  BoringViewCoordinator+ExpandingView.swift
//  boringNotch
//
//  Extracted from BoringViewCoordinator.swift — expanding view toggle and auto-hide logic.
//

import SwiftUI

extension BoringViewCoordinator {
    func toggleExpandingView(
        status: Bool,
        type: SneakContentType,
        value: CGFloat = 0,
        browser: BrowserType = .chromium
    ) {
        Task { @MainActor in
            withAnimation(.smooth) {
                self.expandingView.show = status
                self.expandingView.type = type
                self.expandingView.value = value
                self.expandingView.browser = browser
            }
        }
    }

    func scheduleExpandingViewHide() {
        expandingViewTask?.cancel()
        let duration: TimeInterval = (expandingView.type == .download ? 2 : 3)
        let currentType = expandingView.type
        expandingViewTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self = self, !Task.isCancelled else { return }
            self.toggleExpandingView(status: false, type: currentType)
        }
    }
}
