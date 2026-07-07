import SwiftUI

enum RecapTheme {
    enum ColorToken {
        static let background = Color(red: 0.965, green: 0.976, blue: 0.992)
        static let surface = Color.white
        static let primary = Color(red: 0.255, green: 0.420, blue: 0.929)
        static let primaryLight = Color(red: 0.910, green: 0.936, blue: 1.000)
        static let primarySoft = Color(red: 0.965, green: 0.976, blue: 1.000)
        static let textPrimary = Color(red: 0.100, green: 0.120, blue: 0.170)
        static let textSecondary = Color(red: 0.420, green: 0.470, blue: 0.560)
        static let textTertiary = Color(red: 0.600, green: 0.650, blue: 0.730)
        static let border = Color(red: 0.875, green: 0.900, blue: 0.940)
        static let divider = Color(red: 0.920, green: 0.935, blue: 0.960)
        static let warning = Color(red: 0.965, green: 0.680, blue: 0.175)
        static let warningSoft = Color(red: 1.000, green: 0.965, blue: 0.875)
        static let success = Color(red: 0.180, green: 0.650, blue: 0.420)
        static let thumbnail = Color(red: 0.835, green: 0.870, blue: 0.920)
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
    var borderColor: Color = RecapTheme.ColorToken.border
    var fill: Color = RecapTheme.ColorToken.surface

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

extension View {
    func recapCard(
        radius: CGFloat = RecapTheme.Radius.large,
        borderColor: Color = RecapTheme.ColorToken.border,
        fill: Color = RecapTheme.ColorToken.surface
    ) -> some View {
        modifier(RecapCardStyle(radius: radius, borderColor: borderColor, fill: fill))
    }
}

#Preview("Theme card") {
    VStack(spacing: RecapTheme.Spacing.large) {
        Text("RE-CAP")
            .font(.headline)
        Text("카드 스타일 미리보기")
            .font(.subheadline)
            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .recapCard()
    .padding()
    .background(RecapTheme.ColorToken.background)
}
