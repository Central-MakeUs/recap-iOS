import SwiftUI

struct HomeFavoritesSection: View {
    let cards: [InformationCard]
    let openFavorites: () -> Void
    let openCard: (InformationCard) -> Void

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
    let cards: [InformationCard]
    let openAllRecent: () -> Void
    let openCard: (InformationCard) -> Void

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
    let openArchive: (CollectionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RecapSectionHeader(title: "자주 저장한 유형")

            if !frequentTypes.isEmpty {
                HStack(spacing: 20) {
                    ForEach(frequentTypes) { kind in
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
                                    .frame(width: 71)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var frequentTypes: [CollectionKind] {
        Array(summaries.prefix(4).map(\.kind))
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

#Preview("Home sections") {
    ScrollView {
        VStack(spacing: 26) {
            HomeFavoritesSection(
                cards: SampleData.cards.filter(\.isFavorite),
                openFavorites: {},
                openCard: { _ in }
            )
            HomeRecentSection(
                cards: SampleData.recentCards,
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
