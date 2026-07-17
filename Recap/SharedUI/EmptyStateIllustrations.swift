import SwiftUI
struct RecapSearchEmptyIllustration: View {
    var size: CGFloat = 175

    var body: some View {
        ZStack {
            folder
                .offset(x: -12, y: 8)

            Circle()
                .stroke(Color.recapGray200, lineWidth: size * 0.055)
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(x: size * 0.24, y: size * 0.12)

            RoundedRectangle(cornerRadius: size * 0.015, style: .continuous)
                .fill(Color.recapGray200)
                .frame(width: size * 0.20, height: size * 0.055)
                .rotationEffect(.degrees(50))
                .offset(x: size * 0.42, y: size * 0.34)
        }
        .frame(width: size, height: size * 0.73)
    }

    private var folder: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                .fill(Color.recapGray100)
                .frame(width: size * 0.61, height: size * 0.46)
                .offset(y: size * 0.17)

            RecapEmptyFolderTabShape()
                .fill(Color.recapGray100)
                .frame(width: size * 0.57, height: size * 0.18)

            HStack(spacing: -2) {
                emptyEye
                emptyEye
            }
            .offset(x: size * 0.13, y: size * 0.39)
        }
        .frame(width: size * 0.64, height: size * 0.65)
    }

    private var emptyEye: some View {
        Circle()
            .fill(.white)
            .frame(width: size * 0.14, height: size * 0.14)
            .overlay {
                Circle()
                    .fill(Color.recapGray200)
                    .frame(width: size * 0.07, height: size * 0.07)
            }
    }
}

struct RecapArchiveEmptyIllustration: View {
    enum Style {
        case favorites
        case other
    }

    let style: Style

    var body: some View {
        ZStack {
            if style == .other {
                RecapSearchEmptyIllustration(size: 175)
            } else {
                favoriteDocument
                starField
            }
        }
        .frame(width: 175, height: 128)
    }

    private var favoriteDocument: some View {
        RecapEmptyDocumentShape()
            .fill(Color.recapGray100)
            .frame(width: 85, height: 97)
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: -2) {
                    emptyEye
                    emptyEye
                }
                .offset(x: -8, y: -30)
            }
            .offset(y: 18)
    }

    private var emptyEye: some View {
        Circle()
            .fill(.white)
            .frame(width: 24, height: 24)
            .overlay {
                Capsule()
                    .stroke(Color.recapGray100, lineWidth: 2)
                    .frame(width: 12, height: 6)
            }
    }

    private var starField: some View {
        ZStack {
            RecapIconView(icon: .star, size: 20, color: Color.recapGray100)
                .offset(x: -55, y: -29)
            RecapIconView(icon: .star, size: 20, color: Color.recapGray100)
                .offset(x: 0, y: -50)
            RecapIconView(icon: .star, size: 20, color: Color.recapGray100)
                .offset(x: 55, y: -29)
        }
    }
}

private struct RecapEmptyDocumentShape: Shape {
    func path(in rect: CGRect) -> Path {
        let foldWidth = rect.width * 0.29
        let foldHeight = rect.height * 0.25
        let radius = rect.width * 0.06

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - foldWidth, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + foldHeight))
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

private struct RecapEmptyFolderTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        let tabEnd = rect.width * 0.36
        let slopeEnd = rect.width * 0.48
        let bodyTop = rect.height * 0.50
        let radius = rect.height * 0.15

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + tabEnd, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + slopeEnd, y: rect.minY + bodyTop))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY + bodyTop))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + bodyTop + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY + bodyTop)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
