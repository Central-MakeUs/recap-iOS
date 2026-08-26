import SwiftUI

struct ArchiveDetailContainerView: View {
    @Environment(AppRouter.self) private var router

    let scope: ArchiveDetailScope
    let invalidationCenter: CardDataInvalidationCenter

    @State private var model: ArchiveDetailFeatureModel
    @State private var searchModel: SearchFeatureModel
    @State private var loadedRevision: Int?

    init(
        scope: ArchiveDetailScope,
        loader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        cardStore: CardStore,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.scope = scope
        self.invalidationCenter = invalidationCenter
        _model = State(
            initialValue: ArchiveDetailFeatureModel(
                scope: scope,
                loader: loader,
                cardStore: cardStore
            )
        )
        _searchModel = State(
            initialValue: SearchFeatureModel(
                loader: searchLoader,
                scope: scope.searchScope,
                cardStore: cardStore
            )
        )
    }

    var body: some View {
        ArchiveDetailView(
            scope: scope,
            cards: cards,
            searchModel: searchModel,
            sort: model.sort,
            loadState: loadState,
            onRetry: retry,
            onImportScreenshots: { router.navigate(.cardCreationStart) },
            onDeleteCards: deleteCards,
            onAction: handleAction
        )
        .task(id: reloadTrigger) {
            guard reloadTrigger.isActive else { return }

            let revision = invalidationCenter.archiveDetailRevision
            if loadedRevision == nil {
                await model.loadIfNeeded()
            } else if loadedRevision != revision {
                await model.reload()
            }
            guard !Task.isCancelled else { return }
            loadedRevision = revision
        }
    }

    private var reloadTrigger: ArchiveDetailReloadTrigger {
        ArchiveDetailReloadTrigger(
            revision: invalidationCenter.archiveDetailRevision,
            isActive: router.path(for: router.selectedTab).last == route
        )
    }

    private var route: AppRoute {
        switch scope {
        case .favorites:
            .archiveFavorites
        case .category(let category):
            .archiveDetail(category)
        }
    }

    private func handleAction(_ action: ArchiveAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .openFavorites:
            router.navigate(.archiveFavorites)
        case .openArchive(let category):
            router.navigate(.archiveDetail(category))
        case .openCard(let captureID):
            router.navigate(.remoteCardDetail(captureID))
        case .editCard(let captureID):
            router.navigate(.cardEdit(captureID))
        case .selectSort(let sort):
            Task {
                await model.selectSort(sort)
            }
        case .openSettings:
            router.navigate(.settings)
        }
    }

    private var cards: [CardSnapshot] {
        guard case .loaded(let cards) = model.state else {
            return []
        }
        return cards
    }

    private var loadState: ArchiveDetailView.LoadState {
        switch model.state {
        case .idle, .loading:
            .loaded
        case .loaded:
            .loaded
        case .failed:
            .failed
        }
    }

    private func retry() {
        Task {
            await model.retry()
        }
    }

    private func deleteCards(_ ids: Set<CardSnapshot.ID>) async throws {
        try await model.deleteCards(ids: ids)
        await searchModel.refreshCurrentQuery()
    }

}

private struct ArchiveDetailReloadTrigger: Hashable {
    let revision: Int
    let isActive: Bool
}

private struct ArchiveCardRowModel: Identifiable {
    let snapshot: CardSnapshot
    let card: Card

    var id: CardSnapshot.ID { snapshot.id }
}

struct ArchiveDetailView: View {
    enum LoadState {
        case loaded
        case failed
    }

    enum InteractionMode: Equatable {
        case browsing
        case searching
        case selecting(returnToSearch: Bool)

        var showsSearchField: Bool {
            switch self {
            case .browsing:
                false
            case .searching:
                true
            case .selecting(let returnToSearch):
                returnToSearch
            }
        }

        var showsSearchButton: Bool {
            self == .browsing
        }

        var isSelecting: Bool {
            if case .selecting = self { return true }
            return false
        }

