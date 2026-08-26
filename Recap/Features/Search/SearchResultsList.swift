import SwiftUI

struct SearchResultsList: View {
    @Environment(CardStore.self) private var cardStore

    let totalCount: Int
    let results: [SearchResult]
    let openCard: (Int64) -> Void
    let loadNextPageIfNeeded: (SearchResult.ID) -> Void
    var onToggleFavorite: ((Card) -> Void)?
    var onEditCard: ((Card) -> Void)?
    var onRequestDeletion: ((Card) -> Void)?

    var body: some View {
        RecapSwipeCardCollection(
            items: results,
            header: AnyView(resultCount),
            headerHeight: 25,
            isLoading: false,
            horizontalInset: 16,
            topInset: 18,
            bottomInset: 40,
            rowContent: { result in
                guard let card = cardStore.card(withCaptureID: result.captureID) else {
                    return AnyView(EmptyView())
                }
                return AnyView(
                    RecapInformationCardRow(
                        card: card,
                        titleText: result.title.styledText(
                            defaultColor: Color.recapGray900
                        ),
                        summaryText: result.summary.styledText(
                            defaultColor: Color.recapGray500
                        ),
                        onToggleFavorite: favoriteAction(for: card),
                        onRemoteImageFailure: { failedURL in
                            refreshImageURL(for: card, failedURL: failedURL)
                        }
                    )
                )
            },
            actions: { result in
                guard
                    let card = cardStore.card(withCaptureID: result.captureID),
                    onEditCard != nil || onRequestDeletion != nil
                else { return [] }
                return RecapSwipeAction.cardActions(
                    onEdit: { onEditCard?(card) },
                    onDelete: { onRequestDeletion?(card) }
                )
            },
            onSelect: { result in
                openCard(result.captureID)
            },
            onWillDisplay: { result in
                loadNextPageIfNeeded(result.id)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultCount: some View {
        Text("\(totalCount) recaps")
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(Color.recapGray500)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

    private func refreshImageURL(for card: Card, failedURL: URL) {
        Task {
            await cardStore.refreshImageURL(for: card, failedURL: failedURL)
        }
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
