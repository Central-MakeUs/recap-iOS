import Observation
import SwiftUI

struct AllRecentCardsContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var model: AllRecentCardsModel
    @State private var loadedRevision: Int?
    let invalidationCenter: CardDataInvalidationCenter

    init(
        summaryLoader: any HomeSummaryLoading,
        cardStore: CardStore,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.invalidationCenter = invalidationCenter
        _model = State(
            initialValue: AllRecentCardsModel(
                loader: summaryLoader,
                cardStore: cardStore
            )
        )
    }

    var body: some View {
        AllRecentCardsView(
            cards: cards,
            totalCount: model.totalCount,
            isLoadingNextPage: model.isLoadingNextPage,
            onBack: dismiss.callAsFunction,
            onSearch: { router.navigate(.search) },
            onSelectCard: { router.navigate(.remoteCardDetail($0.captureID)) },
            onEditCard: { router.navigate(.cardEdit($0.captureID)) },
            onLoadMore: model.loadNextPage
        )
        .task(id: reloadTrigger) {
            let revision = invalidationCenter.homeRevision
            if loadedRevision == nil { await model.load() }
            else if loadedRevision != revision { await model.reload() }
            guard !Task.isCancelled else { return }
            loadedRevision = revision
        }
    }

    private var cards: [CardSnapshot] {
        model.cards
    }

    private var reloadTrigger: Int {
        invalidationCenter.homeRevision
    }
}

struct AllRecentCardsView: View {
    @Environment(CardStore.self) private var cardStore

    let cards: [CardSnapshot]
    let totalCount: Int
    let isLoadingNextPage: Bool
    let onBack: () -> Void
    let onSearch: () -> Void
    let onSelectCard: (Card) -> Void
    let onEditCard: (Card) -> Void
    var onLoadMore: () async -> Void = {}

    @State private var toast: RecapToastContent?
    @State private var cardPendingDeletion: Card?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 제목 아래 16pt까지가 헤더다. 이 여백이 스크롤 영역에 있으면
            // 목록을 올렸을 때 카드가 제목에 바짝 붙는다.
            AllRecentCardsNavigationBar(
                onBack: onBack,
                onSearch: onSearch
            )
            .padding(.horizontal, 16)
            .padding(.top, 19)
            .padding(.bottom, 16)