        var returnsToSearchAfterSelection: Bool {
            if case .selecting(let returnToSearch) = self {
                return returnToSearch
            }
            return false
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(RecapMainTabChromeState.self) private var mainTabChromeState

    @State private var query = ""
    @State private var interactionMode: InteractionMode
    @State private var selectedIDs: Set<CardSnapshot.ID> = []
    @Environment(CardStore.self) private var cardStore
    @State private var isDeleteConfirmationPresented = false
    @State private var isDeleting = false
    @State private var toast: RecapToastContent?
    @State private var cardPendingDeletion: Card?

    let scope: ArchiveDetailScope
    let cards: [CardSnapshot]
    let searchModel: SearchFeatureModel
    let sort: ArchiveSort
    let loadState: LoadState
    let onRetry: () -> Void
    let onImportScreenshots: () -> Void
    let onDeleteCards: (Set<CardSnapshot.ID>) async throws -> Void
    let onAction: (ArchiveAction) -> Void

    init(
        scope: ArchiveDetailScope,
        cards: [CardSnapshot],
        searchModel: SearchFeatureModel,
        sort: ArchiveSort = .latest,
        loadState: LoadState = .loaded,
        interactionMode: InteractionMode = .browsing,
        initialToast: RecapToastContent? = nil,
        onRetry: @escaping () -> Void = {},
        onImportScreenshots: @escaping () -> Void = {},
        onDeleteCards: @escaping (Set<CardSnapshot.ID>) async throws -> Void = { _ in },
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        self.scope = scope
        self.cards = cards
        self.searchModel = searchModel
        self.sort = sort
        self.loadState = loadState
        _interactionMode = State(initialValue: interactionMode)
        _toast = State(initialValue: initialToast)
        self.onRetry = onRetry
        self.onImportScreenshots = onImportScreenshots
        self.onDeleteCards = onDeleteCards
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: 0) {
            ArchiveDetailNavigationHeader(
                scope: scope,
                query: $query,
                showsSearchField: interactionMode.showsSearchField,
                showsSearchButton: interactionMode.showsSearchButton,
                onBack: { dismiss() },
                onStartSearch: startSearch,
                onCloseSearch: closeSearch
            )
            .padding(.horizontal, 16)
            .padding(.top, interactionMode.showsSearchField ? 11 : 20)

            controlRow
                .padding(.top, interactionMode.showsSearchField ? 14 : 24)

            Rectangle()
                .fill(Color.recapControlFill)
                .frame(height: 6)
                .padding(.top, 12)

            detailContent
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .interactivePopGestureEnabled()
        .recapConfirmationDialog(
            isPresented: $isDeleteConfirmationPresented,
            title: "\(selectedIDs.count)개의 스크린샷을 삭제할까요?",
            message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
            cancelTitle: "취소",
            confirmTitle: "삭제",
            onConfirm: confirmDeletion
        )
        // 스와이프 한 장 삭제. 선택 모드에서는 스와이프가 꺼지므로 위 다이얼로그와
        // 동시에 뜰 일은 없다.
        .recapConfirmationDialog(
            isPresented: Binding(
                get: { cardPendingDeletion != nil },
                set: { if !$0 { cardPendingDeletion = nil } }
            ),
            title: "스크린샷을 삭제할까요?",
            message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
            cancelTitle: "취소",
            confirmTitle: "삭제",
            // 다이얼로그가 확인 직전에 isPresented를 내리면서 카드가 비워지므로,
            // 그리는 시점의 카드를 클로저에 담아둔다.
            onConfirm: { [card = cardPendingDeletion] in
                guard let card else { return }
                deleteSingleCard(card)
            }
        )
        .recapToast(toast)
        .task(id: toast) {
            await clearToastIfNeeded()
        }
        .task(id: query) {
            await searchModel.search(query: query)
        }
        .onAppear {
            mainTabChromeState.setVisible(false, for: .archive)
        }
        .onChange(of: query) {
            guard isSelecting else { return }
            selectedIDs.formIntersection(visibleCards.map(\.id))
        }
        .onDisappear {
            mainTabChromeState.reset(for: .archive)
        }
    }

    private var controlRow: some View {
        HStack(spacing: 14) {
            RecapSortToggleButton(title: sort.title) {
                onAction(.selectSort(sort.toggled))
            }

            Spacer()

            if isSelecting {
                Button("취소", action: cancelSelection)
                    .foregroundStyle(Color.recapGray500)

                Button("선택 삭제 (\(selectedIDs.count))", action: requestDeletion)
                    .foregroundStyle(Color.recapBlue500)
                    .disabled(selectedIDs.isEmpty || isDeleting)
            } else if scope != .favorites {
                Button("선택", action: beginSelection)
                    .foregroundStyle(Color.recapGray500)
            }
        }
        .font(RecapFont.pretendard(size: 14, weight: .regular))
        .tracking(-0.28)
        .padding(.horizontal, 16)
        .frame(height: 35)
    }

    @ViewBuilder
    private var detailContent: some View {
        if query.isEmpty {
            archiveContent
        } else {
            searchContent
        }
    }

    @ViewBuilder
    private var archiveContent: some View {
        switch loadState {
        case .failed:
            RecapLoadFailureView(style: .archive, retry: onRetry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 82)
        case .loaded:
            loadedContent(cards: cards, highlightedResults: [:])
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        switch searchModel.state {
        case .idle, .loading:
            Color.clear
        case .failed:
            RecapLoadFailureView(style: .archive, retry: retrySearch)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 82)
        case .loaded(let content):
            let results = sortedSearchResults(content.results)
            let displayCards = results.map(displayCard)
            loadedContent(
                cards: displayCards,
                highlightedResults: Dictionary(
                    uniqueKeysWithValues: zip(displayCards, results).map {
                        ($0.id, $1)
                    }
                )
            )
        }
    }

    @ViewBuilder
    private func loadedContent(
        cards: [CardSnapshot],
        highlightedResults: [CardSnapshot.ID: SearchResult]
    ) -> some View {
        if cards.isEmpty {
            recapCount(cards.count)

            ArchiveDetailEmptyState(
                scope: scope,
                onImportScreenshots: onImportScreenshots
            )
            .frame(maxHeight: .infinity)
            .padding(.bottom, 120)
        } else {
            // recaps 개수는 헤더가 아니라 목록과 함께 스크롤된다.
            cardList(cards: cards, highlightedResults: highlightedResults)
        }
    }

    private func recapCount(_ count: Int) -> some View {
        Text(
            "\(Text("\(count)").font(RecapFont.pretendard(size: 14, weight: .semibold)).foregroundStyle(Color.recapGray700)) recaps"
        )
        .font(RecapFont.pretendard(size: 14, weight: .regular))
        .tracking(-0.28)
        .foregroundStyle(Color.recapGray500)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 15)
    }

