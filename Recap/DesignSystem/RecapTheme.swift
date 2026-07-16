import SwiftUI

enum RecapTheme {
    enum Typography {
        static let heading1 = RecapFont.pretendard(size: 22, weight: .semibold)
        static let heading2 = RecapFont.pretendard(size: 18, weight: .semibold)
        static let heading3 = RecapFont.pretendard(size: 16, weight: .semibold)
        static let body1 = RecapFont.pretendard(size: 15, weight: .medium)
        static let body2 = RecapFont.pretendard(size: 14, weight: .regular)
        static let caption1 = RecapFont.pretendard(size: 13, weight: .medium)
        static let caption2 = RecapFont.pretendard(size: 12, weight: .medium)
        static let caption3 = RecapFont.pretendard(size: 10, weight: .medium)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 22
    }
}

struct RecapCardStyle: ViewModifier {
    var radius: CGFloat = RecapTheme.Radius.large
    var borderColor: Color = .recapGray100
    var fill: Color = .white

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func recapCard(
        radius: CGFloat = RecapTheme.Radius.large,
        borderColor: Color = .recapGray100,
        fill: Color = .white
    ) -> some View {
        modifier(RecapCardStyle(radius: radius, borderColor: borderColor, fill: fill))
    }
}

#Preview("Theme card") {
    ZStack {
        Color.recapBackground.ignoresSafeArea()
        VStack(spacing: RecapTheme.Spacing.large) {
            Text("Recap")
                .font(RecapTheme.Typography.heading2)
            Text("카드 스타일 미리보기")
                .font(RecapTheme.Typography.body2)
                .foregroundStyle(Color.recapGray500)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .recapCard()
        .padding()
    }
}
