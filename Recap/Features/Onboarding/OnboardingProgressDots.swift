import SwiftUI
struct RecapOnboardingDots: View {
    let activeIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == activeIndex ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.border)
                    .frame(width: index == activeIndex ? 17 : 8, height: 8)
            }
        }
    }
}
