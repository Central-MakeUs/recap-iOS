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
        captureMutator: any CaptureMutating,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.invalidationCenter = invalidationCenter
        _model = State(
            initialValue: AllRecentCardsModel(
                loader: summaryLoader,
                captureMutator: captureMutator,
                invalidationCenter: invalidationCenter
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
            onSelectCard: { router.navigate(.remoteCardDetail($0)) },
            onToggleFavorite: { try await model.toggleFavorite(cardID: $0) },
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

    private var cards: [InformationCard] {
        model.cards
    }

    private var reloadTrigger: Int {
        invalidationCenter.homeRevision
    }
}

struct AllRecentCardsView: View {
    let cards: [InformationCard]
    let totalCount: Int
    let isLoadingNextPage: Bool
    let onBack: () -> Void
    let onSearch: () -> Void
    let onSelectCard: (InformationCard) -> Void
    var onToggleFavorite: (InformationCard.ID) async throws -> Bool = { _ in false }
    var onLoadMore: () async -> Void = {}

    @State private var favoriteUpdatingIDs: Set<InformationCard.ID> = []
    @State private var toast: RecapToastContent?

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

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    Text(
                        "\(Text("\(totalCount)").font(RecapFont.pretendard(size: 14, weight: .semibold)).foregroundStyle(Color.recapGray700)) recaps"
                    )
                        .font(RecapFont.pretendard(size: 14, weight: .regular))
                        .tracking(-0.28)
                        .foregroundStyle(Color.recapGray500)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 9)
                        .padding(.bottom, 7)

                    ForEach(cards) { card in
                        AllRecentCardRow(
                            card: card,
                            onToggleFavorite: favoriteUpdatingIDs.contains(card.id)
                                ? nil
                                : { toggleFavorite(card.id) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectCard(card)
                        }
                        .task {
                            guard card.id == cards.last?.id else { return }
                            await onLoadMore()
                        }
                    }

                    if isLoadingNextPage {
                        ProgressView()
                            .tint(Color.recapBlue300)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .interactivePopGestureEnabled()
        .recapToast(toast)
        .task(id: toast) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    private func toggleFavorite(_ id: InformationCard.ID) {
        guard favoriteUpdatingIDs.insert(id).inserted else { return }

        Task {
            defer { favoriteUpdatingIDs.remove(id) }

            do {
                let isFavorite = try await onToggleFavorite(id)
                toast = RecapToastContent(
                    style: .success,
                    message: isFavorite
                        ? "즐겨찾기에 추가했어요."
                        : "즐겨찾기에서 해제했어요."
                )
            } catch {
                toast = RecapToastContent(
                    style: .error,
                    message: "즐겨찾기를 변경하지 못했어요. 다시 시도해주세요."
                )
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

#Preview {
    NavigationStack {
        AllRecentCardsView(
            cards: SampleData.recentCards,
            totalCount: SampleData.recentCards.count,
            isLoadingNextPage: false,
            onBack: {},
            onSearch: {},
            onSelectCard: { _ in }
        )
    }
}

@MainActor
@Observable
private final class AllRecentCardsModel {
    private static let pageSize = 20

    private let loader: any HomeSummaryLoading
    private let captureMutator: any CaptureMutating
    private let invalidationCenter: CardDataInvalidationCenter

    private(set) var cards: [InformationCard] = []
    private(set) var totalCount = 0
    private(set) var hasNext = false
    private(set) var isLoadingNextPage = false
    private var nextPage = 0

    init(
        loader: any HomeSummaryLoading,
        captureMutator: any CaptureMutating,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.loader = loader
        self.captureMutator = captureMutator
        self.invalidationCenter = invalidationCenter
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

    func toggleFavorite(cardID: InformationCard.ID) async throws -> Bool {
        guard
            let index = cards.firstIndex(where: { $0.id == cardID }),
            let captureID = cards[index].captureID
        else {
            throw CaptureLifecycleError.missingCaptureID
        }

        let previous = cards[index].isFavorite
        let target = !previous
        cards[index] = cards[index].with(isFavorite: target)

        do {
            try await captureMutator.updateFavorite(captureID: captureID, isFavorite: target)
            invalidationCenter.invalidate(.favoriteChanged)
            return target
        } catch {
            cards[index] = cards[index].with(isFavorite: previous)
            throw error
        }
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
