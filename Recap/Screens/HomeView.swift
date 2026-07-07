import SwiftUI

struct HomeContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        HomeView(
            status: .ready,
            recentCards: cardStore.recentCards,
            collectionSummaries: cardStore.collectionSummaries,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: HomeAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .openAllRecent:
            router.navigate(.allRecentCards)
        case .openCard(let id):
            router.navigate(.cardDetail(id))
        case .openArchive(let kind):
            router.navigate(.archiveDetail(kind))
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

struct HomeView: View {
    var status: HomeStatus = .ready
    let recentCards: [InformationCard]
    let collectionSummaries: [CollectionSummary]
    let onAction: (HomeAction) -> Void

    init(
        status: HomeStatus = .ready,
        recentCards: [InformationCard],
        collectionSummaries: [CollectionSummary],
        onAction: @escaping (HomeAction) -> Void
    ) {
        self.status = status
        self.recentCards = recentCards
        self.collectionSummaries = collectionSummaries
        self.onAction = onAction
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                ScreenHeader(
                    style: .logo,
                    onMenuTap: openSettings
                )

                Button(action: openSearch) {
                    SearchBar(text: .constant(""))
                        .allowsHitTesting(false)
                }
                .buttonStyle(.plain)

                StatusBanner(status: status)

                SectionHeader(
                    title: "최근 정리된 카드",
                    actionTitle: "전체 보기",
                    onAction: openAllRecent
                )

                VStack(spacing: RecapTheme.Spacing.medium) {
                    ForEach(visibleRecentCards) { card in
                        Button {
                            openCard(card.id)
                        } label: {
                            InfoCardRow(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }

                SectionHeader(title: "저장 목적별 컬렉션")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RecapTheme.Spacing.small) {
                    ForEach(collectionSummaries) { summary in
                        Button {
                            openArchive(summary.kind)
                        } label: {
                            CollectionSummaryCard(summary: summary, compact: true)
                        }
                        .buttonStyle(.plain)
                    }
                }

                ConfirmationBanner()
                    .padding(.top, RecapTheme.Spacing.small)
            }
            .padding(.horizontal, RecapTheme.Spacing.large)
            .padding(.top, RecapTheme.Spacing.large)
            .padding(.bottom, RecapTheme.Spacing.xLarge)
        }
        .background(RecapTheme.ColorToken.background)
    }

    private var visibleRecentCards: [InformationCard] {
        Array(recentCards.prefix(status == .complete ? 3 : 2))
    }

    private func openSearch() {
        onAction(.search)
    }

    private func openAllRecent() {
        onAction(.openAllRecent)
    }

    private func openCard(_ id: InformationCard.ID) {
        onAction(.openCard(id))
    }

    private func openArchive(_ kind: CollectionKind) {
        onAction(.openArchive(kind))
    }

    private func openSettings() {
        onAction(.openSettings)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            Spacer()
            if let actionTitle {
                if let onAction {
                    Button(actionTitle, action: onAction)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                        .buttonStyle(.plain)
                } else {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                }
            }
        }
    }
}

#Preview("Home ready") {
    NavigationStack {
        HomeView(
            status: .ready,
            recentCards: SampleData.recentCards,
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home processing") {
    NavigationStack {
        HomeView(
            status: .processing,
            recentCards: SampleData.recentCards,
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home complete") {
    NavigationStack {
        HomeView(
            status: .complete,
            recentCards: SampleData.recentCards,
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home waiting") {
    NavigationStack {
        HomeView(
            status: .waiting,
            recentCards: SampleData.recentCards,
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}
