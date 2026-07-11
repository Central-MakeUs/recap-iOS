import SwiftUI

enum ArchiveCategoryThumbnailState: Equatable {
    case filled
    case empty
}

struct ArchiveCategoryCard: View {
    let title: String
    let count: Int
    var thumbnailState: ArchiveCategoryThumbnailState = .filled
    var kind: CollectionKind = .shopping
    var tint: Color? = nil

    var body: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)
        let fill = tint ?? display.dotColor
        let foreground = display.textColor

        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 7.41, style: .continuous)
                    .fill(thumbnailState == .filled ? fill : RecapTheme.ColorToken.border)
                    .frame(width: 93, height: 71)
                    .offset(x: 0, y: 0)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(thumbnailState == .filled ? 1 : 0.78))
                    .frame(width: 85, height: 63)
                    .offset(x: 4, y: 4)

                ArchiveCategoryFolderVector(tint: fill)
                    .frame(width: 94, height: 79)
                    .offset(x: 5, y: 9)

                Image(systemName: display.symbolName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(foreground)
                    .frame(width: 16, height: 16)
                    .offset(x: 15, y: 19)

                Text("\(count)")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.center)
                    .frame(width: countTextWidth, height: 18)
                    .offset(x: countTextX, y: 60)

                Text("recaps")
                    .font(RecapFont.pretendard(size: 10, weight: .medium))
                    .tracking(-0.2)
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.center)
                    .frame(width: 30, height: 14)
                    .offset(x: 31, y: 63)
            }
            .frame(width: 99, height: 88, alignment: .topLeading)
            .opacity(thumbnailState == .filled ? 1 : 0.62)

            Text(title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .lineLimit(1)
                .frame(width: 99)
        }
        .frame(width: 99, height: 118, alignment: .top)
    }

    private var countTextWidth: CGFloat {
        if count < 10 { return 6 }
        if count < 20 { return 14 }
        return 16
    }

    private var countTextX: CGFloat {
        count < 10 ? 19 : (count < 20 ? 15 : 14)
    }
}

struct ArchiveCategoryListCard: View {
    let title: String
    let subtitle: String
    let count: Int
    let kind: CollectionKind

    var body: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)

        HStack(spacing: 27) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6.68, style: .continuous)
                    .fill(display.dotColor)
                    .frame(width: 59, height: 45)
                RoundedRectangle(cornerRadius: 4.51, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 55, height: 40)
                    .offset(x: 3, y: 2.5)
                ArchiveCategoryFolderVector(tint: display.dotColor)
                    .frame(width: 64, height: 55.65)
                    .offset(x: 0, y: 0)
                Image(systemName: display.symbolName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(display.textColor)
                    .frame(width: 10, height: 10)
                    .offset(x: 8, y: 10)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(count)")
                        .font(RecapFont.pretendard(size: 12, weight: .medium))
                    Text("recaps")
                        .font(RecapFont.pretendard(size: 10, weight: .medium))
                }
                .tracking(-0.2)
                .foregroundStyle(display.textColor)
                .offset(x: 8, y: 35)
            }
            .frame(width: 64, height: 55.65)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(Color.black)
                Text(subtitle)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .frame(height: 85)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RecapTheme.ColorToken.border)
                .frame(height: 1)
        }
    }
}

private struct ArchiveCategoryFolderVector: View {
    let tint: Color
    private let gradientOpacity = 0.699999988079071

    var body: some View {
        ArchiveCategoryFolderVectorShape()
            .fill(folderGradient)
            .overlay {
                ArchiveCategoryFolderVectorShape()
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

private struct ArchiveCategoryFolderVectorShape: Shape {
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

#Preview("Archive category") {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(99), spacing: 19), count: 3), spacing: 39) {
            ForEach(CollectionKind.folderCases) { kind in
                let display = RecapPresentation.collectionDisplay(for: kind)
                ArchiveCategoryCard(
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
