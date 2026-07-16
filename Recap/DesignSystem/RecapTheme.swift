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

        enum Category {
            static let blue300 = Color("RecapCategoryBlue300")
            static let blue500 = Color("RecapCategoryBlue500")
            static let blue700 = Color("RecapCategoryBlue700")

            static let red300 = Color("RecapCategoryRed300")
            static let red500 = Color("RecapCategoryRed500")
            static let red700 = Color("RecapCategoryRed700")

            static let green300 = Color("RecapCategoryGreen300")
            static let green500 = Color("RecapCategoryGreen500")
            static let green700 = Color("RecapCategoryGreen700")

            static let yellow300 = Color("RecapCategoryYellow300")
            static let yellow500 = Color("RecapCategoryYellow500")
            static let yellow700 = Color("RecapCategoryYellow700")

            static let gray300 = Color("RecapCategoryGray300")
            static let gray500 = Color("RecapCategoryGray500")
            static let gray700 = Color("RecapCategoryGray700")

            static let mint300 = Color("RecapCategoryMint300")
            static let mint500 = Color("RecapCategoryMint500")
            static let mint700 = Color("RecapCategoryMint700")

            static let purple300 = Color("RecapCategoryPurple300")
            static let purple500 = Color("RecapCategoryPurple500")
            static let purple700 = Color("RecapCategoryPurple700")

            static let orange300 = Color("RecapCategoryOrange300")
            static let orange500 = Color("RecapCategoryOrange500")
            static let orange700 = Color("RecapCategoryOrange700")
        }

        static let background = Color(red: 253 / 255, green: 253 / 255, blue: 253 / 255)
        static let surface = Color.white
        static let controlFill = Color(red: 244 / 255, green: 245 / 255, blue: 248 / 255)
        static let primary = Color(red: 92 / 255, green: 116 / 255, blue: 255 / 255)
        static let primaryLight = Color(red: 92 / 255, green: 116 / 255, blue: 255 / 255).opacity(0.14)
        static let primarySoft = Color(red: 243 / 255, green: 245 / 255, blue: 255 / 255)
        static let textPrimary = Color(red: 11 / 255, green: 17 / 255, blue: 29 / 255)
        static let textBody = Color(red: 34 / 255, green: 43 / 255, blue: 60 / 255)
        static let textSecondary = Color(red: 77 / 255, green: 88 / 255, blue: 108 / 255)
        static let textTertiary = Color(red: 153 / 255, green: 160 / 255, blue: 176 / 255)
        static let border = Color(red: 226 / 255, green: 230 / 255, blue: 237 / 255)
        static let divider = border
        static let warning = Color(red: 0.965, green: 0.680, blue: 0.175)
        static let warningSoft = Color(red: 1.000, green: 0.965, blue: 0.875)
        static let success = Color(red: 0.180, green: 0.650, blue: 0.420)
        static let unimplemented = Color(red: 1.0, green: 0.18, blue: 0.62)
        static let thumbnail = Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255)
    }

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
    var borderColor: Color = RecapTheme.ColorToken.border
    var fill: Color = RecapTheme.ColorToken.surface

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
        borderColor: Color = RecapTheme.ColorToken.border,
        fill: Color = RecapTheme.ColorToken.surface
    ) -> some View {
        modifier(RecapCardStyle(radius: radius, borderColor: borderColor, fill: fill))
    }
}

#Preview("Theme card") {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        VStack(spacing: RecapTheme.Spacing.large) {
            Text("Recap")
                .font(RecapTheme.Typography.heading2)
            Text("카드 스타일 미리보기")
                .font(RecapTheme.Typography.body2)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .recapCard()
        .padding()
    }
}
