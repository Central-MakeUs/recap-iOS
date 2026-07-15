import SwiftUI

struct CardOriginalPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let card: InformationCard

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
            }
            .padding(.horizontal, 16)
            .frame(height: 35)

            ScrollView(showsIndicators: true) {
                if let assetName = card.detailImageAssetName {
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
}

#Preview("원본 이미지 전체 보기") {
    CardOriginalPreviewSheet(card: SampleData.cards[0])
}
