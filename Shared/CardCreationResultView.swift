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
    /// Figma 03-04_정리 완료(375x812) 기준.
    ///
    /// 절대 y 좌표가 아니라 요소 사이 간격으로 적는다. 절대 좌표로 두면 간격이
    /// 코드에 드러나지 않고, 글자 크기나 화면 높이가 달라질 때 어긋난다.
    private enum Layout {
        /// 화면 최상단에서 체크 아이콘까지. Figma 190.
        static let topInset: CGFloat = 190
        /// Figma 아이콘 40×40. 그 안의 체크는 30이고 사방 5씩 여백이 있다.
        static let checkSize: CGFloat = 40
        /// 체크 아래 240 - (190 + 40).
        static let titleSpacing: CGFloat = 10
        /// 제목(2줄, 높이 50) 아래 334 - (240 + 50).
        static let characterSpacing: CGFloat = 44
        static let characterSize = CGSize(width: 195.09, height: 119.43)
        /// 캐릭터만 가운데가 아니다. Figma 좌여백 81, 우여백 98.91이라
        /// 화면 중심에서 왼쪽으로 치우쳐 있다.
        static let characterCenterOffset: CGFloat = -8.96
        /// 캐릭터 아래 481 - (334 + 119.43).
        static let subtitleSpacing: CGFloat = 27.57
        /// 체크 아이콘이 커지는 시점. 이때 컨페티가 터진다.
        static let confettiDelay: Duration = .milliseconds(420)
    }

    let organizedCount: Int

    @State private var confettiTrigger = 0

    var body: some View {
        VStack(spacing: 0) {
            RecapLottieView(name: "complete_check", playback: .playOnce)
                .frame(width: Layout.checkSize, height: Layout.checkSize)

            Text("\(organizedCount)개의 스크린샷을\n정리했어요")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .lineSpacing(0)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray900)
                .padding(.top, Layout.titleSpacing)

            // 움직임은 컨페티가 담당한다. 캐릭터는 정지 이미지다.
            Image("CardCreationCompleteCharacter")
                .resizable()
                .scaledToFit()
                .frame(
                    width: Layout.characterSize.width,
                    height: Layout.characterSize.height
                )
                .offset(x: Layout.characterCenterOffset)
                .padding(.top, Layout.characterSpacing)

            Text("보관함에서 확인해보세요!")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, Layout.subtitleSpacing)

            Spacer(minLength: 0)
        }
        .padding(.top, Layout.topInset)
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