            RecapSwipeCardCollection(
                items: rows,
                header: AnyView(recapCount),
                headerHeight: 36,
                isLoading: isLoadingNextPage,
                rowContent: { card in
                    AnyView(
                        AllRecentCardRow(
                            card: card,
                            onToggleFavorite: cardStore.updatingFavoriteIDs.contains(card.captureID)
                                ? nil
                                : { toggleFavorite(card) },
                            onRemoteImageFailure: { failedURL in
                                refreshImageURL(for: card, failedURL: failedURL)
                            }
                        )
                    )
                },
                actions: { card in
                    RecapSwipeAction.cardActions(
                        onEdit: { onEditCard(card) },
                        onDelete: { requestDeletion(of: card) }
                    )
                },
                onSelect: onSelectCard,
                onWillDisplay: { card in
                    guard shouldPrefetchNextPage(after: card) else { return }
                    Task { await onLoadMore() }
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .interactivePopGestureEnabled()
        .recapToast(toast)
        .recapConfirmationDialog(
            isPresented: Binding(
                get: { cardPendingDeletion != nil },
                set: { if !$0 { cardPendingDeletion = nil } }
            ),
            title: "스크린샷을 삭제할까요?",
            message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
            cancelTitle: "취소",
            confirmTitle: "삭제",
            // 다이얼로그가 확인 직전에 isPresented를 내리면서 카드가 비워지므로,
            // 그리는 시점의 카드를 클로저에 담아둔다.
            onConfirm: { [card = cardPendingDeletion] in
                guard let card else { return }
                delete(card)
            }
        )
        .task(id: toast) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    /// 응답은 순서·소속만 정하고, 그리기는 스토어의 공유 인스턴스로 한다.
    /// 모델이 적재 시점에 upsert하므로 스토어 조회는 실패하지 않는다.
    private var rows: [Card] {
        cards.compactMap { cardStore.card(withCaptureID: $0.captureID) }
    }

    private var recapCount: some View {
        Text(
            "\(Text("\(totalCount)").font(RecapFont.pretendard(size: 14, weight: .semibold)).foregroundStyle(Color.recapGray700)) recaps"
        )
        .font(RecapFont.pretendard(size: 14, weight: .regular))
        .tracking(-0.28)
        .foregroundStyle(Color.recapGray500)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 7)
    }

    private func shouldPrefetchNextPage(after card: Card) -> Bool {
        guard let index = cards.firstIndex(where: { $0.captureID == card.captureID }) else {
            return false
        }
        return index >= max(cards.count - 5, 0)
    }

    private func toggleFavorite(_ card: Card) {
        Task {
            guard let content = await cardStore.toggleFavoriteReturningToast(card) else { return }
            toast = content
        }
    }

    private func requestDeletion(of card: Card) {
        cardPendingDeletion = card
    }

    private func refreshImageURL(for card: Card, failedURL: URL) {
        Task {
            await cardStore.refreshImageURL(for: card, failedURL: failedURL)
        }
    }

    /// 삭제는 상세 화면과 같은 길로 보낸다. 스토어가 내리면 홈·검색도 함께 갱신된다.
    private func delete(_ card: Card) {
        Task {
            do {
                try await cardStore.delete(card)
            } catch {
                toast = RecapToastMessage.screenshotDeleteFailed.content
            }
        }
    }
}

private struct AllRecentCardsNavigationBar: View {
    let onBack: () -> Void
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                RecapIconView(icon: .back, size: 24, color: Color.recapGray900)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle().inset(by: -10))
            .accessibilityLabel("뒤로가기")

            Text("최근 정리된 스크린샷")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
                .padding(.leading, 13)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            Button(action: onSearch) {
                RecapIconView(icon: .search, size: 24, color: Color.recapGray900)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle().inset(by: -10))
            .accessibilityLabel("검색")
        }
        .frame(height: 25)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AllRecentCardsView(
            cards: SampleData.recentCards,
            totalCount: SampleData.recentCards.count,
            isLoadingNextPage: false,
            onBack: {},
            onSearch: {},
            onSelectCard: { _ in },
            onEditCard: { _ in }
        )
    }
    .environment(PreviewStores.cardStore())
}
#endif

@MainActor
@Observable
private final class AllRecentCardsModel {
    private static let pageSize = 20

    private let loader: any HomeSummaryLoading
    private let cardStore: CardStore?

    private(set) var cards: [CardSnapshot] = [] {
        didSet { cardStore?.upsert(cards) }
    }
    private(set) var totalCount = 0
    private(set) var hasNext = false
    private(set) var isLoadingNextPage = false
    private var nextPage = 0

    init(
        loader: any HomeSummaryLoading,
        cardStore: CardStore? = nil
    ) {
        self.loader = loader
        self.cardStore = cardStore
    }

    func load() async {
        nextPage = 0
        cards = []
        await requestPage(reset: true)
    }

    func reload() async {
        await load()
    }

    func loadNextPage() async {
        guard hasNext, !isLoadingNextPage else { return }
        await requestPage(reset: false)
    }

    private func requestPage(reset: Bool) async {
        guard !isLoadingNextPage else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let page = try await loader.fetchRecentCaptures(
                page: nextPage,
                size: Self.pageSize
            )
            cards = reset ? page.cards : cards + page.cards
            totalCount = page.totalCount
            hasNext = page.hasNext
            nextPage += 1
        } catch is CancellationError {
            return
        } catch {
            if reset {
                cards = []
                totalCount = 0
                hasNext = false
            }
        }
    }
}
