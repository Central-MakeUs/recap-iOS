import SwiftUI

struct RecapFilterButton: View {
    let title: String
    var icon: RecapIcon = .dropdown
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(RecapFont.pretendard(size: 12, weight: .medium))
                    .tracking(-0.24)
                RecapIconView(icon: icon, size: 16, color: RecapComponentColor.filterText)
            }
            .foregroundStyle(RecapComponentColor.filterText)
            .padding(.leading, 11)
            .padding(.trailing, 11)
            .frame(height: 32)
            .background(RecapComponentColor.controlFill)
            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Filter") {
    ZStack {
        Color.green.ignoresSafeArea()
        RecapFilterButton(title: "최신순")
    }
}
