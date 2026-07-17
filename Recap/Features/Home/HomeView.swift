import SwiftUI

struct HomeContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        HomeView(
            status: .ready,
            recentCards: cardStore.recentCards,
            favoriteCards: cardStore.favoriteCards,
            collectionSummaries: cardStore.collectionSummaries,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: HomeAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .startOrganizing:
            router.navigate(.cardCreationStart)
        case .openAllRecent:
            router.navigate(.allRecentCards)
        case .openCard(let id):
            router.navigate(.cardDetail(id))
        case .openArchive(let kind):
            router.selectedTab = .archive
            router.navigate(.archiveDetail(kind), in: .archive)
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

private struct HomeFrequentType: Identifiable {
    let kind: CollectionKind
    let count: Int

    var id: CollectionKind { kind }
}

struct HomeView: View {
    var status: HomeStatus = .ready
    let recentCards: [InformationCard]
    let favoriteCards: [InformationCard]
    let collectionSummaries: [CollectionSummary]
    let onAction: (HomeAction) -> Void
    let onRetry: () -> Void

    init(
        status: HomeStatus = .ready,
        recentCards: [InformationCard],
        favoriteCards: [InformationCard] = [],
        collectionSummaries: [CollectionSummary],
        onAction: @escaping (HomeAction) -> Void,
        onRetry: @escaping () -> Void = {}
    ) {
        self.status = status
        self.recentCards = recentCards
        self.favoriteCards = favoriteCards
        self.collectionSummaries = collectionSummaries
        self.onAction = onAction
        self.onRetry = onRetry
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                if status == .failed {
                    loadingFailureState
                        .padding(.top, 120)
                } else if recentCards.isEmpty {
                    emptyState
                        .padding(.top, 24)
                } else {
                    recentSection
                        .padding(.top, 18)
                    favoritesSection
                        .padding(.top, 50)
                    frequentTypesSection
                        .padding(.top, 26)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            RecapLogoText()

            Spacer()

            Button(action: openSettings) {
                RecapIconView(
                    icon: .setting,
                    size: 24,
                    color: Color.recapGray900
                )
            }
            .buttonStyle(.plain)

            Button(action: openSearch) {
                RecapIconView(icon: .search, size: 24, color: Color.recapGray900)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 36)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 158)

            RecapSearchEmptyIllustration(size: 154)

            VStack(spacing: 8) {
                Text("아직 정리된 스크린샷이 없어요")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(Color.recapGray900)
                Text("정리할 스크린샷을 불러오거나\n갤러리에서 공유해주세요")
                    .font(RecapFont.pretendard(size: 14, weight: .medium))
                    .tracking(-0.28)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.recapGray500)
            }

            RecapButton(
                title: "스크린샷 불러오기",
                style: .primary,
                size: .medium,
                action: startOrganizing
            )
            .frame(width: 155)
            .padding(.top, 12)

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity)
    }

    private var loadingFailureState: some View {
        RecapLoadFailureView(style: .home, retry: onRetry)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            RecapSectionHeader(title: "최근 정리된 스크린샷", trailingIcon: "chevron.right", action: openAllRecent)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(recentCards.prefix(3)) { card in
                        Button {
                            openCard(card.id)
                        } label: {
                            RecapHomeRecentCard(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 16)
            }
            .scrollClipDisabled()
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            RecapSectionHeader(title: "즐겨찾기", trailingIcon: "chevron.right")
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                if favoriteCards.isEmpty {
                    RecapInlineEmptyView(
                        title: "아직 즐겨찾기가 없어요",
                        message: "즐겨찾기한 스크린샷이 여기에 표시됩니다."
                    )
                } else {
                    ForEach(favoriteCards.prefix(3)) { card in
                        Button {
                            openCard(card.id)
                        } label: {
                            FavoriteRecapListCard(card: card, isStarred: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, -16)
    }

    private var frequentTypesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            RecapSectionHeader(title: "자주 저장한 유형")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 19) {
                    ForEach(homeFrequentTypes) { item in
                        Button {
                            openArchive(item.kind)
                        } label: {
                            let display = RecapPresentation.collectionDisplay(for: item.kind)
                            RecapFolderCard(
                                title: display.title,
                                count: item.count,
                                thumbnailState: .filled,
                                kind: item.kind
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 16)
            }
            .scrollClipDisabled()
        }
    }

    private var homeFrequentTypes: [HomeFrequentType] {
        [.shopping, .place, .content, .schedule].compactMap { kind in
            collectionSummaries.first(where: { $0.kind == kind }).map {
                HomeFrequentType(kind: kind, count: $0.count)
            }
        }
    }

    private func openSearch() { onAction(.search) }
    private func startOrganizing() { onAction(.startOrganizing) }
    private func openAllRecent() { onAction(.openAllRecent) }
    private func openCard(_ id: InformationCard.ID) { onAction(.openCard(id)) }
    private func openArchive(_ kind: CollectionKind) { onAction(.openArchive(kind)) }
    private func openSettings() { onAction(.openSettings) }
}

#Preview("Home with cards") {
    NavigationStack {
        HomeView(
            status: .ready,
            recentCards: SampleData.recentCards,
            favoriteCards: SampleData.cards.filter(\.isFavorite),
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home empty") {
    NavigationStack {
        HomeView(
            status: .waiting,
            recentCards: [],
            favoriteCards: [],
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home loading failed") {
    NavigationStack {
        HomeView(
            status: .failed,
            recentCards: [],
            favoriteCards: [],
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}
