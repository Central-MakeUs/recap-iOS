import ConfettiSwiftUI
import SwiftUI

struct CardCreationResultView: View {
    let state: CardCreationResultState
    var selectedCount = 5
    var failedCount = 1
    let onDone: () -> Void

    var body: some View {
        Group {
            if state == .complete {
                // Figma 좌표는 상태 바를 포함한 화면 최상단 기준이다.
                completeContent
                    .ignoresSafeArea(.container, edges: [.top, .bottom])
            } else {
                legacyContent
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
    }

    /// Figma 03-04_정리 완료. 체크·캐릭터 애니메이션과 하단 그라디언트 배경을 쓴다.
    private var completeContent: some View {
        CardCreationCompleteResultContent(organizedCount: selectedCount)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .bottom) {
                doneButton
            }
            .background {
                ZStack(alignment: .bottom) {
                    Color.recapBackground

                    // Figma 주석: 정리 완료 페이지는 배경 그라디언트 추가 (#8FA4FF, 40%)
                    LinearGradient(
                        colors: [
                            Color(red: 143 / 255, green: 164 / 255, blue: 255 / 255)
                                .opacity(0),
                            Color(red: 143 / 255, green: 164 / 255, blue: 255 / 255)
                                .opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 445)
                }
                .ignoresSafeArea()
            }
    }

    private var legacyContent: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 141)

            resultContent

            Spacer(minLength: 20)

            doneButton
        }
        .background(Color.recapBackground)
    }

    private var doneButton: some View {
        RecapButton(
            title: state.buttonTitle,
            style: .primary,
            action: onDone
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 31)
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
    /// Figma 03-04_정리 완료(375x812) 기준 절대 y 좌표.
    private enum Layout {
        static let checkTop: CGFloat = 188
        static let checkSize: CGFloat = 45
        static let titleTop: CGFloat = 240
        static let characterTop: CGFloat = 215
        static let characterHeight: CGFloat = 300
        static let subtitleTop: CGFloat = 481
        /// 체크 아이콘이 커지는 시점. 이때 컨페티가 터진다.
        static let confettiDelay: Duration = .milliseconds(420)
    }

    let organizedCount: Int

    @State private var confettiTrigger = 0

    var body: some View {
        ZStack(alignment: .top) {
            RecapLottieView(name: "complete_check", playback: .playOnce)
                .frame(width: Layout.checkSize, height: Layout.checkSize)
                .padding(.top, Layout.checkTop)

            Text("\(organizedCount)개의 스크린샷을\n정리했어요")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .lineSpacing(0)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray900)
                .padding(.top, Layout.titleTop)

            RecapLottieView(name: "complete_character", playback: .playOnce)
                .frame(height: Layout.characterHeight)
                .frame(maxWidth: .infinity)
                .padding(.top, Layout.characterTop)

            Text("보관함에서 확인해보세요!")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, Layout.subtitleTop)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // 체크 아이콘 중심에서 터져 화면 전체로 퍼진 뒤 아래로 떨어진다.
        .confettiCannon(
            trigger: $confettiTrigger,
            num: 60,
            confettis: [.shape(.square), .shape(.slimRectangle)],
            colors: [.recapBlue500, .recapBlue300, .recapBlue50],
            confettiSize: 8,
            rainHeight: 900,
            radius: 420,
            hapticFeedback: false
        )
        .task {
            try? await Task.sleep(for: Layout.confettiDelay)
            confettiTrigger += 1
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

#if DEBUG
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
#endif
