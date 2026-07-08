import SwiftUI

struct CollectionDetailContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    let kind: CollectionKind

    var body: some View {
        CollectionDetailView(
            kind: kind,
            cards: cardStore.cards(in: kind),
            summary: cardStore.collectionSummaries.first { $0.kind == kind },
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
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

struct CollectionDetailView: View {
    let kind: CollectionKind
    let cards: [InformationCard]
    let summary: CollectionSummary?
    let onAction: (ArchiveAction) -> Void

    init(
        kind: CollectionKind,
        cards: [InformationCard],
        summary: CollectionSummary?,
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        self.kind = kind
        self.cards = cards
        self.summary = summary
        self.onAction = onAction
    }

    var body: some View {
        let collection = RecapPresentation.collectionDisplay(for: kind)

        Group {
            if let summary {
                detailContent(collection: collection, summary: summary)
            } else {
                MissingCollectionSummaryView(kind: kind)
            }
        }
        .background(RecapTheme.ColorToken.background)
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailContent(collection: RecapPresentation.CollectionDisplay, summary: CollectionSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: RecapTheme.Spacing.small) {
                    HStack(spacing: RecapTheme.Spacing.small) {
                        Circle()
                            .fill(collection.dotColor)
                            .frame(width: 9, height: 9)
                        Text(collection.title)
                            .font(.title3.weight(.black))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    }

                    Text(collection.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(summary.count)개 카드")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RecapTheme.ColorToken.primary)
                        .padding(.top, 2)
                }

                HStack {
                    RecapFilterButton(title: "최신순") {
                        onAction(.selectFilter("최신순"))
                    }
                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RecapTheme.Spacing.small) {
                        Text("전체")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, RecapTheme.Spacing.medium)
                            .padding(.vertical, RecapTheme.Spacing.small)
                            .background(RecapTheme.ColorToken.primary)
                            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                        Text("상품")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(collection.dotColor)
                            .padding(.horizontal, RecapTheme.Spacing.medium)
                            .padding(.vertical, RecapTheme.Spacing.small)
                            .background(collection.dotColor.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                        Text("맛집")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(collection.dotColor)
                            .padding(.horizontal, RecapTheme.Spacing.medium)
                            .padding(.vertical, RecapTheme.Spacing.small)
                            .background(collection.dotColor.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                        Text("여행지")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(collection.dotColor)
                            .padding(.horizontal, RecapTheme.Spacing.medium)
                            .padding(.vertical, RecapTheme.Spacing.small)
                            .background(collection.dotColor.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                        Text("숙소")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(collection.dotColor)
                            .padding(.horizontal, RecapTheme.Spacing.medium)
                            .padding(.vertical, RecapTheme.Spacing.small)
                            .background(collection.dotColor.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                    }
                }

                VStack(spacing: 0) {
                    ForEach(cards) { card in
                        Button {
                            openCard(card.id)
                        } label: {
                            ArchiveListCard(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.medium, style: .continuous))
            }
            .padding(RecapTheme.Spacing.large)
        }
    }

    private func openCard(_ id: InformationCard.ID) {
        onAction(.openCard(id))
    }
}

struct MissingCollectionSummaryView: View {
    let kind: CollectionKind

    var body: some View {
        let collection = RecapPresentation.collectionDisplay(for: kind)

        VStack(spacing: RecapTheme.Spacing.large) {
            Image(systemName: "rectangle.stack.badge.questionmark")
                .font(.title.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                .frame(width: 64, height: 64)
                .background(RecapTheme.ColorToken.surface)
                .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))

            VStack(spacing: RecapTheme.Spacing.small) {
                Text("컬렉션 정보를 찾을 수 없어요")
                    .font(.title3.weight(.black))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                Text("\(collection.title) 요약 데이터가 없어 실제 카드 수로 조용히 대체하지 않았습니다.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            }
        }
        .padding(RecapTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(
            kind: .comparison,
            cards: SampleData.cards(in: .comparison),
            summary: SampleData.collectionSummaries.first { $0.kind == .comparison },
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Missing collection summary") {
    NavigationStack { MissingCollectionSummaryView(kind: .reference) }
}
