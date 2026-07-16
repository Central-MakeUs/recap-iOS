import SwiftUI

struct RecapToastContent: Hashable {
    let style: RecapToast.Style
    let message: String
}

struct RecapToast: View {
    enum Style: Hashable {
        case success
        case error

        fileprivate var iconName: String {
            switch self {
            case .success:
                "checkmark.circle.fill"
            case .error:
                "exclamationmark.circle.fill"
            }
        }

        fileprivate var iconColor: Color {
            switch self {
            case .success:
                Color(red: 31 / 255, green: 205 / 255, blue: 112 / 255)
            case .error:
                Color(red: 1, green: 100 / 255, blue: 100 / 255)
            }
        }
    }

    let style: Style
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(style.iconColor)
                .frame(width: 24, height: 24)

            Text(message)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 21)
        .frame(height: 45)
        .background(Color.black.opacity(0.50))
        .clipShape(Capsule())
    }
}

struct RecapToastModifier: ViewModifier {
    private enum Layout {
        static let horizontalPadding: CGFloat = 13
        static let bottomPadding: CGFloat = 50
    }

    let toast: RecapToastContent?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast {
                RecapToast(style: toast.style, message: toast.message)
                    .padding(.horizontal, Layout.horizontalPadding)
                    .padding(.bottom, Layout.bottomPadding)
            }
        }
    }
}

extension View {
    func recapToast(_ toast: RecapToastContent?) -> some View {
        modifier(RecapToastModifier(toast: toast))
    }
}

#Preview("토스트 - 성공") {
    RecapToast(style: .success, message: "즐겨찾기에 추가했어요.")
}

#Preview("토스트 - 삭제 성공") {
    RecapToast(style: .success, message: "스크린샷을 삭제했어요.")
}

#Preview("토스트 - 오류") {
    RecapToast(style: .error, message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요.")
}
