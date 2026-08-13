import SwiftUI

struct SearchResultsList: View {
    @Environment(CardStore.self) private var cardStore

    let totalCount: Int
    let results: [SearchResult]
    let openCard: (Int64) -> Void
    let loadNextPageIfNeeded: (SearchResult.ID) -> Void
    var onToggleFavorite: ((Card) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(totalCount) recaps")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray500)

            VStack(spacing: 0) {
                ForEach(results) { result in
                    // 모델이 적재 시점에 upsert하므로 스토어 조회는 실패하지 않는다.
                    if let card = cardStore.card(withCaptureID: result.captureID) {
                        RecapInformationCardRow(
                            card: card,
                            titleText: result.title.styledText(
                                defaultColor: Color.recapGray900
                            ),
                            summaryText: result.summary.styledText(
                                defaultColor: Color.recapGray500
                            ),
                            onToggleFavorite: favoriteAction(for: card)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openCard(card.captureID)
                        }
                        .onAppear {
                            loadNextPageIfNeeded(result.id)
                        }
                    }
                }
            }
        }
        .padding(.top, 1)
    }

    private func favoriteAction(for card: Card) -> (() -> Void)? {
        guard
            let onToggleFavorite,
            !cardStore.updatingFavoriteIDs.contains(card.captureID)
        else {
            return nil
        }
        return { onToggleFavorite(card) }
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
    .environment(PreviewStores.cardStore())
}
#endif
