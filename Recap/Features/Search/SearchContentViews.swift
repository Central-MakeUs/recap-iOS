import SwiftUI

struct SearchTopBar: View {
    @Binding var query: String
    let onSubmit: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onClose) {
                RecapIconView(icon: .back, size: 24, color: Color.recapGray900)
                    .frame(width: 24, height: 44)
            }
            .buttonStyle(.plain)

            SearchBar(
                text: $query,
                showsClearButton: true,
                onSubmit: onSubmit
            )
                .frame(height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

struct SearchRecentContent: View {
    let recentKeywords: [String]
    let clearKeywords: () -> Void
    let selectKeyword: (String) -> Void

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
    let totalCount: Int
    let results: [SearchResult]
    let openCard: (InformationCard.ID) -> Void
    let loadNextPageIfNeeded: (SearchResult.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(totalCount) recaps")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray500)

            VStack(spacing: 0) {
                ForEach(results) { result in
                    Button {
                        openCard(result.card.id)
                    } label: {
                        RecapInformationCardRow(
                            card: result.card,
                            titleText: result.title.styledText(
                                defaultColor: Color.recapGray900
                            ),
                            summaryText: result.summary.styledText(
                                defaultColor: Color.recapGray500
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        loadNextPageIfNeeded(result.id)
                    }
                }
            }
        }
        .padding(.top, 1)
    }
}

struct SearchNoResultsView: View {
    var body: some View {
        VStack(spacing: 0) {
            SearchNoResultsIllustration()

            Text("검색 결과가 없어요")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 26)

            Text("다른 키워드로 다시 검색해보세요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 13)

            Spacer(minLength: 0)
        }
        .padding(.top, 208)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SearchNoResultsIllustration: View {
    var body: some View {
        Image("SearchEmptyIllustration")
            .resizable()
            .scaledToFit()
            .frame(width: 123, height: 83, alignment: .topLeading)
            .accessibilityHidden(true)
    }
}

private extension SearchHighlightedString {
    func styledText(defaultColor: Color) -> Text {
        var attributedString = AttributedString()

        for segment in segments {
            var part = AttributedString(segment.text)
            part.foregroundColor = segment.isHighlighted
                ? Color.recapBlue300
                : defaultColor
            attributedString.append(part)
        }

        return Text(attributedString)
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

#Preview("검색 결과 없음") {
    SearchNoResultsView()
        .background(Color.recapBackground)
}
