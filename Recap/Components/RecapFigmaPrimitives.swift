import SwiftUI

struct RecapLogoText: View {
    var size: CGFloat = 23.17

    var body: some View {
        Text("Recap")
            .font(RecapFont.lexend(size: size, weight: .bold))
            .foregroundStyle(RecapTheme.ColorToken.primary)
    }
}

struct RecapOnboardingDots: View {
    let activeIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == activeIndex ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.border)
                    .frame(width: index == activeIndex ? 17 : 8, height: 8)
            }
        }
    }
}

struct RecapMascotMark: View {
    var size: CGFloat = 127

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.072, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1, green: 1, blue: 1),
                            Color(red: 92 / 255, green: 109 / 255, blue: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 0.76)
                .shadow(color: RecapTheme.ColorToken.primary.opacity(0.24), radius: size * 0.18, y: size * 0.07)

            RoundedRectangle(cornerRadius: size * 0.045, style: .continuous)
                .fill(Color(red: 89 / 255, green: 106 / 255, blue: 1))
                .frame(width: size * 0.70, height: size * 0.53)
                .offset(y: -size * 0.01)

            HStack(spacing: size * 0.045) {
                eye
                eye
            }
            .offset(y: size * 0.03)
        }
        .frame(width: size, height: size)
    }

    private var eye: some View {
        Circle()
            .fill(Color(red: 243 / 255, green: 243 / 255, blue: 243 / 255))
            .overlay {
                Circle()
                    .fill(Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255))
                    .frame(width: size * 0.17, height: size * 0.17)
                    .offset(x: size * 0.03)
            }
            .frame(width: size * 0.31, height: size * 0.31)
    }
}

struct RecapSearchEmptyIllustration: View {
    var size: CGFloat = 175

    var body: some View {
        ZStack {
            folder
                .offset(x: -20, y: 12)
            Circle()
                .stroke(RecapTheme.ColorToken.border, lineWidth: size * 0.04)
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(x: size * 0.23, y: size * 0.11)
            RoundedRectangle(cornerRadius: size * 0.015, style: .continuous)
                .fill(RecapTheme.ColorToken.border)
                .frame(width: size * 0.16, height: size * 0.04)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.39, y: size * 0.31)
        }
        .frame(width: size, height: size * 0.73)
    }

    private var folder: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(RecapTheme.ColorToken.border)
                .frame(width: size * 0.49, height: size * 0.56)
                .offset(y: size * 0.11)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(RecapTheme.ColorToken.border)
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
                    .fill(RecapTheme.ColorToken.border)
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
                .foregroundStyle(RecapTheme.ColorToken.border)
                .offset(x: -45, y: -28)
            Image(systemName: "star.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(RecapTheme.ColorToken.border)
                .offset(x: 0, y: -48)
            Image(systemName: "star.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(RecapTheme.ColorToken.border)
                .offset(x: 45, y: -25)
        }
    }
}

struct RecapIncompleteCallout: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text("미완성")
                .font(RecapFont.pretendard(size: 11, weight: .bold))
                .tracking(-0.12)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RecapTheme.ColorToken.unimplemented)
                .clipShape(Capsule())
            Text(title)
                .font(RecapFont.pretendard(size: 15, weight: .semibold))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            Text(message)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
        }
        .padding(18)
        .background(RecapTheme.ColorToken.warningSoft)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RecapTheme.ColorToken.unimplemented, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct RecapSectionHeader: View {
    let title: String
    var trailingIcon: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            Spacer()
            if let trailingIcon {
                Button(action: { action?() }) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 25)
    }
}

#Preview("Figma primitives") {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        VStack(spacing: 24) {
            RecapLogoText()
            RecapOnboardingDots(activeIndex: 2, count: 4)
            RecapMascotMark(size: 96)
            RecapSearchEmptyIllustration(size: 140)
            RecapIncompleteCallout(title: "검색 실패", message: "연결 전 상태를 명시합니다.")
        }
        .padding()
    }
}
