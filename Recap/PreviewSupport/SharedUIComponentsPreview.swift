import SwiftUI
#Preview("Figma primitives") {
    ZStack {
        Color.recapBackground.ignoresSafeArea()
        VStack(spacing: 24) {
            RecapLogoText()
            RecapOnboardingDots(activeIndex: 2, count: 4)
            RecapMascotMark(size: 96)
            RecapSearchEmptyIllustration(size: 140)
            RecapIncompleteCallout(title: "검색 실패", message: "연결 전 상태를 명시합니다.")
        }
        .padding()
    }
}
