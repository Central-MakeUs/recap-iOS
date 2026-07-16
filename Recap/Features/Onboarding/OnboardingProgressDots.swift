import SwiftUI
struct RecapOnboardingDots: View {
    let activeIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == activeIndex ? Color.recapBlue300 : Color.recapGray100)
                    .frame(width: index == activeIndex ? 17 : 8, height: 8)
            }
        }
    }
}
