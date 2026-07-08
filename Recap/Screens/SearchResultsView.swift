import SwiftUI

struct SearchContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        SearchResultsView(
            search: cardStore.search,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: SearchAction) {
        switch action {
        case .openCard(let id):
            router.navigate(.cardDetail(id))
        }
    }
}

struct SearchResultsView: View {
    @State private var query = "성수동"
    let search: (String) -> [InformationCard]
    let onAction: (SearchAction) -> Void

    init(
        search: @escaping (String) -> [InformationCard],
        onAction: @escaping (SearchAction) -> Void
    ) {
        self.search = search
        self.onAction = onAction
    }

    private var results: [InformationCard] {
        search(query)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                SearchBar(text: $query, placeholder: "카드 제목 또는 핵심 정보 검색", showsClearButton: true)

                VStack(alignment: .leading, spacing: RecapTheme.Spacing.xSmall) {
                    HStack(spacing: 4) {
                        Text("‘\(query.isEmpty ? "전체" : query)’ 검색 결과")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        Text("\(results.count)개")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(RecapTheme.ColorToken.primary)
                    }
                    Text("카드 제목과 핵심 정보에서 검색합니다")
                        .font(.caption)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                }

                if results.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: RecapTheme.Spacing.medium) {
                        ForEach(results) { card in
                            Button {
                                openCard(card.id)
                            } label: {
                                let collection = RecapPresentation.collectionDisplay(for: card.collection)
                                HStack(spacing: RecapTheme.Spacing.medium) {
                                    RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                                        .fill(RecapTheme.ColorToken.thumbnail)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                                                .fill(collection.dotColor.opacity(0.08))
                                        )
                                        .overlay(
                                            Image(systemName: "doc.text.fill")
                                                .font(.caption)
                                                .foregroundStyle(collection.dotColor.opacity(0.55))
                                        )
                                        .frame(width: 54, height: 54)

                                    VStack(alignment: .leading, spacing: RecapTheme.Spacing.xSmall) {
                                        Text(card.title)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                                            .lineLimit(1)

                                        Text(card.summary)
                                            .font(.caption)
                                            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                                            .lineLimit(1)

                                        HStack(spacing: RecapTheme.Spacing.xSmall) {
                                            Circle()
                                                .fill(collection.dotColor)
                                                .frame(width: 5, height: 5)
                                            Text(collection.title)
                                            Text("·")
                                            Text(card.dateText)
                                        }
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                                    }

                                    Spacer(minLength: RecapTheme.Spacing.small)
                                }
                                .padding(RecapTheme.Spacing.medium)
                                .recapCard(radius: RecapTheme.Radius.medium)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(RecapTheme.Spacing.large)
        }
        .background(RecapTheme.ColorToken.background)
        .navigationTitle("검색")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openCard(_ id: InformationCard.ID) {
        onAction(.openCard(id))
    }

    private var emptyState: some View {
        VStack(spacing: RecapTheme.Spacing.medium) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
            Text("검색 결과가 없어요")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            Text("다른 카드 제목이나 핵심 정보를 입력해보세요")
                .font(.caption)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .recapCard()
    }
}

#Preview {
    NavigationStack {
        SearchResultsView(
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}
