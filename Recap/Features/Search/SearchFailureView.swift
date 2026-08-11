import SwiftUI

struct SearchFailureView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SearchFailureIllustration()

            Text("검색을 완료하지 못했어요")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 20)

            Text("네트워크 상태를 확인 한 뒤\n다시 시도해주세요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 13)

            RecapButton(
                title: "다시 시도",
                style: .secondary,
                size: .medium,
                action: onRetry
            )
            .frame(width: 155)
            .padding(.top, 23)

            Spacer(minLength: 0)
        }
        .padding(.top, 184)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SearchFailureIllustration: View {
    var body: some View {
        Circle()
            .fill(Color.recapGray100)
            .frame(width: 60, height: 60)
            .overlay {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 6, height: 19)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("검색 실패") {
    SearchFailureView(onRetry: PreviewActions.noop)
        .background(Color.recapBackground)
}
#endif
