import Observation
import SwiftUI

enum AppNavigationPath {
    static func appending(_ route: AppRoute, to path: [AppRoute]) -> [AppRoute] {
        path + [route]
    }
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: MainTab = .home
    var archiveSection: ArchiveSection = .type
    var homePath: [AppRoute] = []
    var archivePath: [AppRoute] = []

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

    func openArchive(section: ArchiveSection = .type) {
        archiveSection = section
        selectedTab = .archive
    }

    func reset(tab: MainTab) {
        setPath([], for: tab)
    }

    func returnHome() {
        selectedTab = .home
        homePath = []
    }

    func path(for tab: MainTab) -> [AppRoute] {
        switch tab {
        case .home:
            homePath
        case .archive:
            archivePath
        }
    }

    private func append(_ route: AppRoute, to tab: MainTab) {
        switch tab {
        case .home:
            homePath = AppNavigationPath.appending(route, to: homePath)
        case .archive:
            archivePath = AppNavigationPath.appending(route, to: archivePath)
        }
    }

    private func setPath(_ path: [AppRoute], for tab: MainTab) {
        switch tab {
        case .home:
            homePath = path
        case .archive:
            archivePath = path
        }
    }
}
