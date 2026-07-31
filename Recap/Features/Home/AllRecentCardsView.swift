import SwiftUI

struct AllRecentCardsContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var model: HomeFeatureModel
    @State private var loadedRevision: Int?
    let invalidationCenter: CardDataInvalidationCenter

    init(
        summaryLoader: any HomeSummaryLoading,
        captureMutator: any CaptureMutating,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.invalidationCenter = invalidationCenter
        _model = State(
            initialValue: HomeFeatureModel(
                summaryLoader: summaryLoader,
                captureMutator: captureMutator,
                invalidationCenter: invalidationCenter
            )
        )
    }

    var body: some View {
        AllRecentCardsView(
            cards: cards,
            onBack: dismiss.callAsFunction,
            onSearch: { router.navigate(.search) },
            onSelectCard: { router.navigate(.remoteCardDetail($0)) },
            onToggleFavorite: { try await model.toggleFavorite(cardID: $0) }
        )
        .task(id: reloadTrigger) {
            let revision = invalidationCenter.homeRevision
            if loadedRevision == nil {
                await model.loadIfNeeded()
            } else if loadedRevision != revision {
                await model.reload()
            }
            guard !Task.isCancelled else { return }
            loadedRevision = revision
        }
    }

    private var cards: [InformationCard] {
        guard case .loaded(let content) = model.state else {
            return []
        }
        return content.recentCards
    }

    private var reloadTrigger: Int {
        invalidationCenter.homeRevision
    }
}

struct AllRecentCardsView: View {
    let cards: [InformationCard]
    let onBack: () -> Void
    let onSearch: () -> Void
    let onSelectCard: (InformationCard) -> Void
    var onToggleFavorite: (InformationCard.ID) async throws -> Bool = { _ in false }

    @State private var favoriteUpdatingIDs: Set<InformationCard.ID> = []
    @State private var toast: RecapToastContent?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AllRecentCardsNavigationBar(
                onBack: onBack,
                onSearch: onSearch
            )
            .padding(.horizontal, 16)
            .padding(.top, 19)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    Text(
                        "\(Text("\(cards.count)").font(RecapFont.pretendard(size: 14, weight: .semibold)).foregroundStyle(Color.recapGray700)) recaps"
                    )
                        .font(RecapFont.pretendard(size: 14, weight: .regular))
                        .tracking(-0.28)
                        .foregroundStyle(Color.recapGray500)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 25)
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
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
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
            onBack: {},
            onSearch: {},
            onSelectCard: { _ in }
        )
    }
}
