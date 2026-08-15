import SwiftUI

struct ArchiveHomeView: View {
    enum LayoutMode {
        case grid
        case list
    }

    enum LoadState {
        case loaded
        case failed
    }

    @State private var layoutMode: LayoutMode

    let summaries: [CategorySummary]
    let favoriteCount: Int
    let otherCount: Int
    let loadState: LoadState
    let onRetry: () -> Void
    let onImportScreenshots: () -> Void
    let onAction: (ArchiveAction) -> Void

    init(
        summaries: [CategorySummary],
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
        .interactivePopGestureEnabled()
    }

    private var loadedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더·검색 바·즐겨찾기까지 고정되고, 폴더 목록만 스크롤된다.
            header
                .padding(.horizontal, 16)
                .padding(.top, 15)

            searchButton
                .padding(.horizontal, 16)
                .padding(.top, 20)

            Button {
                onAction(.openFavorites)
            } label: {
                ArchiveHomeFavoritesLink(count: favoriteCount)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 21)

            ScrollView(showsIndicators: false) {
                // 그리드는 좌우 여백을 두고, 목록은 행이 화면 끝까지 닿아야 한다.
                // 공통 여백을 두고 목록에서 음수로 상쇄하는 대신 분기마다 직접 준다.
                VStack(alignment: .leading, spacing: 0) {
                    if layoutMode == .grid {
                        ArchiveHomeFolderGrid(
                            summaries: folderSummaries,
                            onOpenArchive: openArchive
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 28)
                    } else {
                        ArchiveHomeFolderList(
                            summaries: folderSummaries,
                            onOpenArchive: openArchive
                        )
                        .padding(.top, 14)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 24)
            }
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

            ArchiveHomeEmptyState(onImportScreenshots: onImportScreenshots)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 30)
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
        ArchiveHomeHeader(layoutMode: $layoutMode)
    }

    private var searchButton: some View {
        Button {
            onAction(.search)
        } label: {
            SearchBarDisplay()
        }
        .buttonStyle(.plain)
    }

    private var folderSummaries: [CategorySummary] {
        let byKind = Dictionary(uniqueKeysWithValues: summaries.map { ($0.category, $0) })
        return CardCategory.allCases.map { category in
            byKind[category] ?? CategorySummary(
                category: category,
                count: category == .other ? otherCount : 0,
                previewTitle: ""
            )
        }
    }

    private var totalCardCount: Int {
        summaries.reduce(otherCount) { $0 + $1.count }
    }

    private func openArchive(_ category: CardCategory) {
        onAction(.openArchive(category))
    }
}

#if DEBUG
#Preview("보관함 홈 폴더형") {
    NavigationStack {
        ArchiveHomeView(
            summaries: SampleData.categorySummaries,
            favoriteCount: SampleData.cards.filter(\.isFavorite).count,
            otherCount: SampleData.cards(in: .other).count,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 홈 리스트형") {
    NavigationStack {
        ArchiveHomeView(
            summaries: SampleData.categorySummaries,
            favoriteCount: SampleData.cards.filter(\.isFavorite).count,
            otherCount: SampleData.cards(in: .other).count,
            layoutMode: .list,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 항목 없음") {
    NavigationStack {
        ArchiveHomeView(
            summaries: [],
            favoriteCount: 0,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 리스트 로딩 실패") {
    NavigationStack {
        ArchiveHomeView(
            summaries: [],
            favoriteCount: 0,
            loadState: .failed,
            onAction: PreviewActions.handleArchive
        )
    }
}
#endif
