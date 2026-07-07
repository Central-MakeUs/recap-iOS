import Observation
import SwiftUI

@MainActor
@Observable
final class AppRouter {
    var selectedTab: MainTab = .home
    var homePath: [AppRoute] = []
    var organizePath: [AppRoute] = []
    var archivePath: [AppRoute] = []
    var presentedSheet: AppSheetRoute?
    var presentedModal: AppModalRoute?

    func binding(for tab: MainTab) -> Binding<[AppRoute]> {
        Binding(
            get: { self.path(for: tab) },
            set: { self.setPath($0, for: tab) }
        )
    }

    func navigate(_ route: AppRoute, in tab: MainTab? = nil) {
        let targetTab = tab ?? selectedTab
        append(route, to: targetTab)
    }

    func switchTo(_ tab: MainTab) {
        selectedTab = tab
    }

    func reset(tab: MainTab) {
        setPath([], for: tab)
    }

    func presentSheet(_ sheet: AppSheetRoute) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func presentModal(_ modal: AppModalRoute) {
        presentedModal = modal
    }

    func dismissModal() {
        presentedModal = nil
    }

    func path(for tab: MainTab) -> [AppRoute] {
        switch tab {
        case .home:
            homePath
        case .organize:
            organizePath
        case .archive:
            archivePath
        }
    }

    private func append(_ route: AppRoute, to tab: MainTab) {
        switch tab {
        case .home:
            homePath.append(route)
        case .organize:
            organizePath.append(route)
        case .archive:
            archivePath.append(route)
        }
    }

    private func setPath(_ path: [AppRoute], for tab: MainTab) {
        switch tab {
        case .home:
            homePath = path
        case .organize:
            organizePath = path
        case .archive:
            archivePath = path
        }
    }
}
