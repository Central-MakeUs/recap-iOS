import SwiftUI

enum RecapTheme {
    enum ColorToken {
        static let blue900 = Color("RecapBlue900")
        static let blue500 = Color("RecapBlue500")
        static let blue300 = Color("RecapBlue300")
        static let blue50 = Color("RecapBlue50")

        static let gray900 = Color("RecapGray900")
        static let gray700 = Color("RecapGray700")
        static let gray500 = Color("RecapGray500")
        static let gray300 = Color("RecapGray300")
        static let gray200 = Color("RecapGray200")
        static let gray100 = Color("RecapGray100")
        static let gray50 = Color("RecapGray50")

        static let background = gray50
        static let surface = Color.white
        static let primary = blue500
        static let primaryLight = blue300
        static let primarySoft = blue50
        static let textPrimary = gray900
        static let textSecondary = gray500
        static let textTertiary = gray300
        static let border = gray100
        static let divider = gray100
        static let warning = Color(red: 0.965, green: 0.680, blue: 0.175)
        static let warningSoft = Color(red: 1.000, green: 0.965, blue: 0.875)
        static let success = Color(red: 0.180, green: 0.650, blue: 0.420)
        static let thumbnail = gray200
    }

    enum Typography {
        static let heading1 = Font.system(size: 22, weight: .semibold)
        static let heading2 = Font.system(size: 18, weight: .semibold)
        static let heading3 = Font.system(size: 16, weight: .semibold)
        static let body1 = Font.system(size: 15, weight: .medium)
        static let body2 = Font.system(size: 14, weight: .regular)
        static let caption1 = Font.system(size: 13, weight: .medium)
        static let caption2 = Font.system(size: 12, weight: .medium)
        static let caption3 = Font.system(size: 10, weight: .medium)
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
            .font(RecapTheme.Typography.heading2)
        Text("카드 스타일 미리보기")
            .font(RecapTheme.Typography.body2)
            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .recapCard()
    .padding()
    .background(RecapTheme.ColorToken.background)
}
