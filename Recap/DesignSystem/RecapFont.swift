import SwiftUI

enum RecapFont {
    static func pretendard(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(pretendardPostScriptName(for: weight), size: size)
    }

    /// 워드마크용. `Lexend.ttf`는 wght 100~900 가변 폰트이며
    /// `Lexend-Bold`는 그 안의 이름 붙은 인스턴스다.
    static func lexend(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Lexend-Bold", size: size).weight(weight)
    }

    private static func pretendardPostScriptName(for weight: Font.Weight) -> String {
        if weight == .bold {
            return "Pretendard-Bold"
        }
        if weight == .semibold {
            return "Pretendard-SemiBold"
        }
        if weight == .medium {
            return "Pretendard-Medium"
        }
        return "Pretendard-Regular"
    }
}
