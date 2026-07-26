import SwiftUI

struct CardCreationResultView: View {
    let state: CardCreationResultState
    var selectedCount = 5
    var failedCount = 1
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 141)

            resultContent

            Spacer(minLength: 20)

            RecapButton(
                title: state.buttonTitle,
                style: .primary,
                action: onDone
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(Color.recapBackground)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder
    private var resultContent: some View {
        switch state {
        case .complete:
            CardCreationCompleteResultContent(
                organizedCount: selectedCount
            )
        case .partialFailure:
            CardCreationPartialFailureResultContent(
                organizedCount: selectedCount
            )
        case .failure:
            CardCreationFailureResultContent()
        }
    }
}

private struct CardCreationCompleteResultContent: View {
    let organizedCount: Int

    var body: some View {
        VStack(spacing: 0) {
            Image("CardCreationSuccessIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text("\(organizedCount)개의 스크린샷을\n정리했어요")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .lineSpacing(0)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray900)
                .padding(.top, 10)

            Image("CardCreationCompleteIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 195.09, height: 177.43)
                .padding(.top, 25)

            Text("보관함에서 확인해보세요!")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, 21)
        }
    }
}

private struct CardCreationPartialFailureResultContent: View {
    let organizedCount: Int

    var body: some View {
        VStack(spacing: 0) {
            Image("CardCreationPartialFailureIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text("일부 스크린샷을 정리하지 못했어요")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
                .padding(.top, 10)

            Text("\(organizedCount)개 정리됨")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapBlue300)
                .frame(width: 124, height: 38)
                .background(Color.recapPrimarySoft)
                .clipShape(Capsule())
                .padding(.top, 18)

            Image("CardCreationPartialFailureIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 123, height: 95)
                .padding(.top, 56)

            Text("정리된 스크린샷은\n보관함에 저장했어요!")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .lineSpacing(0)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, 22)
        }
    }
}

private struct CardCreationFailureResultContent: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("CardCreationFailureIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text("스크린샷을 정리하지 못했어요")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
                .padding(.top, 10)

            Image("CardCreationFailureIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 123, height: 95)
                .padding(.top, 56)

            Text("다음에 다시 시도해주세요.")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, 22)
        }
    }
}

#Preview("CardCreation result - complete") {
    CardCreationResultView(
        state: .complete,
        selectedCount: 5,
        onDone: {}
    )
}

#Preview("CardCreation result - partial failure") {
    CardCreationResultView(
        state: .partialFailure,
        selectedCount: 3,
        failedCount: 2,
        onDone: {}
    )
}

#Preview("CardCreation result - failure") {
    CardCreationResultView(
        state: .failure,
        selectedCount: 0,
        failedCount: 5,
        onDone: {}
    )
}
