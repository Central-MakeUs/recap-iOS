import SwiftUI

/// 앱과 공유 확장이 함께 쓴다.
///
/// 확장 번들에는 Pretendard Regular·Medium·SemiBold만 들어 있다. 확장에서 그리는
/// 화면에 `.bold`나 `lexend`를 쓰면 시스템 폰트로 조용히 대체되므로,
/// 필요해지면 확장 번들과 `UIAppFonts`에 해당 폰트를 먼저 추가해야 한다.
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
