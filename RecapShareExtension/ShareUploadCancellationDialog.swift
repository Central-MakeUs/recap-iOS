import SwiftUI

struct ShareUploadCancellationDialog: View {
    let onContinue: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(OrganizeCancellationCopy.title)
                .font(.custom("Pretendard-SemiBold", size: 16))
                .tracking(-0.32)
                .foregroundStyle(Color("RecapGray900"))

            Text(OrganizeCancellationCopy.message)
                .font(.custom("Pretendard-Regular", size: 14))
                .tracking(-0.28)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("RecapGray500"))
                .lineSpacing(4)
                .padding(.top, 10)

            HStack(spacing: 14) {
                RecapPopupButton(
                    title: OrganizeCancellationCopy.continueTitle,
                    style: .secondary,
                    action: onContinue
                )

                RecapPopupButton(
                    title: OrganizeCancellationCopy.exitTitle,
                    style: .primary,
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

}

#if DEBUG
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
#endif
