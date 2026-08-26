import SwiftUI

struct RecapButton: View {
    enum Size: Equatable {
        case large
        case medium
        case small

        var height: CGFloat {
            switch self {
            case .large: 50
            case .medium: 45
            case .small: 40
            }
        }

        var font: Font {
            switch self {
            case .small:
                .custom("Pretendard-Medium", size: 12)
            case .large, .medium:
                .custom("Pretendard-SemiBold", size: 14)
            }
        }
    }

    enum Style: Equatable {
        case primary
        case dark
        case kakao
        case secondary

        var foreground: Color {
            switch self {
            case .primary, .dark: .white
            case .kakao: Color("RecapGray900")
            case .secondary: Color("RecapBlue300")
            }
        }

        var background: Color {
            switch self {
            case .primary: Color("RecapBlue300")
            case .dark: Color("RecapGray900")
            case .kakao: Color("RecapKakaoYellow")
            case .secondary: Color("RecapBlue50")
            }
        }
    }

    let title: String
    var systemImage: String?
    var assetImageName: String?
    var style: Style = .primary
    var size: Size = .large
    var isLoading = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isLoading {
                    ProgressView()
                        .tint(isEnabled ? style.foreground : Color("RecapGray300"))
                } else {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                    } else if let assetImageName {
                        Image(assetImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }

                    Text(title)
                        .font(size.font)
                        .tracking(size == .small ? -0.24 : -0.28)
                }
            }
        }
        .buttonStyle(RecapButtonStyle(style: style, size: size))
    }
}

struct RecapButtonStyle: ButtonStyle {
    let style: RecapButton.Style
    let size: RecapButton.Size

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? style.foreground : Color("RecapGray300"))
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background {
                background(isPressed: configuration.isPressed)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func background(isPressed: Bool) -> some View {
        if !isEnabled {
            Color("RecapGray100")
        } else if isPressed {
            if style == .primary {
                Color("RecapBlue500")
            } else {
                style.background
                    .overlay(Color.black.opacity(0.12))
            }
        } else {
            style.background
        }
    }
}

#if DEBUG
#Preview("btn states") {
    VStack(spacing: 12) {
        RecapButton(title: "버튼", action: {})
        RecapButton(title: "비활성 버튼", action: {})
            .disabled(true)
        RecapButton(title: "스크린샷 불러오기", style: .secondary, size: .medium, action: {})
            .frame(width: 155)
    }
    .padding()
}
#endif
