import SwiftUI

struct SearchResultsView: View {
    @State private var query = "성수동"

    private var results: [InformationCard] {
        SampleData.search(query)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                SearchBar(text: $query, showsClearButton: true)

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
                            NavigationLink(value: AppRoute.cardDetail(card.id)) {
                                InfoCardRow(card: card)
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
    NavigationStack { SearchResultsView() }
}
