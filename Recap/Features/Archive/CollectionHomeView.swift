import SwiftUI

struct CollectionHomeView: View {
    enum LayoutMode {
        case grid
        case list
    }

    enum LoadState {
        case loaded
        case failed
    }

    @State private var layoutMode: LayoutMode

    let summaries: [CollectionSummary]
    let favoriteCount: Int
    let otherCount: Int
    let loadState: LoadState
    let onRetry: () -> Void
    let onImportScreenshots: () -> Void
    let onAction: (ArchiveAction) -> Void

    init(
        summaries: [CollectionSummary],
        favoriteCount: Int,
        otherCount: Int = 0,
        layoutMode: LayoutMode = .grid,
        loadState: LoadState = .loaded,
        onRetry: @escaping () -> Void = {},
        onImportScreenshots: @escaping () -> Void = {},
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        _layoutMode = State(initialValue: layoutMode)
        self.summaries = summaries
        self.favoriteCount = favoriteCount
        self.otherCount = otherCount
        self.loadState = loadState
        self.onRetry = onRetry
        self.onImportScreenshots = onImportScreenshots
        self.onAction = onAction
    }

    var body: some View {
        Group {
            if loadState == .failed {
                failureContent
            } else if totalCardCount == 0 {
                emptyContent
            } else {
                loadedContent
            }
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                searchButton
                    .padding(.top, 20)

                Button {
                    onAction(.openFavorites)
                } label: {
                    CollectionHomeFavoritesLink(count: favoriteCount)
                }
                .buttonStyle(.plain)
                .padding(.top, 21)

                if layoutMode == .grid {
                    CollectionHomeFolderGrid(
                        summaries: folderSummaries,
                        onOpenArchive: openArchive
                    )
                    .padding(.top, 21)
                } else {
                    CollectionHomeFolderList(
                        summaries: folderSummaries,
                        onOpenArchive: openArchive
                    )
                    .padding(.horizontal, -16)
                    .padding(.top, 14)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 15)
            .padding(.bottom, 24)
        }
    }

    private var emptyContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 15)

            searchButton
                .padding(.horizontal, 16)
                .padding(.top, 20)

            CollectionHomeEmptyState(onImportScreenshots: onImportScreenshots)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 82)
        }
    }

    private var failureContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 15)

            RecapLoadFailureView(style: .archive, retry: onRetry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 82)
        }
    }

    private var header: some View {
        CollectionHomeHeader(layoutMode: $layoutMode)
    }

    private var searchButton: some View {
        Button {
            onAction(.search)
        } label: {
            SearchBarDisplay()
        }
        .buttonStyle(.plain)
    }

    private var folderSummaries: [CollectionSummary] {
        let byKind = Dictionary(uniqueKeysWithValues: summaries.map { ($0.kind, $0) })
        return CollectionKind.allCases.map { kind in
            byKind[kind] ?? CollectionSummary(
                kind: kind,
                count: kind == .other ? otherCount : 0,
                previewTitle: "카드 없음"
            )
        }
    }

    private var totalCardCount: Int {
        summaries.reduce(otherCount) { $0 + $1.count }
    }

    private func openArchive(_ kind: CollectionKind) {
        onAction(.openArchive(kind))
    }
}

#Preview("보관함 홈 폴더형") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            favoriteCount: SampleData.cards.filter(\.isFavorite).count,
            otherCount: SampleData.cards(in: .other).count,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 홈 리스트형") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            favoriteCount: SampleData.cards.filter(\.isFavorite).count,
            otherCount: SampleData.cards(in: .other).count,
            layoutMode: .list,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 항목 없음") {
    NavigationStack {
        CollectionHomeView(
            summaries: [],
            favoriteCount: 0,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 리스트 로딩 실패") {
    NavigationStack {
        CollectionHomeView(
            summaries: [],
            favoriteCount: 0,
            loadState: .failed,
            onAction: PreviewActions.handleArchive
        )
    }
}
