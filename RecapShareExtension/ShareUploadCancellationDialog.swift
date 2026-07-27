import SwiftUI

struct ShareUploadCancellationDialog: View {
    let onContinue: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("정리를 취소할까요?")
                .font(.custom("Pretendard-SemiBold", size: 16))
                .tracking(-0.32)
                .foregroundStyle(Color("RecapGray900"))

            Text("지금 나가면 공유한 스크린샷이\n정리되지 않아요")
                .font(.custom("Pretendard-Regular", size: 14))
                .tracking(-0.28)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("RecapGray500"))
                .lineSpacing(4)
                .padding(.top, 10)

            HStack(spacing: 14) {
                dialogButton(
                    title: "계속정리하기",
                    foregroundColor: Color("RecapGray700"),
                    backgroundColor: Color("RecapGray50"),
                    action: onContinue
                )

                dialogButton(
                    title: "나가기",
                    foregroundColor: .white,
                    backgroundColor: Color("RecapBlue300"),
                    action: onExit
                )
            }
            .padding(.top, 22)
        }
        .padding(.horizontal, 21)
        .padding(.top, 25)
        .frame(width: 292, height: 181, alignment: .top)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func dialogButton(
        title: String,
        foregroundColor: Color,
        backgroundColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Pretendard-SemiBold", size: 14))
                .tracking(-0.28)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("공유 업로드 취소 확인") {
    ZStack {
        Color.black.opacity(0.30)
            .ignoresSafeArea()

        ShareUploadCancellationDialog(
            onContinue: {},
            onExit: {}
        )
    }
}
