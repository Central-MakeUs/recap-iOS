import SwiftUI

struct SearchRecentContent: View {
    let recentKeywords: [String]
    let clearKeywords: () -> Void
    let selectKeyword: (String) -> Void
    let removeKeyword: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            header

            if recentKeywords.isEmpty {
                emptyRecentTerms
            } else {
                recentKeywordChips
            }
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
                Button("전체삭제", action: clearKeywords)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapGray500)
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
            .frame(height: 30)
    }

    private var recentKeywordChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(recentKeywords, id: \.self) { keyword in
                    RecapChip(
                        configuration: .recentSearch(keyword),
                        onSelect: { selectKeyword(keyword) },
                        onRemove: { removeKeyword(keyword) }
                    )
                }
            }
        }
        .scrollClipDisabled()
    }
}

#if DEBUG
#Preview("최근 검색어") {
    SearchRecentContent(
        recentKeywords: ["검색어", "검색어 01234", "검색검색검색"],
        clearKeywords: PreviewActions.noop,
        selectKeyword: { _ in },
        removeKeyword: { _ in }
    )
    .padding(16)
    .background(Color.recapBackground)
}

#Preview("최근 검색어 없음") {
    SearchRecentContent(
        recentKeywords: [],
        clearKeywords: PreviewActions.noop,
        selectKeyword: { _ in },
        removeKeyword: { _ in }
    )
    .padding(16)
    .background(Color.recapBackground)
}
#endif
