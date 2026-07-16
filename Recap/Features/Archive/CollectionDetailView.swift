import SwiftUI

struct CollectionDetailContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    let kind: CollectionKind

    var body: some View {
        CollectionDetailView(
            kind: kind,
            cards: cardsForDisplay,
            summary: cardStore.collectionSummaries.first { $0.kind == kind },
            onAction: handleAction
        )
    }

    private var cardsForDisplay: [InformationCard] {
        cardStore.cards(in: kind)
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
        case .deleteCards(let ids):
            ids.forEach(cardStore.removeCard)
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

struct CollectionDetailView: View {
    enum LoadState { case loaded, failed }

    @State private var query = ""
    @State private var isSelecting = false
    @State private var selectedIDs: Set<InformationCard.ID> = []

    let kind: CollectionKind
    let cards: [InformationCard]
    let summary: CollectionSummary?
    var loadState: LoadState = .loaded
    var onRetry: () -> Void = {}
    let onAction: (ArchiveAction) -> Void

    init(
        kind: CollectionKind,
        cards: [InformationCard],
        summary: CollectionSummary?,
        loadState: LoadState = .loaded,
        onRetry: @escaping () -> Void = {},
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        self.kind = kind
        self.cards = cards
        self.summary = summary
        self.loadState = loadState
        self.onRetry = onRetry
        self.onAction = onAction
    }

    var body: some View {
        let collection = RecapPresentation.collectionDisplay(for: kind)

        if loadState == .failed {
            RecapLoadFailureView(style: .archive, retry: onRetry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.recapBackground)
                .navigationTitle("보관함")
                .navigationBarTitleDisplayMode(.inline)
        } else {
            loadedContent(collection: collection)
        }
    }

    private func loadedContent(collection: RecapPresentation.CollectionDisplay) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                SearchBar(text: $query)
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    RecapFilterButton(title: "최신순") {
                        onAction(.selectFilter("최신순"))
                    }

                    Spacer()
                }

                HStack {
                    Text("\(filteredCards.count) recaps")
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(Color.recapGray500)
                    Spacer()
                    Button(isSelecting ? "완료" : "선택") {
                        isSelecting.toggle()
                        if !isSelecting { selectedIDs.removeAll() }
                    }
                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                    .foregroundStyle(Color.recapGray500)
                }

                VStack(spacing: 0) {
                    if filteredCards.isEmpty {
                        RecapInlineEmptyView(
                            title: "아직 \(collection.title) 카드가 없어요",
                            message: "실제 분류 데이터가 연결되면 이곳에 표시됩니다."
                        )
                    } else {
                        ForEach(filteredCards) { card in
                            Button {
                                if isSelecting {
                                    toggleSelection(card.id)
                                } else {
                                    openCard(card.id)
                                }
                            } label: {
                                HStack(spacing: 0) {
                                    if isSelecting {
                                        Image(systemName: selectedIDs.contains(card.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundStyle(selectedIDs.contains(card.id) ? Color.recapBlue300 : Color.recapGray100)
                                            .padding(.leading, 16)
                                    }
                                    ArchiveListCard(card: card)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.recapGray100, lineWidth: 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 122)
        }
        .background(Color.recapBackground)
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if isSelecting {
                Button {
                    onAction(.deleteCards(selectedIDs))
                    selectedIDs.removeAll()
                    isSelecting = false
                } label: {
                    Text("삭제")
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(selectedIDs.isEmpty ? Color.recapGray300 : Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(selectedIDs.isEmpty)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.recapBackground)
            }
        }
    }

    private var filteredCards: [InformationCard] {
        guard !query.isEmpty else { return cards }
        return cards.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    private func toggleSelection(_ id: InformationCard.ID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }

    private func openCard(_ id: InformationCard.ID) {
        onAction(.openCard(id))
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(
            kind: .shopping,
            cards: SampleData.cards(in: .shopping),
            summary: SampleData.collectionSummaries.first { $0.kind == .shopping },
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive load failure") {
    NavigationStack {
        CollectionDetailView(
            kind: .shopping,
            cards: [],
            summary: nil,
            loadState: .failed,
            onAction: PreviewActions.handleArchive
        )
    }
}
