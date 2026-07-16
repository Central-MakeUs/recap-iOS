import SwiftUI

struct CollectionHomeTypeGrid: View {
    let summaries: [CollectionSummary]
    let onOpenArchive: (CollectionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CollectionHomeFolderCountLabel()

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(99), spacing: 19), count: 3),
                alignment: .leading,
                spacing: 39
            ) {
                ForEach(folderSummaries) { summary in
                    Button {
                        onOpenArchive(summary.kind)
                    } label: {
                        let display = RecapPresentation.collectionDisplay(for: summary.kind)
                        ArchiveCategoryCard(
                            title: display.title,
                            count: summary.count,
                            thumbnailState: summary.kind == .other ? .empty : .filled,
                            kind: summary.kind
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 335, alignment: .leading)
            .padding(.leading, 4)
        }
    }

    private var folderSummaries: [CollectionSummary] {
        summaries.filter { CollectionKind.folderCases.contains($0.kind) }
    }
}

struct CollectionHomeTypeList: View {
    let summaries: [CollectionSummary]
    let onOpenArchive: (CollectionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CollectionHomeFolderCountLabel()
                .padding(.bottom, 16)

            ForEach(folderSummaries) { summary in
                Button {
                    onOpenArchive(summary.kind)
                } label: {
                    let display = RecapPresentation.collectionDisplay(for: summary.kind)
                    ArchiveCategoryListCard(
                        title: display.title,
                        subtitle: display.subtitle,
                        count: summary.count,
                        kind: summary.kind
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, -16)
    }

    private var folderSummaries: [CollectionSummary] {
        summaries.filter { CollectionKind.folderCases.contains($0.kind) }
    }
}

struct CollectionHomeCardSection: View {
    enum Style: Equatable {
        case favorites
        case other
    }

    let cards: [InformationCard]
    let style: Style
    let emptySegment: CollectionHomeView.Segment
    let onSelectFilter: (String) -> Void
    let onOpenCard: (InformationCard.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionHeader

            if style == .other {
                recapCountText
                    .padding(.top, 5)
                    .padding(.horizontal, 16)
            }

            if cards.isEmpty {
                CollectionHomeEmptyState(segment: emptySegment)
            } else {
                cardList
            }
        }
        .padding(.horizontal, -16)
    }

    private var sectionHeader: some View {
        HStack {
            if style == .other {
                RecapFilterButton(title: "최신순") {
                    onSelectFilter("최신순")
                }
            } else {
                recapCountText
            }

            Spacer()

            Text("선택")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray500)
        }
        .padding(.horizontal, 16)
    }

    private var cardList: some View {
        VStack(spacing: 0) {
            ForEach(cards) { card in
                Button {
                    onOpenCard(card.id)
                } label: {
                    if style == .favorites {
                        FavoriteRecapListCard(card: card, isStarred: true)
                    } else {
                        ArchiveOtherCard(card: card)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recapCountText: some View {
        Text("\(cards.count) recaps")
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(Color.recapGray500)
    }
}

struct CollectionHomeEmptyState: View {
    let segment: CollectionHomeView.Segment

    var body: some View {
        switch segment {
        case .favorites:
            VStack(spacing: 14) {
                RecapArchiveEmptyIllustration(style: .favorites)
                Text("아직 즐겨찾기한 스크린샷이 없어요")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(Color.recapGray900)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 76)
        case .other:
            VStack(spacing: 14) {
                RecapArchiveEmptyIllustration(style: .other)
                Text("아직 기타 스크린샷이 없어요")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(Color.recapGray900)
                Text("유형을 정하지 못한 항목은 이후 이 위치에 표시됩니다.")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapGray500)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 76)
        case .type:
            EmptyView()
        }
    }
}

private struct CollectionHomeFolderCountLabel: View {
    var body: some View {
        Text("8개의 유형 폴더")
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(Color.recapGray500)
            .padding(.leading, 5)
    }
}
