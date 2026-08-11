import SwiftUI

struct SearchResultsList: View {
    let totalCount: Int
    let results: [SearchResult]
    let openCard: (InformationCard.ID) -> Void
    let loadNextPageIfNeeded: (SearchResult.ID) -> Void
    var onToggleFavorite: ((InformationCard.ID) -> Void)?
    var favoriteUpdatingIDs: Set<InformationCard.ID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(totalCount) recaps")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray500)

            VStack(spacing: 0) {
                ForEach(results) { result in
                    RecapInformationCardRow(
                        card: result.card,
                        titleText: result.title.styledText(
                            defaultColor: Color.recapGray900
                        ),
                        summaryText: result.summary.styledText(
                            defaultColor: Color.recapGray500
                        ),
                        onToggleFavorite: favoriteAction(for: result.card.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openCard(result.card.id)
                    }
                    .onAppear {
                        loadNextPageIfNeeded(result.id)
                    }
                }
            }
        }
        .padding(.top, 1)
    }

    private func favoriteAction(for cardID: InformationCard.ID) -> (() -> Void)? {
        guard let onToggleFavorite, !favoriteUpdatingIDs.contains(cardID) else {
            return nil
        }
        return { onToggleFavorite(cardID) }
    }
}

#if DEBUG
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
#endif
