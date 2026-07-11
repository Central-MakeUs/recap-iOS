import CoreText
import SwiftUI

enum RecapFont {
    static func registerFonts() {
        RecapFontRegistrar.registerFonts()
    }

    static func pretendard(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(pretendardPostScriptName(for: weight), size: size)
    }

    static func lexend(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        // Figma uses Lexend for the wordmark. If the font is not bundled yet,
        // SwiftUI falls back while keeping the design token explicit.
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

private enum RecapFontRegistrar {
    private static var didRegister = false

    static func registerFonts() {
        guard !didRegister else { return }
        didRegister = true

        guard let resourceURL = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(
                at: resourceURL,
                includingPropertiesForKeys: nil
              ) else {
            return
        }

        for case let fontURL as URL in enumerator {
            guard ["otf", "ttf"].contains(fontURL.pathExtension.lowercased()),
                  fontURL.lastPathComponent.hasPrefix("Pretendard-")
                    || fontURL.lastPathComponent == "Lexend.ttf" else {
                continue
            }
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
