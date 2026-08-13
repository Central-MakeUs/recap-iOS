import SwiftUI

struct CardOriginalPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let card: Card
    var onRemoteImageFailure: (URL) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: close) {
                    RecapIconView(icon: .cancel, size: 24, color: Color.recapGray900)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle().inset(by: -10))
                .accessibilityLabel("닫기")

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 35)

            ScrollView(showsIndicators: true) {
                imageContent
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: CardDetailStyle.cornerRadius,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: CardDetailStyle.cornerRadius,
                            style: .continuous
                        )
                        .strokeBorder(Color.recapGray100, lineWidth: 0.5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
        }
        .background(Color.recapBackground)
        .statusBarHidden(false)
    }

    @ViewBuilder
    private var imageContent: some View {
        Group {
                if let assetName = card.detailImageAssetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, alignment: .top)
                } else if let imageURL = card.originalImageURL ?? card.thumbnailURL {
                    RecapRemoteImage(
                        url: imageURL,
                        onExpiredURL: onRemoteImageFailure,
                        imageContent: { image in
                            image
                                .resizable()
                                .scaledToFit()
                        },
                        loadingContent: {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                        },
                        failureContent: {
                            CardImageFailureView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .top)
                } else {
                    CardImageFailureView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                }
        }
    }

    private func close() {
        dismiss()
    }
}

#if DEBUG
#Preview("원본 이미지 전체 보기") {
    CardOriginalPreviewSheet(card: Card(snapshot: SampleData.cards[0]))
}
#endif
