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
        captureMutator: any CaptureMutating,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.scope = scope
        self.invalidationCenter = invalidationCenter
        _model = State(
            initialValue: ArchiveDetailFeatureModel(
                scope: scope,
                loader: loader,
                captureMutator: captureMutator,
                invalidationCenter: invalidationCenter
            )
        )
    }

    var body: some View {
        CollectionDetailView(
            scope: scope,
            cards: cards,
            sort: model.sort,
            loadState: loadState,
            onRetry: retry,
            onImportScreenshots: { router.navigate(.cardCreationStart) },
            onDeleteCards: deleteCards,
            onToggleFavorite: toggleFavorite,
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
        case .selectSort(let sort):
            Task {
                await model.selectSort(sort)
            }
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

    private func deleteCards(_ ids: Set<InformationCard.ID>) async throws {
        try await model.deleteCards(ids: ids)
    }

    private func toggleFavorite(_ id: InformationCard.ID) async throws -> Bool {
        try await model.toggleFavorite(cardID: id)
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
    @State private var isDeleteConfirmationPresented = false
    @State private var isDeleting = false
    @State private var favoriteUpdatingIDs: Set<InformationCard.ID> = []
    @State private var toast: RecapToastContent?

    let scope: ArchiveDetailScope
    let cards: [InformationCard]
    let sort: ArchiveSort
    let loadState: LoadState
    let onRetry: () -> Void
    let onImportScreenshots: () -> Void
    let onDeleteCards: (Set<InformationCard.ID>) async throws -> Void
    let onToggleFavorite: (InformationCard.ID) async throws -> Bool
    let onAction: (ArchiveAction) -> Void

    init(
        scope: ArchiveDetailScope,
        cards: [InformationCard],
        sort: ArchiveSort = .latest,
        loadState: LoadState = .loaded,
        interactionMode: InteractionMode = .browsing,
        initialToast: RecapToastContent? = nil,
        onRetry: @escaping () -> Void = {},
        onImportScreenshots: @escaping () -> Void = {},
        onDeleteCards: @escaping (Set<InformationCard.ID>) async throws -> Void = { _ in },
        onToggleFavorite: @escaping (InformationCard.ID) async throws -> Bool = { _ in false },
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        self.scope = scope
        self.cards = cards
        self.sort = sort
        self.loadState = loadState
        _interactionMode = State(initialValue: interactionMode)
        _toast = State(initialValue: initialToast)
        self.onRetry = onRetry
        self.onImportScreenshots = onImportScreenshots
        self.onDeleteCards = onDeleteCards
        self.onToggleFavorite = onToggleFavorite
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
                    RecapInformationCardRow(
                        card: card,
                        metadata: scope.rowMetadata,
                        selectionState: isSelecting
                            ? selectedIDs.contains(card.id)
                            : nil,
                        onToggleFavorite: isSelecting || favoriteUpdatingIDs.contains(card.id)
                            ? nil
                            : { toggleFavorite(card.id) }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            toggleSelection(card.id)
                        } else {
                            onAction(.openCard(card))
                        }
                    }
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

    private func toggleFavorite(_ id: InformationCard.ID) {
        guard favoriteUpdatingIDs.insert(id).inserted else { return }

        Task {
            defer { favoriteUpdatingIDs.remove(id) }

            do {
                let isFavorite = try await onToggleFavorite(id)
                toast = RecapToastContent(
                    style: .success,
                    message: isFavorite
                        ? "즐겨찾기에 추가했어요."
                        : "즐겨찾기에서 해제했어요."
                )
            } catch {
                toast = RecapToastContent(
                    style: .error,
                    message: "즐겨찾기를 변경하지 못했어요. 다시 시도해주세요."
                )
            }
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
                toast = RecapToastContent(
                    style: .success,
                    message: "\(ids.count)개의 스크린샷을 삭제했어요."
                )
            } catch {
                toast = RecapToastContent(
                    style: .error,
                    message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요."
                )
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
