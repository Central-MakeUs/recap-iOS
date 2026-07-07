import SwiftUI

struct AppShellView: View {
    let router: AppRouter
    let cardStore: RecapCardStore

    var body: some View {
        TabView(selection: selectedTab) {
            tabStack(for: .home) {
                HomeContainerView()
            }
            .tabItem {
                let item = RecapPresentation.tabItem(for: .home)
                Label(item.title, systemImage: item.systemImage)
            }
            .tag(MainTab.home)

            tabStack(for: .organize) {
                OrganizeContainerView()
            }
            .tabItem {
                let item = RecapPresentation.tabItem(for: .organize)
                Label(item.title, systemImage: item.systemImage)
            }
            .tag(MainTab.organize)

            tabStack(for: .archive) {
                CollectionHomeContainerView()
            }
            .tabItem {
                let item = RecapPresentation.tabItem(for: .archive)
                Label(item.title, systemImage: item.systemImage)
            }
            .tag(MainTab.archive)
        }
        .withAppPresentations(router: router, cardStore: cardStore)
        .tint(RecapTheme.ColorToken.primary)
        .background(RecapTheme.ColorToken.background)
        .environment(router)
        .environment(cardStore)
    }

    @ViewBuilder
    private func tabStack<Content: View>(
        for tab: MainTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack(path: router.binding(for: tab)) {
            content()
                .withAppNavigationDestinations()
        }
    }

    private var selectedTab: Binding<MainTab> {
        Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        )
    }
}

#Preview {
    AppShellView(
        router: AppRouter(),
        cardStore: PreviewStores.recapCardStore()
    )
}