    private func cardList(
        cards: [CardSnapshot],
        highlightedResults: [CardSnapshot.ID: SearchResult]
    ) -> some View {
        RecapSwipeCardCollection(
            items: rows(for: cards),
            header: AnyView(
                recapCount(cards.count)
                    .padding(.bottom, 7)
            ),
            headerHeight: 39,
            isLoading: false,
            rowContent: { row in
                let card = row.snapshot
                let searchResult = highlightedResults[card.id]
                return AnyView(
                    RecapInformationCardRow(
                        card: row.card,
                        metadata: scope.rowMetadata,
                        selectionState: isSelecting
                            ? selectedIDs.contains(card.id)
                            : nil,
                        titleText: searchResult?.title.styledText(
                            defaultColor: Color.recapGray900
                        ),
                        summaryText: searchResult?.summary.styledText(
                            defaultColor: Color.recapGray500
                        ),
                        onToggleFavorite: isSelecting
                            || cardStore.updatingFavoriteIDs.contains(row.card.captureID)
                            ? nil
                            : { toggleFavorite(row.card) },
                        onRemoteImageFailure: { failedURL in
                            refreshImageURL(for: row.card, failedURL: failedURL)
                        }
                    )
                )
            },
            actions: { row in
                guard !isSelecting else { return [] }
                return RecapSwipeAction.cardActions(
                    onEdit: { onAction(.editCard(row.card.captureID)) },
                    onDelete: { cardPendingDeletion = row.card }
                )
            },
            onSelect: { row in
                if isSelecting {
                    toggleSelection(row.snapshot.id)
                } else {
                    onAction(.openCard(row.card.captureID))
                }
            },
            onWillDisplay: { row in
                guard let searchResult = highlightedResults[row.snapshot.id] else { return }
                loadNextSearchPage(after: searchResult.id)
            }
        )
    }

    private var visibleCards: [CardSnapshot] {
        guard !query.isEmpty else { return cards }
        guard case .loaded(let content) = searchModel.state else { return [] }
        return sortedSearchResults(content.results).map(displayCard)
    }

    private func displayCard(for result: SearchResult) -> CardSnapshot {
        cards.first { $0.captureID == result.captureID } ?? result.card
    }

    private func sortedSearchResults(_ results: [SearchResult]) -> [SearchResult] {
        results.enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element.card.organizedAt, rhs.element.card.organizedAt) {
                case let (left?, right?) where left != right:
                    return sort == .latest ? left > right : left < right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }

    private func retrySearch() {
        Task {
            await searchModel.retry()
        }
    }

    private func loadNextSearchPage(after resultID: SearchResult.ID) {
        Task {
            await searchModel.loadNextPageIfNeeded(after: resultID)
        }
    }

    private var isSelecting: Bool {
        interactionMode.isSelecting
    }

    private func startSearch() {
        interactionMode = .searching
    }

    private func closeSearch() {
        query = ""
        selectedIDs.removeAll()
        interactionMode = .browsing
    }

