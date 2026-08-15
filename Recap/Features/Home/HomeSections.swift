import SwiftUI

struct HomeFavoritesSection: View {
    let cards: [Card]
    let openFavorites: () -> Void
    let openCard: (Card) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 11),
        GridItem(.flexible(), spacing: 11)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RecapSectionHeader(
                title: "즐겨찾기",
                showsNavigationIndicator: true,
                action: openFavorites
            )

            Group {
                if cards.isEmpty {
                    HomeSectionEmptyMessage(
                        "아직 즐겨찾기한 스크린샷이 없어요.\n별 아이콘을 눌러 즐겨찾기해보세요!"
                    )
                    .offset(y: 5)
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 11) {
                        ForEach(cards.prefix(4)) { card in
                            Button {
                                openCard(card)
                            } label: {
                                RecapHomeFavoriteCard(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: 181, alignment: .top)
        }
    }
}

struct HomeRecentSection: View {
    let cards: [Card]
    let openAllRecent: () -> Void
    let openCard: (Card) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RecapSectionHeader(
                title: "최근 정리된 스크린샷",
                showsNavigationIndicator: true,
                action: openAllRecent
            )

            Group {
                if cards.isEmpty {
                    HomeSectionEmptyMessage("최근 정리한 스크린샷이 없어요.")
                        .offset(y: 5)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(cards.prefix(3)) { card in
                                Button {
                                    openCard(card)
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
            .frame(height: 147, alignment: .top)
        }
    }
}

struct HomeFrequentTypesSection: View {
    let summaries: [CollectionSummary]
    let openArchive: (CardCategory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RecapSectionHeader(title: "자주 저장한 유형")

            if !frequentTypes.isEmpty {
                HStack(spacing: usesDistributedSpacing ? 0 : 16) {
                    ForEach(Array(frequentTypes.enumerated()), id: \.element) { index, kind in
                        Button {
                            openArchive(kind)
                        } label: {
                            VStack(spacing: 9) {
                                RecapCategoryIcon(kind: kind, size: .large)

                                Text(RecapPresentation.collectionDisplay(for: kind).title)
                                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                                    .tracking(-0.26)
                                    .foregroundStyle(Color.recapGray700)
                                    .lineLimit(1)
                            }
                            .frame(width: 71)
                        }
                        .buttonStyle(.plain)

                        if usesDistributedSpacing, index < frequentTypes.count - 1 {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var frequentTypes: [CardCategory] {
        Array(summaries.prefix(4).map(\.kind))
    }

    private var usesDistributedSpacing: Bool {
        frequentTypes.count == 4
    }
}

private struct HomeSectionEmptyMessage: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(RecapFont.pretendard(size: 14, weight: .regular))
            .tracking(-0.28)
            .lineSpacing(3)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.recapGray300)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Home sections") {
    ScrollView {
        VStack(spacing: 26) {
            HomeFavoritesSection(
                cards: SampleData.cards.filter(\.isFavorite).compactMap(Card.init(snapshot:)),
                openFavorites: {},
                openCard: { _ in }
            )
            HomeRecentSection(
                cards: SampleData.recentCards.compactMap(Card.init(snapshot:)),
                openAllRecent: {},
                openCard: { _ in }
            )
            HomeFrequentTypesSection(
                summaries: SampleData.collectionSummaries,
                openArchive: { _ in }
            )
        }
        .padding()
    }
    .background(Color.recapBackground)
}

#Preview("Frequent types aligned leading") {
    HomeFrequentTypesSection(
        summaries: Array(SampleData.collectionSummaries.prefix(2)),
        openArchive: { _ in }
    )
    .padding(.horizontal, 16)
    .background(Color.recapBackground)
}
#endif
