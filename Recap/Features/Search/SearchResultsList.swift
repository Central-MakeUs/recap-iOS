import SwiftUI

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

#Preview("검색 결과 목록") {
    let results = SampleData.search("파스타").map(SearchResult.init(card:))

    SearchResultsList(
        totalCount: results.count,
        results: results,
        openCard: { _ in },
        loadNextPageIfNeeded: { _ in }
    )
    .background(Color.recapBackground)
}
