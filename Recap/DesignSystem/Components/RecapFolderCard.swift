import SwiftUI

struct RecapFolderCard: View {
    let title: String
    let count: Int
    var kind: CollectionKind = .shopping

    var body: some View {
        VStack(spacing: 10) {
            RecapFolderArtwork(kind: kind)

            VStack(spacing: 3) {
                Text(title)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
                    .foregroundStyle(Color.recapGray900)
                    .lineLimit(1)

                Text("\(count) Recaps")
                    .font(RecapFont.pretendard(size: 12, weight: .medium))
                    .tracking(-0.24)
                    .foregroundStyle(Color.recapGray300)
            }
            .frame(width: 99)
        }
        .frame(width: 99, height: 138, alignment: .top)
    }
}

private struct RecapFolderArtwork: View {
    let kind: CollectionKind

    var body: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 7.409886837005615, style: .continuous)
                .fill(Color.recapFolderBack)
                .frame(width: 93, height: 71)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.white)
                .frame(width: 85, height: 63)
                .offset(x: 4, y: 4)

            RecapFolderFront()
                .frame(width: 94, height: 79)
                .offset(x: 5, y: 9)

            if kind != .other {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.recapBackground)
                    .frame(width: 30, height: 30)
                    .overlay {
                        RecapIconView(
                            icon: RecapIcon.categoryIcon(for: kind),
                            size: 16,
                            color: display.dotColor
                        )
                    }
                    .offset(x: 13, y: 17)
            }
        }
        .frame(width: 99, height: 88, alignment: .topLeading)
    }
}

private struct RecapFolderFront: View {
    var body: some View {
        RecapFolderFrontShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color.recapFolderBack,
                        Color.white
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            )
            .overlay {
                RecapFolderFrontShape()
                    .stroke(Color.white, lineWidth: 1)
            }
    }
}

private struct RecapFolderFrontShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 94
        let scaleY = rect.height / 79
        let bodyTop = 10 * scaleY
        let radius = 10 * min(scaleX, scaleY)
        let tabEndX = 37 * scaleX
        let tabSlopeEndX = 47 * scaleX

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + tabEndX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + tabSlopeEndX, y: rect.minY + bodyTop),
            control1: CGPoint(x: rect.minX + tabEndX + 3.5 * scaleX, y: rect.minY),
            control2: CGPoint(
                x: rect.minX + tabSlopeEndX - 3.5 * scaleX,
                y: rect.minY + bodyTop
            )
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY + bodyTop))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + bodyTop + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY + bodyTop)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

#if DEBUG
#Preview("폴더 카드") {
    ZStack {
        Color.recapBackground.ignoresSafeArea()
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(99), spacing: 23), count: 3),
            spacing: 15
        ) {
            ForEach(CollectionKind.allCases) { kind in
                RecapFolderCard(
                    title: kind.displayTitle,
                    count: SampleData.sampleCount(for: kind),
                    kind: kind
                )
            }
        }
        .padding()
    }
}
#endif
