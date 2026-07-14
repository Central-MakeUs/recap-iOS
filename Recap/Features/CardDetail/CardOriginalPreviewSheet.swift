import SwiftUI

struct CardOriginalPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    private var card: InformationCard? { cardStore.card(id: cardID) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: close) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: goHome) {
                    Image(systemName: "house")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 35)

            ScrollView(showsIndicators: true) {
                if let assetName = card?.detailImageAssetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, alignment: .top)
                } else {
                    CardImageFailureView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                }
            }
        }
        .background(RecapTheme.ColorToken.background)
        .statusBarHidden(false)
    }

    private func close() {
        dismiss()
    }

    private func goHome() {
        router.returnHome()
    }
}

#Preview("원본 이미지 전체 보기") {
    CardOriginalPreviewSheet(cardID: SampleData.cards[0].id)
        .environment(AppRouter())
        .environment(PreviewStores.recapCardStore())
}
