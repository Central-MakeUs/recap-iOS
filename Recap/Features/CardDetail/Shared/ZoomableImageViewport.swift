import SwiftUI
import UIKit

/// 원본 이미지를 고정된 전체보기 영역 안에서 확대·이동한다.
///
/// 기본 크기는 위 62pt, 아래 25pt, 좌우 34pt의 경계 안에서 원본 비율을
/// 유지한다. 세로 제한으로 계산한 너비가 가로 경계를 넘으면 가로 제한을
/// 우선해, 이미지가 화면 밖으로 나가지 않는다.
struct ZoomableImageViewport: View {
    private static let magnificationTransformAnchor = UnitPoint(x: 0.5, y: 0)

    private enum Metric {
        static let topInset: CGFloat = 62
        static let bottomInset: CGFloat = 25
        static let horizontalInset: CGFloat = 34
        static let minimumScale: CGFloat = 1
        static let maximumScale: CGFloat = 10
        static let doubleTapScale: CGFloat = 2.5
    }

    let image: UIImage

    @State private var scale = Metric.minimumScale
    @State private var offset = CGSize.zero
    @State private var scaleAtMagnificationStart = Metric.minimumScale
    @State private var offsetAtMagnificationStart = CGSize.zero
    @State private var offsetAtDragStart = CGSize.zero
    @State private var isMagnifying = false
    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            let viewportSize = viewportSize(in: proxy.size)
            let imageSize = ZoomableImageLayout.renderedSize(
                imageSize: image.size,
                viewportSize: viewportSize
            )

            imageCard(size: imageSize)
                .scaleEffect(scale, anchor: Self.magnificationTransformAnchor)
                .offset(offset)
                .shadow(color: Color.black.opacity(0.13), radius: 8, x: 0, y: 1)
                .gesture(magnificationGesture(imageSize: imageSize, viewportSize: viewportSize))
                .simultaneousGesture(
                    panGesture(imageSize: imageSize, viewportSize: viewportSize),
                    isEnabled: scale > Metric.minimumScale && !isMagnifying
                )
                .onTapGesture(count: 2) {
                    toggleDoubleTapZoom(imageSize: imageSize, viewportSize: viewportSize)
                }
                // 세로로 긴 화면에서 짧은 이미지가 위로 붙어 아래가 크게 비지
                // 않도록 가운데에 둔다.
                .frame(
                    width: viewportSize.width,
                    height: viewportSize.height,
                    alignment: .center
                )
                .padding(.top, Metric.topInset)
                .padding(.bottom, Metric.bottomInset)
                .padding(.horizontal, Metric.horizontalInset)
        }
    }

    private func imageCard(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: CardDetailStyle.cornerRadius,
                style: .continuous
            )
            .fill(Color.recapBackground)

            Image(uiImage: image)
                .resizable()
                .frame(width: size.width, height: size.height)
        }
        .frame(width: size.width, height: size.height)
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
        .compositingGroup()
    }

    private func viewportSize(in size: CGSize) -> CGSize {
        CGSize(
            width: max(0, size.width - Metric.horizontalInset * 2),
            height: max(0, size.height - Metric.topInset - Metric.bottomInset)
        )
    }

    private func magnificationGesture(
        imageSize: CGSize,
        viewportSize: CGSize
    ) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if !isMagnifying {
                    isMagnifying = true
                    scaleAtMagnificationStart = scale
                    offsetAtMagnificationStart = offset
                }

                let nextScale = clampedScale(scaleAtMagnificationStart * value.magnification)
                let anchorAdjustedOffset = ZoomableImageLayout.offsetPreservingMagnificationAnchor(
                    initialOffset: offsetAtMagnificationStart,
                    imageSize: imageSize,
                    magnificationAnchor: value.startAnchor,
                    transformAnchor: Self.magnificationTransformAnchor,
                    initialScale: scaleAtMagnificationStart,
                    nextScale: nextScale
                )
                scale = nextScale
                offset = boundedOffset(
                    anchorAdjustedOffset,
                    imageSize: imageSize,
                    viewportSize: viewportSize,
                    scale: nextScale
                )
            }
            .onEnded { _ in
                isMagnifying = false
                offset = boundedOffset(
                    offset,
                    imageSize: imageSize,
                    viewportSize: viewportSize,
                    scale: scale
                )
            }
    }

    private func panGesture(
        imageSize: CGSize,
        viewportSize: CGSize
    ) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    offsetAtDragStart = offset
                }

                let candidate = CGSize(
                    width: offsetAtDragStart.width + value.translation.width,
                    height: offsetAtDragStart.height + value.translation.height
                )
                offset = boundedOffset(
                    candidate,
                    imageSize: imageSize,
                    viewportSize: viewportSize,
                    scale: scale
                )
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    private func toggleDoubleTapZoom(imageSize: CGSize, viewportSize: CGSize) {
        let nextScale = scale > Metric.minimumScale ? Metric.minimumScale : Metric.doubleTapScale
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = nextScale
            offset = boundedOffset(
                .zero,
                imageSize: imageSize,
                viewportSize: viewportSize,
                scale: nextScale
            )
        }
    }

    private func clampedScale(_ value: CGFloat) -> CGFloat {
        min(max(value, Metric.minimumScale), Metric.maximumScale)
    }

    private func boundedOffset(
        _ offset: CGSize,
        imageSize: CGSize,
        viewportSize: CGSize,
        scale: CGFloat
    ) -> CGSize {
        let horizontalLimit = max(0, (imageSize.width * scale - viewportSize.width) / 2)
        let minimumVerticalOffset = min(
            0,
            viewportSize.height - imageSize.height * scale
        )

        return CGSize(
            width: min(max(offset.width, -horizontalLimit), horizontalLimit),
            height: min(max(offset.height, minimumVerticalOffset), 0)
        )
    }
}

nonisolated enum ZoomableImageLayout {
    static func renderedSize(imageSize: CGSize, viewportSize: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }

        let scale = min(
            viewportSize.width / imageSize.width,
            viewportSize.height / imageSize.height
        )
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    static func offsetPreservingMagnificationAnchor(
        initialOffset: CGSize,
        imageSize: CGSize,
        magnificationAnchor: UnitPoint,
        transformAnchor: UnitPoint,
        initialScale: CGFloat,
        nextScale: CGFloat
    ) -> CGSize {
        let scaleDifference = initialScale - nextScale
        let anchorDistance = CGSize(
            width: (magnificationAnchor.x - transformAnchor.x) * imageSize.width,
            height: (magnificationAnchor.y - transformAnchor.y) * imageSize.height
        )

        return CGSize(
            width: initialOffset.width + scaleDifference * anchorDistance.width,
            height: initialOffset.height + scaleDifference * anchorDistance.height
        )
    }
}

#if DEBUG
#Preview("불투명 원본 이미지") {
    ZoomableImageViewport(image: UIImage(named: "InformationCardOriginal")!)
        .background(Color.recapBackground)
}

#Preview("투명 영역이 있는 이미지") {
    ZoomableImageViewport(image: UIImage(named: "HomeRecentReturn")!)
        .background(Color.recapBackground)
}
#endif
