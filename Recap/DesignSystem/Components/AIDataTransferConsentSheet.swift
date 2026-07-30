import SwiftUI

struct AIDataTransferConsentSheet: View {
    let primaryButtonTitle: String
    let onConsent: () -> Void
    let onCancel: () -> Void

    @State private var showsPrivacyPolicy = false

    init(
        primaryButtonTitle: String = "동의하고 정리하기",
        onConsent: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.primaryButtonTitle = primaryButtonTitle
        self.onConsent = onConsent
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color.recapGray200)
                .frame(width: 43, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 13)

            transferIcon
                .padding(.horizontal, 22)
                .padding(.top, 18)

            Text("AI 분석을 위해 이미지를 전송해요")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
                .frame(height: 25)
                .padding(.horizontal, 22)
                .padding(.top, 12)

            Text(
                "리캡은 제목 · 요약 · 유형을 생성하기 위해 회원님이 선택한\n"
                    + "스크린샷 이미지와 이미지에서 추출한 텍스트를 당사\n"
                    + "서버를 거쳐 Google LLC의 Gemini API로 전송합니다."
            )
            .font(RecapFont.pretendard(size: 14, weight: .regular))
            .tracking(-0.28)
            .foregroundStyle(Color.recapGray700)
            .frame(height: 60, alignment: .topLeading)
            .padding(.horizontal, 22)
            .padding(.top, 13)

            Button("개인정보 처리방침") {
                showsPrivacyPolicy = true
            }
            .buttonStyle(.plain)
            .font(RecapFont.pretendard(size: 14, weight: .regular))
            .tracking(-0.28)
            .foregroundStyle(Color.recapGray500)
            .frame(height: 20)
            .padding(.horizontal, 22)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 10) {
                Text(
                    "업로드한 원본 이미지는 1개월간 보관 후 삭제되며, "
                        + "미리보기용 이미지와 정보카드는 회원 탈퇴 시까지 보관돼요."
                )
                .frame(height: 40, alignment: .topLeading)

                Text("전송된 정보는 Google의 AI모델 학습에 사용되지 않아요.")
                    .frame(height: 20, alignment: .topLeading)

                Text("AI가 생성한 결과는 일부 부정확할 수 있으며, 직접 수정할 수 있어요.")
                    .frame(height: 40, alignment: .topLeading)
            }
            .font(RecapFont.pretendard(size: 14, weight: .regular))
            .tracking(-0.28)
            .foregroundStyle(Color.recapGray500)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 22)
            .padding(.top, 38)

            RecapButton(
                title: primaryButtonTitle,
                style: .primary,
                action: onConsent
            )
            .padding(.horizontal, 16)
            .padding(.top, 30)

            Button("취소", action: onCancel)
                .buttonStyle(.plain)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray500)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
        .padding(.bottom, 21)
        .background(Color.white)
        .fullScreenCover(isPresented: $showsPrivacyPolicy) {
            NavigationStack {
                PrivacyInformationView()
            }
        }
    }

    private var transferIcon: some View {
        Image("AIDataTransferUploadIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 34, height: 33)
    }
}

extension View {
    func aiDataTransferConsentSheet(
        isPresented: Binding<Bool>,
        onConsent: @escaping () -> Void
    ) -> some View {
        modifier(
            AIDataTransferConsentPresentation(
                isPresented: isPresented,
                onConsent: onConsent
            )
        )
    }
}

private struct AIDataTransferConsentPresentation: ViewModifier {
    @Binding var isPresented: Bool
    let onConsent: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                AIDataTransferConsentSheet(
                    onConsent: onConsent,
                    onCancel: dismiss
                )
                .presentationDetents([.height(532)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(32)
                .presentationBackground(Color.white)
            }
    }

    private func dismiss() {
        isPresented = false
    }
}

#Preview("AI 전송 동의") {
    AIDataTransferConsentSheet(
        onConsent: PreviewActions.noop,
        onCancel: PreviewActions.noop
    )
}
