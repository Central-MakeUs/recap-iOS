import SwiftUI

struct RecapToastContent: Hashable {
    let style: RecapToast.Style
    let message: String
}

struct RecapToast: View {
    enum Style: Hashable {
        case success
        case error

        fileprivate var icon: RecapIcon {
            switch self {
            case .success:
                .success
            case .error:
                .error
            }
        }

        fileprivate var iconColor: Color {
            switch self {
            case .success:
                Color.recapToastSuccess
            case .error:
                Color.recapDestructive
            }
        }
    }

    let style: Style
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            RecapIconView(
                icon: style.icon,
                size: 24,
                color: style.iconColor
            )

            Text(message)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 21)
        .frame(height: 45)
        // 뒤 콘텐츠를 뭉개 긴 본문 위에서도 문구가 읽히게 한다(#110, Figma 4310:15258).
        // glassEffect는 배경 밝기를 따라가 흰 글자 대비가 무너져서 쓰지 않는다.
        // 뒤 콘텐츠가 살짝 비치되 글자로 읽히지는 않게 한다(#110, Figma 4310:15258,
        // 디자이너 확인 값: 흐림 8, 고르게). Material은 반경을 못 정해 형태까지
        // 다 뭉개서 쓰지 않는다. 검정 0.50은 Figma 원값 — 흰 배경 위 흰 글자
        // 대비 4.06:1로 WCAG AA(4.5:1)에는 못 미친다(0.55면 넘지만 비침이
        // 죽는다). 비침을 우선한 결정이다.
        .background {
            ZStack {
                RecapBackdropBlur(radius: 8)
                Color.black.opacity(0.50)
            }
        }
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

#if DEBUG
/// 배경 흐림 너머로 뒤 콘텐츠가 살짝 비치는지 확인할 수 있게 글줄을 깔아둔다.
private struct RecapToastPreviewBackdrop: View {
    let toast: RecapToast

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                ForEach(0..<10, id: \.self) { _ in
                    Text("뒤 콘텐츠가 살짝 비치는지 확인하는 글줄입니다.")
                        .font(RecapFont.pretendard(size: 15, weight: .semibold))
                        .foregroundStyle(Color.recapGray900)
                }
            }
            toast
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.recapBackground)
    }
}

#Preview("토스트 - 성공") {
    RecapToastPreviewBackdrop(
        toast: RecapToast(style: .success, message: "즐겨찾기에 추가했어요.")
    )
}

#Preview("토스트 - 삭제 성공") {
    RecapToastPreviewBackdrop(
        toast: RecapToast(style: .success, message: "스크린샷을 삭제했어요.")
    )
}

#Preview("토스트 - 오류") {
    RecapToastPreviewBackdrop(
        toast: RecapToast(style: .error, message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요.")
    )
}
#endif
