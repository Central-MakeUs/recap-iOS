import SwiftUI

struct CollectionDetailContainerView: View {
    @Environment(AppRouter.self) private var router

    let scope: ArchiveDetailScope
    let invalidationCenter: CardDataInvalidationCenter

    @State private var model: ArchiveDetailFeatureModel
    @State private var loadedRevision: Int?

    init(
        scope: ArchiveDetailScope,
        loader: any ArchiveLoading,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.scope = scope
        self.invalidationCenter = invalidationCenter
        _model = State(
            initialValue: ArchiveDetailFeatureModel(
                scope: scope,
                loader: loader
            )
        )
    }

    var body: some View {
        CollectionDetailView(
            scope: scope,
            cards: cards,
            loadState: loadState,
            onRetry: retry,
            onImportScreenshots: { router.navigate(.cardCreationStart) },
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
            isActive: router.selectedTab == .archive
                && router.path(for: .archive).last == route
        )
    }

    private var route: AppRoute {
        switch scope {
        case .favorites:
            .archiveFavorites
        case .category(let kind):
            .archiveDetail(kind)
        }
    }

    private func handleAction(_ action: ArchiveAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .openFavorites:
            router.navigate(.archiveFavorites)
        case .openArchive(let kind):
            router.navigate(.archiveDetail(kind))
        case .openCard(let card):
            router.navigate(.remoteCardDetail(card))
        case .selectFilter(let value):
            guard let sort = ArchiveSort.allCases.first(where: { $0.title == value }) else {
                return
            }
            Task {
                await model.selectSort(sort)
            }
        case .deleteCards:
            break
        case .openSettings:
            router.navigate(.settings)
        }
    }

    private var cards: [InformationCard] {
        guard case .loaded(let cards) = model.state else {
            return []
        }
        return cards
    }

    private var loadState: CollectionDetailView.LoadState {
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
}

private struct ArchiveDetailReloadTrigger: Hashable {
    let revision: Int
    let isActive: Bool
}

struct CollectionDetailView: View {
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
    @State private var selectedIDs: Set<InformationCard.ID> = []
    @State private var filterSelection = "최신순"
    @State private var isFilterExpanded = false
    @State private var isDeleteConfirmationPresented = false
    @State private var toast: RecapToastContent?

    let scope: ArchiveDetailScope
    let cards: [InformationCard]
    let loadState: LoadState
    let onRetry: () -> Void
    let onImportScreenshots: () -> Void
    let onAction: (ArchiveAction) -> Void

    init(
        scope: ArchiveDetailScope,
        cards: [InformationCard],
        loadState: LoadState = .loaded,
        interactionMode: InteractionMode = .browsing,
        initialToast: RecapToastContent? = nil,
        onRetry: @escaping () -> Void = {},
        onImportScreenshots: @escaping () -> Void = {},
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        self.scope = scope
        self.cards = cards
        self.loadState = loadState
        _interactionMode = State(initialValue: interactionMode)
        _toast = State(initialValue: initialToast)
        self.onRetry = onRetry
        self.onImportScreenshots = onImportScreenshots
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: 0) {
            CollectionDetailNavigationHeader(
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
        .recapConfirmationDialog(
            isPresented: $isDeleteConfirmationPresented,
            title: "\(selectedIDs.count)개의 스크린샷을 삭제할까요?",
            message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
            cancelTitle: "취소",
            confirmTitle: "삭제",
            onConfirm: confirmDeletion
        )
        .recapToast(toast)
        .task(id: toast) {
            await clearToastIfNeeded()
        }
        .onAppear {
            mainTabChromeState.setVisible(false, for: .archive)
        }
        .onChange(of: query) {
            guard isSelecting else { return }
            selectedIDs.formIntersection(filteredCards.map(\.id))
        }
        .onDisappear {
            mainTabChromeState.reset(for: .archive)
        }
    }

    private var controlRow: some View {
        HStack(spacing: 14) {
            RecapFilterPicker(
                options: ["최신순", "즐겨찾기"],
                selection: $filterSelection,
                isExpanded: $isFilterExpanded
            )
            .onChange(of: filterSelection) { _, value in
                onAction(.selectFilter(value))
            }

            Spacer()

            if isSelecting {
                Button("취소", action: cancelSelection)
                    .foregroundStyle(Color.recapGray500)

                Button("선택 삭제 (\(selectedIDs.count))", action: requestDeletion)
                    .foregroundStyle(Color.recapBlue500)
                    .disabled(selectedIDs.isEmpty)
            } else {
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
        switch loadState {
        case .failed:
            RecapLoadFailureView(style: .archive, retry: onRetry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 82)
        case .loaded:
            recapCount

            if filteredCards.isEmpty {
                CollectionDetailEmptyState(
                    scope: scope,
                    onImportScreenshots: onImportScreenshots
                )
                .frame(maxHeight: .infinity)
                .padding(.bottom, 120)
            } else {
                cardList
                    .padding(.top, 7)
            }
        }
    }

    private var recapCount: some View {
        Text(
            "\(Text("\(filteredCards.count)").font(RecapFont.pretendard(size: 14, weight: .semibold)).foregroundStyle(Color.recapGray700)) recaps"
        )
        .font(RecapFont.pretendard(size: 14, weight: .regular))
        .tracking(-0.28)
        .foregroundStyle(Color.recapGray500)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 15)
    }

    private var cardList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(filteredCards) { card in
                    Button {
                        if isSelecting {
                            toggleSelection(card.id)
                        } else {
                            onAction(.openCard(card))
                        }
                    } label: {
                        RecapInformationCardRow(
                            card: card,
                            metadata: scope.rowMetadata,
                            favoriteOverride: scope.favoriteOverride,
                            selectionState: isSelecting
                                ? selectedIDs.contains(card.id)
                                : nil
                        )
                    }
                    .buttonStyle(.plain)
                }
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

    private func toggleSelection(_ id: InformationCard.ID) {
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

    private func confirmDeletion() {
        let deletedCount = selectedIDs.count
        onAction(.deleteCards(selectedIDs))
        selectedIDs.removeAll()
        interactionMode = .browsing
        query = ""
        toast = RecapToastContent(
            style: .success,
            message: "\(deletedCount)개의 스크린샷을 삭제했어요."
        )
    }

    private func clearToastIfNeeded() async {
        guard toast != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        toast = nil
    }
}

#Preview("보관함 상세") {
    NavigationStack {
        CollectionDetailView(
            scope: .category(.shopping),
            cards: SampleData.cards(in: .shopping),
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
}

#Preview("즐겨찾기 상세") {
    NavigationStack {
        CollectionDetailView(
            scope: .favorites,
            cards: SampleData.cards.filter(\.isFavorite),
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
}

#Preview("보관함 상세 검색") {
    NavigationStack {
        CollectionDetailView(
            scope: .category(.shopping),
            cards: SampleData.cards(in: .shopping),
            interactionMode: .searching,
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
}

#Preview("보관함 상세 선택") {
    NavigationStack {
        CollectionDetailView(
            scope: .category(.shopping),
            cards: SampleData.cards(in: .shopping),
            interactionMode: .selecting(returnToSearch: false),
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
}

#Preview("보관함 상세 삭제 실패") {
    NavigationStack {
        CollectionDetailView(
            scope: .category(.shopping),
            cards: SampleData.cards(in: .shopping),
            initialToast: RecapToastContent(
                style: .error,
                message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요."
            ),
            onAction: PreviewActions.handleArchive
        )
    }
    .environment(RecapMainTabChromeState())
}
