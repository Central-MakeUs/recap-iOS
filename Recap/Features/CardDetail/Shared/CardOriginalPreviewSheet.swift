import SwiftUI

struct CardOriginalPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let card: InformationCard
    var onRemoteImageFailure: (URL) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: close) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color.recapGray900)
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
                } else if let imageURL = card.originalImageURL ?? card.thumbnailURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                        case .failure:
                            CardImageFailureView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .task {
                                    onRemoteImageFailure(imageURL)
                                }
                        @unknown default:
                            CardImageFailureView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                } else {
                    CardImageFailureView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                }
            }
        }
        .background(Color.recapBackground)
        .statusBarHidden(false)
    }

    private func close() {
        dismiss()
    }
}

#Preview("원본 이미지 전체 보기") {
    CardOriginalPreviewSheet(card: SampleData.cards[0])
}
