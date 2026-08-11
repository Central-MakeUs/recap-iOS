import SwiftUI

struct ShareOrganizeCompleteView: View {
    let organizedCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 141)

            Image("CardCreationSuccessIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text("\(organizedCount)개의 스크린샷을\n정리했어요")
                .font(.custom("Pretendard-SemiBold", size: 18))
                .tracking(-0.36)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("RecapGray900"))
                .padding(.top, 10)

            Image("CardCreationCompleteIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 195.09, height: 177.43)
                .padding(.top, 25)

            Text("보관함에서 확인해보세요!")
                .font(.custom("Pretendard-Medium", size: 15))
                .tracking(-0.3)
                .foregroundStyle(Color("RecapGray500"))
                .padding(.top, 21)

            Spacer(minLength: 20)

            RecapButton(
                title: "완료",
                action: onDone
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(Color("RecapBackground"))
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

struct ShareOrganizeFailureView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 141)

            Image("CardCreationFailureIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text("스크린샷을 정리하지 못했어요")
                .font(.custom("Pretendard-SemiBold", size: 18))
                .tracking(-0.36)
                .foregroundStyle(Color("RecapGray900"))
                .padding(.top, 10)

            Image("CardCreationFailureIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 123, height: 95)
                .padding(.top, 56)

            Text("다음에 다시 시도해주세요.")
                .font(.custom("Pretendard-Medium", size: 15))
                .tracking(-0.3)
                .foregroundStyle(Color("RecapGray500"))
                .padding(.top, 22)

            Spacer(minLength: 20)

            RecapButton(
                title: "닫기",
                action: onClose
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(Color("RecapBackground"))
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

#Preview("04-03_공유 정리 완료") {
    ShareOrganizeCompleteView(organizedCount: 5, onDone: {})
}

#Preview("04-04_공유 정리 실패") {
    ShareOrganizeFailureView(onClose: {})
}