    private func beginSelection() {
        interactionMode = .selecting(returnToSearch: interactionMode == .searching)
    }

    private func cancelSelection() {
        let returnToSearch = interactionMode.returnsToSearchAfterSelection
        selectedIDs.removeAll()
        interactionMode = returnToSearch ? .searching : .browsing
    }

    private func toggleSelection(_ id: CardSnapshot.ID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func requestDeletion() {
        guard !selectedIDs.isEmpty else { return }
        isDeleteConfirmationPresented = true
    }

    /// 스냅샷은 선택·하이라이트 키로, `Card`는 표시·토글로 쓴다.
    /// 모델이 적재 시점에 upsert하므로 스토어 조회는 실패하지 않는다.
    private func rows(
        for snapshots: [CardSnapshot]
    ) -> [ArchiveCardRowModel] {
        snapshots.compactMap { snapshot in
            guard let card = cardStore.card(withCaptureID: snapshot.captureID) else { return nil }
            return ArchiveCardRowModel(snapshot: snapshot, card: card)
        }
    }

    private func toggleFavorite(_ card: Card) {
        Task {
            guard let content = await cardStore.toggleFavoriteReturningToast(card) else { return }
            toast = content
        }
    }

    private func refreshImageURL(for card: Card, failedURL: URL) {
        Task {
            await cardStore.refreshImageURL(for: card, failedURL: failedURL)
        }
    }

    private func confirmDeletion() {
        let ids = selectedIDs
        guard !ids.isEmpty, !isDeleting else { return }
        isDeleting = true

        Task {
            defer { isDeleting = false }

            do {
                try await onDeleteCards(ids)
                selectedIDs.removeAll()
                interactionMode = .browsing
                query = ""
                toast = RecapToastMessage.screenshotsDeleted(count: ids.count).content
            } catch {
                toast = RecapToastMessage.screenshotDeleteFailed.content
            }
        }
    }

    /// 스와이프로 지운 한 장. 선택 삭제와 같은 길로 보내야 이 화면의 목록과
    /// 검색 결과가 함께 갱신된다.
    private func deleteSingleCard(_ card: Card) {
        guard !isDeleting else { return }
        isDeleting = true

        Task {
            defer { isDeleting = false }

            do {
                try await onDeleteCards([card.captureID])
                toast = RecapToastMessage.screenshotsDeleted(count: 1).content
            } catch {
                toast = RecapToastMessage.screenshotDeleteFailed.content
            }
        }
    }

    private func clearToastIfNeeded() async {
        guard toast != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        toast = nil
    }
}

#if DEBUG
#Preview("보관함 상세") {
    NavigationStack {
        ArchiveDetailView(
            scope: .category(.shopping),
            cards: SampleData.cards(in: .shopping),
            searchModel: previewArchiveSearchModel(scope: .category(.shopping)),
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
    .environment(PreviewStores.cardStore())
}

#Preview("즐겨찾기 상세") {
    NavigationStack {
        ArchiveDetailView(
            scope: .favorites,
            cards: SampleData.cards.filter(\.isFavorite),
            searchModel: previewArchiveSearchModel(scope: .favorites),
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
    .environment(PreviewStores.cardStore())
}

#Preview("보관함 상세 검색") {
    NavigationStack {
        ArchiveDetailView(
            scope: .category(.shopping),
            cards: SampleData.cards(in: .shopping),
            searchModel: previewArchiveSearchModel(scope: .category(.shopping)),
            interactionMode: .searching,
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
    .environment(PreviewStores.cardStore())
}

#Preview("보관함 상세 선택") {
    NavigationStack {
        ArchiveDetailView(
            scope: .category(.shopping),
            cards: SampleData.cards(in: .shopping),
            searchModel: previewArchiveSearchModel(scope: .category(.shopping)),
            interactionMode: .selecting(returnToSearch: false),
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
    .environment(PreviewStores.cardStore())
}

#Preview("보관함 상세 삭제 실패") {
    NavigationStack {
        ArchiveDetailView(
            scope: .category(.shopping),
            cards: SampleData.cards(in: .shopping),
            searchModel: previewArchiveSearchModel(scope: .category(.shopping)),
            initialToast: RecapToastContent(
                style: .error,
                message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요."
            ),
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
    .environment(PreviewStores.cardStore())
}
#endif

#if DEBUG
@MainActor
private func previewArchiveSearchModel(
    scope: ArchiveDetailScope
) -> SearchFeatureModel {
    SearchFeatureModel(
        loader: PreviewSearchLoader(),
        scope: scope.searchScope
    )
}
#endif
