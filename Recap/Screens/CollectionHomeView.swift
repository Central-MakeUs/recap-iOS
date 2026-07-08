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
                HStack(spacing: RecapTheme.Spacing.medium) {
                    Text("보관함")
                        .font(.title3.weight(.black))
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                    Spacer()

                    Button(action: openSettings) {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(RecapTheme.ColorToken.surface)
                            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                                    .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("설정 열기")
                }

                Button(action: openSearch) {
                    SearchBar(text: .constant(""))
                        .allowsHitTesting(false)
                }
                .buttonStyle(.plain)

                SectionHeader(title: "기본 컬렉션")

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: RecapTheme.Spacing.large),
                        GridItem(.flexible(), spacing: RecapTheme.Spacing.large),
                        GridItem(.flexible(), spacing: RecapTheme.Spacing.large)
                    ],
                    alignment: .leading,
                    spacing: RecapTheme.Spacing.xLarge
                ) {
                    ForEach(summaries) { summary in
                        Button {
                            openArchive(summary.kind)
                        } label: {
                            let collection = RecapPresentation.collectionDisplay(for: summary.kind)
                            ArchiveCategoryCard(
                                title: collection.title,
                                count: summary.count,
                                thumbnailState: summary.count == 0 ? .empty : .filled,
                                tint: collection.dotColor
                            )
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
