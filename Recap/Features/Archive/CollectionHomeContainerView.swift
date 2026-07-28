import SwiftUI

struct CollectionHomeContainerView: View {
    @Environment(AppRouter.self) private var router

    @State private var model: ArchiveHomeFeatureModel
    @State private var loadedRevision: ArchiveHomeRevision?
    let invalidationCenter: CardDataInvalidationCenter

    init(
        loader: any ArchiveLoading,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.invalidationCenter = invalidationCenter
        _model = State(initialValue: ArchiveHomeFeatureModel(loader: loader))
    }

    var body: some View {
        CollectionHomeView(
            summaries: content.summaries,
            favoriteCount: content.favoriteCount,
            otherCount: content.otherCount,
            loadState: loadState,
            onRetry: retry,
            onImportScreenshots: { router.navigate(.cardCreationStart) },
            onAction: handleAction
        )
        .task(id: reloadTrigger) {
            guard reloadTrigger.isActive else { return }

            let revision = invalidationCenter.archiveHomeRevision
            if let loadedRevision {
                await model.reload(
                    scopes: revision.changedScopes(since: loadedRevision)
                )
            } else {
                await model.loadIfNeeded()
            }
            guard !Task.isCancelled else { return }
            loadedRevision = revision
        }
    }

    private var reloadTrigger: ArchiveHomeReloadTrigger {
        ArchiveHomeReloadTrigger(
            revision: invalidationCenter.archiveHomeRevision,
            isActive: router.selectedTab == .archive && router.path(for: .archive).isEmpty
        )
    }

    private var content: ArchiveHomeContent {
        guard case .loaded(let content) = model.state else {
            return .empty
        }
        return content
    }

    private var loadState: CollectionHomeView.LoadState {
        switch model.state {
        case .idle, .loading:
            .loaded
        case .loaded:
            .loaded
        case .failed:
            .failed
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
        case .selectSort:
            break
        case .openSettings:
            router.navigate(.settings)
        }
    }

    private func retry() {
        Task {
            await model.retry()
        }
    }
}

private struct ArchiveHomeReloadTrigger: Hashable {
    let revision: ArchiveHomeRevision
    let isActive: Bool
}
