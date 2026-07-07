import SwiftUI

struct CardEditPlaceholderView: View {
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    private var card: InformationCard? {
        cardStore.card(id: cardID)
    }

    var body: some View {
        VStack(spacing: RecapTheme.Spacing.large) {
            Image(systemName: "square.and.pencil")
                .font(.title.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.primary)
                .frame(width: 64, height: 64)
                .background(RecapTheme.ColorToken.primaryLight)
                .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))

            VStack(spacing: RecapTheme.Spacing.small) {
                Text(card?.title ?? "카드 수정")
                    .font(.title3.weight(.black))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                Text("수정 화면은 다음 실제 UI 단계에서 교체할 수 있도록 라우트만 먼저 연결했습니다.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .padding(.horizontal, RecapTheme.Spacing.xLarge)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .navigationTitle("카드 수정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CardEditPlaceholderView(cardID: SampleData.cards[0].id)
            .environment(PreviewStores.recapCardStore())
    }
}
