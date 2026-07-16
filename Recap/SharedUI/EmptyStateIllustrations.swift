import SwiftUI
struct RecapSearchEmptyIllustration: View {
    var size: CGFloat = 175

    var body: some View {
        ZStack {
            folder
                .offset(x: -20, y: 12)
            Circle()
                .stroke(Color.recapGray100, lineWidth: size * 0.04)
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(x: size * 0.23, y: size * 0.11)
            RoundedRectangle(cornerRadius: size * 0.015, style: .continuous)
                .fill(Color.recapGray100)
                .frame(width: size * 0.16, height: size * 0.04)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.39, y: size * 0.31)
        }
        .frame(width: size, height: size * 0.73)
    }

    private var folder: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.recapGray100)
                .frame(width: size * 0.49, height: size * 0.56)
                .offset(y: size * 0.11)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.recapGray100)
                .frame(width: size * 0.34, height: size * 0.16)
            HStack(spacing: 0) {
                Circle().fill(.white).frame(width: size * 0.12, height: size * 0.12)
                Circle().fill(.white).frame(width: size * 0.12, height: size * 0.12)
            }
            .offset(x: size * 0.18, y: size * 0.37)
        }
        .frame(width: size * 0.58, height: size * 0.70)
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
            if style == .favorites {
                starField
            }
            if style == .other {
                RecapSearchEmptyIllustration(size: 175)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.recapGray100)
                    .frame(width: 85, height: 97)
                    .overlay {
                        HStack(spacing: 0) {
                            Circle().fill(.white).frame(width: 20, height: 20)
                            Circle().fill(.white).frame(width: 20, height: 20)
                        }
                        .offset(y: 18)
                    }
            }
        }
        .frame(width: 175, height: 128)
    }

    private var starField: some View {
        ZStack {
            Image(systemName: "star.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.recapGray100)
                .offset(x: -45, y: -28)
            Image(systemName: "star.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.recapGray100)
                .offset(x: 0, y: -48)
            Image(systemName: "star.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.recapGray100)
                .offset(x: 45, y: -25)
        }
    }
}
