import SwiftUI

struct AllRecentCardsContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        AllRecentCardsView(
            cards: cardStore.allCards(),
            onBack: dismiss.callAsFunction,
            onSearch: { router.navigate(.search) },
            onSelectCard: { router.navigate(.cardDetail($0)) }
        )
    }
}

struct AllRecentCardsView: View {
    let cards: [InformationCard]
    let onBack: () -> Void
    let onSearch: () -> Void
    let onSelectCard: (InformationCard.ID) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                AllRecentCardsNavigationBar(
                    onBack: onBack,
                    onSearch: onSearch
                )
                .padding(.horizontal, 16)
                .padding(.top, 19)

                Text("\(cards.count) recaps")
                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                    .tracking(-0.28)
                    .foregroundStyle(Color.recapGray500)
                    .padding(.horizontal, 16)
                    .padding(.top, 25)

                LazyVStack(spacing: 0) {
                    ForEach(cards) { card in
                        Button {
                            onSelectCard(card.id)
                        } label: {
                            AllRecentCardRow(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 7)
            }
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
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
            onSelectCard: PreviewActions.handleCardSelection
        )
    }
}
