import SwiftUI

struct SearchTopBar: View {
    @Binding var query: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onClose) {
                RecapIconView(icon: .back, size: 24, color: Color.recapGray900)
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
}

struct SearchRecentContent: View {
    @Binding var recentKeywords: [String]
    let selectKeyword: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            header

            if recentKeywords.isEmpty {
                emptyRecentTerms
            } else {
                recentKeywordChips
            }

            SearchRecommendationGrid()
                .padding(.top, recentKeywords.isEmpty ? 120 : 69)
        }
    }

    private var header: some View {
        HStack {
            Text("최근 검색어")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray700)
            Spacer()
            if !recentKeywords.isEmpty {
                Button("전체삭제") { recentKeywords.removeAll() }
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapGray300)
                    .buttonStyle(.plain)
            }
        }
    }

    private var emptyRecentTerms: some View {
        Text("최근 검색내역이 없어요.")
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(Color.recapGray300)
            .frame(maxWidth: .infinity)
            .padding(.top, 56)
    }

    private var recentKeywordChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(recentKeywords, id: \.self) { keyword in
                    Button {
                        selectKeyword(keyword)
                    } label: {
                        RecapChip(configuration: .recentSearch(keyword))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollClipDisabled()
    }
}

struct SearchResultsList: View {
    let results: [InformationCard]
    let openCard: (InformationCard.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(results.count) recaps")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray500)

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
}

struct SearchIncompleteState: View {
    let title: String

    var body: some View {
        Text(title)
            .font(RecapFont.pretendard(size: 20, weight: .bold))
            .tracking(-0.4)
            .foregroundStyle(Color.recapUnimplemented)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchTargetCardEmptyState: View {
    var body: some View {
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
}
