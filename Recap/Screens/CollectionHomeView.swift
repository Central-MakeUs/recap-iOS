import SwiftUI

struct CollectionHomeContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        CollectionHomeView(
            summaries: cardStore.collectionSummaries,
            favoriteCards: cardStore.favoriteCards,
            otherCards: cardStore.uncategorizedCards,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: ArchiveAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .openArchive(let kind):
            router.navigate(.archiveDetail(kind))
        case .openCard(let id):
            router.navigate(.cardDetail(id))
        case .selectFilter:
            break
        case .deleteCards:
            break
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

struct CollectionHomeView: View {
    enum LayoutMode {
        case grid
        case list
    }

    enum Segment: String, CaseIterable, Identifiable {
        case favorites = "즐겨찾기"
        case type = "유형별 보기"
        case other = "기타"

        var id: String { rawValue }
    }

    @State private var segment: Segment = .type
    @State private var layoutMode: LayoutMode = .grid

    let summaries: [CollectionSummary]
    let favoriteCards: [InformationCard]
    let otherCards: [InformationCard]
    let onAction: (ArchiveAction) -> Void

    init(
        summaries: [CollectionSummary],
        favoriteCards: [InformationCard] = SampleData.cards.filter(\.isFavorite),
        otherCards: [InformationCard] = [],
        initialSegment: Segment = .type,
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        self.summaries = summaries
        self.favoriteCards = favoriteCards
        self.otherCards = otherCards
        self.onAction = onAction
        _segment = State(initialValue: initialSegment)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                Button(action: openSearch) {
                    SearchBarDisplay()
                }
                .buttonStyle(.plain)
                .padding(.top, 25)

                segmentControl
                    .padding(.top, 19)

                content
                    .padding(.top, 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 15)
            .padding(.bottom, 122)
        }
        .background(RecapTheme.ColorToken.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image("RecapArchiveIcon")
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 14)
                .frame(width: 24, height: 24)

            Text("보관함")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

            Spacer()

            if segment == .type {
                Text("보기")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)

                HStack(spacing: 6) {
                    layoutButton(mode: .grid, symbol: "square.grid.2x2.fill")
                    layoutButton(mode: .list, symbol: "list.bullet")
                }
                .padding(.horizontal, 5)
                .frame(width: 64, height: 31)
                .background(RecapTheme.ColorToken.controlFill)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
        .frame(height: 31)
    }

    private func layoutButton(mode: LayoutMode, symbol: String) -> some View {
        Button {
            layoutMode = mode
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(layoutMode == mode ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.textTertiary)
                .frame(width: 24, height: 24)
                .background(layoutMode == mode ? Color.white : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var segmentControl: some View {
        HStack(spacing: 6) {
            ForEach(Segment.allCases) { item in
                Button {
                    segment = item
                } label: {
                    Text(item.rawValue)
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(segment == item ? .white : RecapTheme.ColorToken.textTertiary)
                        .frame(width: 87, height: 35)
                        .background(segment == item ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.controlFill)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch segment {
        case .type:
            layoutMode == .grid ? AnyView(typeGrid) : AnyView(typeList)
        case .favorites:
            archiveCardSection(cards: favoriteCards, style: .favorites)
        case .other:
            archiveCardSection(cards: otherCards, style: .other)
        }
    }

    private var typeGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("8개의 유형 폴더")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .padding(.leading, 5)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(99), spacing: 19), count: 3),
                alignment: .leading,
                spacing: 39
            ) {
                ForEach(summaries.filter { CollectionKind.folderCases.contains($0.kind) }) { summary in
                    Button {
                        openArchive(summary.kind)
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

    private var typeList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("8개의 유형 폴더")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .padding(.leading, 5)
                .padding(.bottom, 16)

            ForEach(summaries.filter { CollectionKind.folderCases.contains($0.kind) }) { summary in
                Button {
                    openArchive(summary.kind)
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

    @ViewBuilder
    private func archiveEmptyState(for segment: Segment) -> some View {
        switch segment {
        case .favorites:
            VStack(spacing: 14) {
                RecapArchiveEmptyIllustration(style: .favorites)
                Text("아직 즐겨찾기한 스크린샷이 없어요")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 76)
        case .other:
            VStack(spacing: 14) {
                RecapArchiveEmptyIllustration(style: .other)
                Text("아직 기타 스크린샷이 없어요")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                Text("유형을 정하지 못한 항목은 이후 이 위치에 표시됩니다.")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 76)
        case .type:
            EmptyView()
        }
    }

    private enum ArchiveCardSectionStyle: Equatable { case favorites, other }

    private func archiveCardSection(cards: [InformationCard], style: ArchiveCardSectionStyle) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                if style == .other {
                    RecapFilterButton(title: "최신순") {
                        onAction(.selectFilter("최신순"))
                    }
                } else {
                    Text("\(cards.count) recaps")
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                }

                Spacer()

                Text("선택")
                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                    .tracking(-0.28)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            }
            .padding(.horizontal, 16)

            if style == .other {
                Text("\(cards.count) recaps")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .padding(.top, 5)
                    .padding(.horizontal, 16)
            }

            if cards.isEmpty {
                archiveEmptyState(for: segment)
            } else {
                VStack(spacing: 0) {
                    ForEach(cards) { card in
                        Button {
                            openCard(card.id)
                        } label: {
                            if style == .favorites {
                                OrganizeRecapCard(card: card, isStarred: true)
                            } else {
                                ArchiveOtherCard(card: card)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, -16)
    }

    private func openSearch() { onAction(.search) }
    private func openArchive(_ kind: CollectionKind) { onAction(.openArchive(kind)) }
    private func openCard(_ id: InformationCard.ID) { onAction(.openCard(id)) }
}

struct RecapInlineEmptyView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(RecapTheme.ColorToken.thumbnail)
                .frame(width: 48, height: 48)
            Text(title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            Text(message)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}

#Preview("Archive type") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive favorites list") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            favoriteCards: SampleData.cards.filter(\.isFavorite),
            initialSegment: .favorites,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive favorites empty") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            favoriteCards: [],
            initialSegment: .favorites,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive other empty") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            otherCards: [],
            initialSegment: .other,
            onAction: PreviewActions.handleArchive
        )
    }
}
