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
    enum ScreenMode: Hashable {
        case normal
        case failureBlank
        case targetCardEmpty
    }

    @Environment(\.dismiss) private var dismiss
    @State private var query: String
    @State private var recentKeywords: [String]

    let mode: ScreenMode
    let search: (String) -> [InformationCard]
    let onAction: (SearchAction) -> Void

    init(
        initialQuery: String = "",
        recentKeywords: [String] = ["검색어", "검색어 01234", "검색검색검색", "검색어검색어"],
        mode: ScreenMode = .normal,
        search: @escaping (String) -> [InformationCard],
        onAction: @escaping (SearchAction) -> Void
    ) {
        _query = State(initialValue: initialQuery)
        _recentKeywords = State(initialValue: recentKeywords)
        self.mode = mode
        self.search = search
        self.onAction = onAction
    }

    private var results: [InformationCard] {
        search(query)
    }

    var body: some View {
        VStack(spacing: 0) {
            topSearchBar

            switch mode {
            case .normal:
                normalContent
            case .failureBlank:
                failureBlankContent
            case .targetCardEmpty:
                targetCardEmptyContent
            }
        }
        .background(RecapTheme.ColorToken.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topSearchBar: some View {
        HStack(spacing: 8) {
            Button(action: close) {
                RecapIconView(icon: .back, size: 24, color: RecapTheme.ColorToken.textPrimary)
                    .frame(width: 24, height: 44)
            }
            .buttonStyle(.plain)

            SearchBar(text: $query, showsClearButton: true)
                .frame(height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var normalContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                if query.isEmpty {
                    recentSearchContent
                } else if results.isEmpty {
                    noResultsContent
                } else {
                    resultsContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
    }

    private var recentSearchContent: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack {
                Text("최근 검색어")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(RecapTheme.ColorToken.textBody)
                Spacer()
                if !recentKeywords.isEmpty {
                    Button("전체삭제") { recentKeywords.removeAll() }
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                        .buttonStyle(.plain)
                }
            }

            if recentKeywords.isEmpty {
                Text("최근 검색내역이 없어요.")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 56)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recentKeywords, id: \.self) { keyword in
                            Button {
                                query = keyword == "검색어 01234" ? "숙소예약" : keyword
                            } label: {
                                Text(keyword)
                                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                                    .tracking(-0.28)
                                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                                    .padding(.horizontal, 12)
                                    .frame(height: 30)
                                    .background(RecapTheme.ColorToken.controlFill)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollClipDisabled()
            }

            SearchRecommendationGrid()
                .padding(.top, recentKeywords.isEmpty ? 120 : 69)
        }
    }

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(results.count) recaps")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)

            VStack(spacing: 0) {
                ForEach(results) { card in
                    Button {
                        openCard(card.id)
                    } label: {
                        RecapSearchResultCard(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 1)
    }

    private var noResultsContent: some View {
        unimplementedSearchState("미구현: 검색 결과 없음")
    }

    private var failureBlankContent: some View {
        unimplementedSearchState("미구현: 검색 실패")
    }

    private var targetCardEmptyContent: some View {
        VStack(spacing: 18) {
            Spacer()
            RecapIncompleteCallout(
                title: "대상 카드 없음",
                message: "표시할 카드가 없습니다. 데이터를 불러온 뒤 다시 확인해주세요."
            )
            .padding(.horizontal, 28)
            Spacer()
        }
    }

    private func unimplementedSearchState(_ title: String) -> some View {
        Text(title)
            .font(RecapFont.pretendard(size: 20, weight: .bold))
            .tracking(-0.4)
            .foregroundStyle(Color(red: 1, green: 0, blue: 0.72))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func close() { dismiss() }
    private func openCard(_ id: InformationCard.ID) { onAction(.openCard(id)) }
}

private struct SearchRecommendationGrid: View {
    private let recommendations = Array(repeating: "정리된 제목", count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RecapTheme.ColorToken.warning)
                    .frame(width: 24, height: 24)
                Text("이런 내용까지 검색가능해요!")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textBody)
            }

            VStack(spacing: 24) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 99) {
                        recommendationItem(recommendations[row * 2])
                        recommendationItem(recommendations[row * 2 + 1])
                    }
                }
            }
            .padding(.leading, 4)
        }
    }

    private func recommendationItem(_ title: String) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(RecapTheme.ColorToken.thumbnail)
                .frame(width: 16, height: 16)
            Text(title)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
        }
        .frame(width: 89, height: 18, alignment: .leading)
    }
}

#Preview("Search home - recent terms") {
    NavigationStack {
        SearchResultsView(
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search home - no recent terms") {
    NavigationStack {
        SearchResultsView(
            recentKeywords: [],
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search results") {
    NavigationStack {
        SearchResultsView(
            initialQuery: "숙소예약",
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search empty - incomplete") {
    NavigationStack {
        SearchResultsView(
            initialQuery: "없는검색어",
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search failure - incomplete") {
    NavigationStack {
        SearchResultsView(
            mode: .failureBlank,
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}
