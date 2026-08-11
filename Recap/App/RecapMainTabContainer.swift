import Observation
import SwiftUI

@MainActor
@Observable
final class RecapMainTabChromeState {
    private(set) var contentVisibility: [MainTab: Bool] = [:]

    func setVisible(_ isVisible: Bool, for tab: MainTab) {
        contentVisibility[tab] = isVisible
    }

    func reset(for tab: MainTab) {
        contentVisibility[tab] = nil
    }
}

struct RecapMainTabContainer: View {
    let router: AppRouter
    let cardStore: RecapCardStore
    let homeSummaryLoader: any HomeSummaryLoading
    let archiveLoader: any ArchiveLoading
    let searchLoader: any SearchLoading
    let captureService: any CaptureServing
    let userAccountService: any UserAccountServing
    let cardCreationProcessor: any CardCreationProcessing
    let cardDataInvalidationCenter: CardDataInvalidationCenter
    let organizeNotificationStore: OrganizeNotificationStore
    let onUpload: () -> Void
    let onCardDeleted: () -> Void
    let onAccountWithdrawalCompleted: () -> Void
    let onAccountDataDeleted: () -> Void

    @State private var chromeState = RecapMainTabChromeState()

    var body: some View {
        @Bindable var router = router

        GeometryReader { geometry in
            TabView(selection: $router.selectedTab) {
                Tab("홈", image: "RecapTabHomeIcon", value: MainTab.home) {
                    tabStack(for: .home) {
                        HomeContainerView(
                            summaryLoader: homeSummaryLoader,
                            invalidationCenter: cardDataInvalidationCenter
                        )
                    }
                    .toolbar(.hidden, for: .tabBar)
                }

                Tab("보관함", image: "RecapTabArchiveIcon", value: MainTab.archive) {
                    tabStack(for: .archive) {
                        CollectionHomeContainerView(
                            loader: archiveLoader,
                            invalidationCenter: cardDataInvalidationCenter
                        )
                    }
                    .toolbar(.hidden, for: .tabBar)
                }
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                if showsBottomChrome {
                    RecapMainTabBarToolbar(
                        selection: router.selectedTab,
                        onSelect: router.switchTo,
                        onUpload: onUpload,
                        height: RecapMainTabBarMetrics.contentHeight(
                            bottomSafeAreaInset: geometry.safeAreaInsets.bottom
                        )
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .scrollEdgeEffectHidden(true, for: .bottom)
            .animation(.easeInOut(duration: 0.18), value: showsBottomChrome)
        }
        .environment(chromeState)
    }

    @ViewBuilder
    private func tabStack<Content: View>(
        for tab: MainTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack(path: router.binding(for: tab)) {
            content()
                .withAppNavigationDestinations(
                    cardStore: cardStore,
                    homeSummaryLoader: homeSummaryLoader,
                    archiveLoader: archiveLoader,
                    searchLoader: searchLoader,
                    captureService: captureService,
                    userAccountService: userAccountService,
                    cardCreationProcessor: cardCreationProcessor,
                    cardDataInvalidationCenter: cardDataInvalidationCenter,
                    organizeNotificationStore: organizeNotificationStore,
                    onCardDeleted: onCardDeleted,
                    onAccountWithdrawalCompleted: onAccountWithdrawalCompleted,
                    onAccountDataDeleted: onAccountDataDeleted
                )
        }
    }

    private var showsBottomChrome: Bool {
        RecapMainTabChromePolicy.showsChrome(
            routeAllowsChrome: RecapMainTabChromePolicy.routeAllowsChrome(
                for: router.path(for: router.selectedTab).last
            ),
            contentVisibility: chromeState.contentVisibility,
            selectedTab: router.selectedTab
        )
    }
}

enum RecapMainTabChromePolicy {
    static func routeAllowsChrome(for route: AppRoute?) -> Bool {
        switch route {
        case nil:
            true
        case .search, .allRecentCards, .archiveFavorites, .archiveDetail,
             .remoteCardDetail, .cardCreationStart, .settings:
            false
        }
    }

    static func showsChrome(
        routeAllowsChrome: Bool,
        contentVisibility: [MainTab: Bool],
        selectedTab: MainTab
    ) -> Bool {
        routeAllowsChrome && contentVisibility[selectedTab, default: true]
    }
}

struct RecapMainTabBarToolbar: View {
    let selection: MainTab
    let onSelect: (MainTab) -> Void
    let onUpload: () -> Void
    var height = RecapMainTabBarMetrics.height

    var body: some View {
        HStack(spacing: 0) {
            RecapTabSelector(
                selection: selection,
                onSelect: onSelect
            )

            Spacer(minLength: 0)

            RecapUploadButton(action: onUpload)
        }
        .padding(.horizontal, RecapMainTabBarMetrics.horizontalPadding)
        .padding(.top, RecapMainTabBarMetrics.topPadding)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
    }
}

#if DEBUG
#Preview("메인 탭 바와 업로드") {
    @Previewable @State var selection = MainTab.home

    RecapMainTabBarToolbar(
        selection: selection,
        onSelect: { selection = $0 },
        onUpload: {}
    )
    .background(Color.recapGray50)
}
#endif
