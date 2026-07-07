import SwiftUI

struct MainTabShellView: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .tabItem {
                let item = RecapPresentation.tabItem(for: .home)
                Label(item.title, systemImage: item.systemImage)
            }
            .tag(MainTab.home)

            NavigationStack {
                CollectionHomeView()
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .tabItem {
                let item = RecapPresentation.tabItem(for: .collection)
                Label(item.title, systemImage: item.systemImage)
            }
            .tag(MainTab.collection)

            NavigationStack {
                SettingsStubView()
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .tabItem {
                let item = RecapPresentation.tabItem(for: .myPage)
                Label(item.title, systemImage: item.systemImage)
            }
            .tag(MainTab.myPage)
        }
        .tint(RecapTheme.ColorToken.primary)
        .background(RecapTheme.ColorToken.background)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .search:
            SearchResultsView()
        case .collectionDetail(let kind):
            CollectionDetailView(kind: kind)
        case .cardDetail(let id):
            if let card = SampleData.card(id: id) {
                CardDetailView(card: card)
            } else {
                MissingCardView(cardID: id)
            }
        case .settingsDetail(let route):
            SettingsDetailStubView(route: route)
        }
    }
}

#Preview {
    MainTabShellView(selectedTab: .constant(.home))
}
