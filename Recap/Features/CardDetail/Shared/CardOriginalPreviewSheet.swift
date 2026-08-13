import SwiftUI

/// 원본 스크린샷 전체 보기 (07-01_스크린샷 전체보기).
///
/// 이미지는 위 62pt·아래 25pt·좌우 34pt 경계 안에서 원본 비율을 유지한다.
/// 상단에는 검정 40%→투명 그라디언트가 이미지 위에 깔려, 어떤 스크린샷
/// 위에서도 닫기 버튼 주변이 정리돼 보인다.
struct CardOriginalPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let card: Card
    var onRemoteImageFailure: (URL) -> Void = { _ in }

    private static let topGradientHeight: CGFloat = 118

    var body: some View {
        ZStack(alignment: .top) {
            imageContent

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.40), location: 0),
                    .init(color: Color.black.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Self.topGradientHeight)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            closeButton
                .padding(.leading, 16)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.recapBackground)
        .statusBarHidden(false)
    }

    private var closeButton: some View {
        Button(action: close) {
            RecapIconView(icon: .cancel, size: 24, color: Color.recapGray900)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle().inset(by: -10))
        .accessibilityLabel("닫기")
    }

    @ViewBuilder
    private var imageContent: some View {
        Group {
            if let assetName = card.detailImageAssetName,
               let image = UIImage(named: assetName) {
                ZoomableImageViewport(image: image)
            } else if let imageURL = card.originalImageURL ?? card.thumbnailURL {
                RecapRemoteImage(
                    url: imageURL,
                    onExpiredURL: onRemoteImageFailure,
                    imageContent: { image in
                        ZoomableImageViewport(image: image)
                    },
                    loadingContent: {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    },
                    failureContent: {
                        CardImageFailureView()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }
                )
            } else {
                CardImageFailureView()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
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
