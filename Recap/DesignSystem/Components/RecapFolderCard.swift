import SwiftUI

enum RecapFolderThumbnailState: Equatable {
    case filled
    case empty
}

struct RecapFolderCard: View {
    let title: String
    let count: Int
    var thumbnailState: RecapFolderThumbnailState = .filled
    var kind: CollectionKind = .shopping
    var tint: Color?

    var body: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)
        let fill = tint ?? display.dotColor
        let foreground = display.textColor

        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 7.41, style: .continuous)
                    .fill(thumbnailState == .filled ? fill : Color.recapGray100)
                    .frame(width: 93, height: 71)
                    .offset(x: 0, y: 0)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(thumbnailState == .filled ? 1 : 0.78))
                    .frame(width: 85, height: 63)
                    .offset(x: 4, y: 4)

                RecapFolderVector(tint: fill)
                    .frame(width: 94, height: 79)
                    .offset(x: 5, y: 9)

                Image(systemName: display.symbolName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(foreground)
                    .frame(width: 30, height: 30)
                    .background(Color.recapBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .offset(x: 13, y: 17)

            }
            .frame(width: 99, height: 88, alignment: .topLeading)
            .opacity(thumbnailState == .filled ? 1 : 0.62)

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
            .frame(width: 99, height: 40, alignment: .top)
        }
        .frame(width: 99, height: 138, alignment: .top)
    }
}

struct RecapFolderListRow: View {
    let title: String
    let subtitle: String
    let count: Int
    let kind: CollectionKind

    var body: some View {
        HStack(spacing: 27) {
            RecapCategoryIcon(kind: kind)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(RecapFont.pretendard(size: 16, weight: .semibold))
                        .tracking(-0.32)
                        .foregroundStyle(Color.black)

                    Spacer(minLength: 8)

                    Text("\(count) Recaps")
                        .font(RecapFont.pretendard(size: 12, weight: .medium))
                        .tracking(-0.24)
                        .foregroundStyle(Color.recapGray300)
                }

                Text(subtitle)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapGray500)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .frame(height: 85)
        .background(Color.recapBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.recapGray100)
                .frame(height: 1)
        }
    }
}

private struct RecapFolderVector: View {
    let tint: Color
    private let gradientOpacity = 0.699999988079071

    var body: some View {
        RecapFolderVectorShape()
            .fill(folderGradient)
            .overlay {
                RecapFolderVectorShape()
                    .stroke(Color.white, lineWidth: 1)
            }
    }

    private var folderGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.white.opacity(gradientOpacity), location: 0),
                .init(color: tint.opacity(gradientOpacity), location: 1)
            ],
            startPoint: UnitPoint(x: 0.499999880844772, y: -0.3310865784233596),
            endPoint: UnitPoint(x: 0.4999998808447753, y: 2.0348124794950126)
        )
    }
}

private struct RecapFolderVectorShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 94
        let scaleY = rect.height / 79
        let bodyTop = 10 * scaleY
        let radius = 10 * min(scaleX, scaleY)
        let tabEndX = 37 * scaleX
        let tabSlopeEndX = 47 * scaleX
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + tabEndX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + tabSlopeEndX, y: rect.minY + bodyTop),
            control1: CGPoint(x: rect.minX + tabEndX + 3.5 * scaleX, y: rect.minY),
            control2: CGPoint(x: rect.minX + tabSlopeEndX - 3.5 * scaleX, y: rect.minY + bodyTop)
        )
        path.addLine(to: CGPoint(x: rect.minX + width - radius, y: rect.minY + bodyTop))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width, y: rect.minY + bodyTop + radius),
            control: CGPoint(x: rect.minX + width, y: rect.minY + bodyTop)
        )
        path.addLine(to: CGPoint(x: rect.minX + width, y: rect.minY + height - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width - radius, y: rect.minY + height),
            control: CGPoint(x: rect.minX + width, y: rect.minY + height)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.minY + height))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + height - radius),
            control: CGPoint(x: rect.minX, y: rect.minY + height)
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

#Preview("폴더") {
    ZStack {
        Color.recapBackground.ignoresSafeArea()
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(99), spacing: 19), count: 3), spacing: 39) {
            ForEach(CollectionKind.folderCases) { kind in
                let display = RecapPresentation.collectionDisplay(for: kind)
                RecapFolderCard(
                    title: display.title,
                    count: display.sampleCount,
                    thumbnailState: kind == .other ? .empty : .filled,
                    kind: kind
                )
            }
        }
        .padding()
    }
}
