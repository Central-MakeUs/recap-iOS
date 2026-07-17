import SwiftUI

struct RecapSectionHeader: View {
    let title: String
    var showsNavigationIndicator = false
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
            Spacer()
            if showsNavigationIndicator {
                Button(action: { action?() }) {
                    RecapIconView(
                        icon: .forward,
                        size: 20,
                        color: Color.recapGray300
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 25)
    }
}
