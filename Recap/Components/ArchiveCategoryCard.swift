import SwiftUI

enum ArchiveCategoryThumbnailState: Equatable {
    case filled
    case empty
}

struct ArchiveCategoryCard: View {
    let title: String
    let count: Int
    var thumbnailState: ArchiveCategoryThumbnailState = .filled
    var tint: Color = RecapTheme.ColorToken.primary

    private var componentHeight: CGFloat {
        switch thumbnailState {
        case .filled: 168
        case .empty: 118
        }
    }

    private var thumbnailHeight: CGFloat {
        switch thumbnailState {
        case .filled: 119.82
        case .empty: 70
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ArchiveFolderThumbnail(state: thumbnailState, tint: tint)
                .frame(width: 91, height: thumbnailHeight)
                .position(x: 45.5, y: thumbnailHeight / 2)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .lineLimit(1)
                .frame(width: 91, height: 18)
                .position(x: 45.5, y: thumbnailHeight + 19)

            Text("\(count) recaps")
                .font(.system(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .lineLimit(1)
                .frame(width: 91, height: 17)
                .position(x: 45.5, y: thumbnailHeight + 39.5)
        }
        .frame(width: 91, height: componentHeight, alignment: .topLeading)
    }
}

private struct ArchiveFolderThumbnail: View {
    let state: ArchiveCategoryThumbnailState
    let tint: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            if state == .filled {
                FolderBackStack(tint: tint)
                FolderFrontShape()
                    .frame(width: 91, height: 70)
                    .position(x: 45.5, y: 84.82)
            } else {
                FolderFrontShape()
                    .frame(width: 91, height: 70)
                    .position(x: 45.5, y: 35)
            }
        }
    }
}

private struct FolderBackStack: View {
    let tint: Color

    private let sheetWidth: CGFloat = 74.99671936035156
    private let sheetHeight: CGFloat = 99.99562072753906
    private let sheetRadius: CGFloat = 3.571272134780884
    private let backSheetRotation: Angle = .degrees(6.24)

    var body: some View {
        ZStack(alignment: .topLeading) {
            FigmaImageFillPlaceholder(tint: tint.opacity(0.10))
                .frame(width: sheetWidth, height: sheetHeight)
                .clipShape(RoundedRectangle(cornerRadius: sheetRadius, style: .continuous))
                .rotationEffect(backSheetRotation)
                .position(x: 45.01662614986688, y: 53.777379970545895)

            FigmaImageFillPlaceholder(tint: tint.opacity(0.14))
                .frame(width: sheetWidth, height: sheetHeight)
                .clipShape(RoundedRectangle(cornerRadius: sheetRadius, style: .continuous))
                .position(x: 45.35504913330078, y: 54.28321075439453)
        }
        .frame(width: 91, height: 119.82, alignment: .topLeading)
    }
}

private struct FigmaImageFillPlaceholder: View {
    let tint: Color

    var body: some View {
        CheckerboardPattern()
            .fill(RecapTheme.ColorToken.gray100)
            .background(RecapTheme.ColorToken.gray50)
            .overlay(tint)
    }
}

private struct FolderFrontShape: View {
    private let gradientOpacity = 0.699999988079071

    var body: some View {
        FigmaFolderShape()
            .fill(folderGradient)
            .overlay {
                FigmaFolderShape()
                    .stroke(Color.white, lineWidth: 1)
            }
    }

    private var folderGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.white.opacity(gradientOpacity), location: 0),
                .init(color: RecapComponentColor.imageGradientEnd.opacity(gradientOpacity), location: 1)
            ],
            startPoint: UnitPoint(x: 0.499999880844772, y: -0.3310865784233596),
            endPoint: UnitPoint(x: 0.4999998808447753, y: 2.0348124794950126)
        )
    }
}

private struct FigmaFolderShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 91
        let scaleY = rect.height / 70
        let bodyTop = 8.349 * scaleY
        let radius = 3.571 * min(scaleX, scaleY)
        let tabEndX = 50 * scaleX
        let tabSlopeEndX = 59 * scaleX
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + tabEndX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + tabSlopeEndX, y: rect.minY + bodyTop),
            control1: CGPoint(x: rect.minX + tabEndX + 3 * scaleX, y: rect.minY),
            control2: CGPoint(x: rect.minX + tabSlopeEndX - 3 * scaleX, y: rect.minY + bodyTop)
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

private struct CheckerboardPattern: Shape {
    func path(in rect: CGRect) -> Path {
        let square: CGFloat = 7.14
        var path = Path()
        var y = rect.minY
        var row = 0

        while y < rect.maxY {
            var x = rect.minX + (row.isMultiple(of: 2) ? 0 : square)
            while x < rect.maxX {
                path.addRect(CGRect(x: x, y: y, width: square, height: square))
                x += square * 2
            }
            y += square
            row += 1
        }

        return path
    }
}

#Preview("Archive category") {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        HStack(spacing: RecapTheme.Spacing.xLarge) {
            ArchiveCategoryCard(title: "카테고리 01", count: 8)
            ArchiveCategoryCard(title: "카테고리 01", count: 0, thumbnailState: .empty)
        }
        .padding()
    }
}
