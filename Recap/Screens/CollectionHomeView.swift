import SwiftUI

struct CollectionHomeContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        CollectionHomeView(
            summaries: cardStore.collectionSummaries,
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

struct CollectionHomeView: View {
    let summaries: [CollectionSummary]
    let onAction: (ArchiveAction) -> Void

    init(
        summaries: [CollectionSummary],
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        self.summaries = summaries
        self.onAction = onAction
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                ScreenHeader(
                    style: .title("보관함"),
                    onMenuTap: openSettings
                )

                Button(action: openSearch) {
                    SearchBar(text: .constant(""))
                        .allowsHitTesting(false)
                }
                .buttonStyle(.plain)

                SectionHeader(title: "기본 컬렉션")

                VStack(spacing: RecapTheme.Spacing.medium) {
                    ForEach(summaries) { summary in
                        Button {
                            openArchive(summary.kind)
                        } label: {
                            CollectionSummaryCard(summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, RecapTheme.Spacing.large)
            .padding(.top, RecapTheme.Spacing.large)
            .padding(.bottom, RecapTheme.Spacing.xLarge)
        }
        .background(RecapTheme.ColorToken.background)
    }

    private func openSearch() {
        onAction(.search)
    }

    private func openArchive(_ kind: CollectionKind) {
        onAction(.openArchive(kind))
    }

    private func openSettings() {
        onAction(.openSettings)
    }
}

#Preview {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleArchive
        )
    }
}
