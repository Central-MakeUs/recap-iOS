import SwiftUI

struct RecapSortToggleButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .regular))
                    .frame(width: 16, height: 16)

                Text(title)
                    .font(RecapFont.pretendard(size: 12, weight: .medium))
                    .tracking(-0.24)
            }
            .foregroundStyle(Color.recapFilterText)
            .frame(width: 92, height: 35)
            .background(Color.recapControlFill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("최신순") {
    RecapSortToggleButton(title: "최신순", action: {})
        .padding()
}

#Preview("오래된순") {
    RecapSortToggleButton(title: "오래된순", action: {})
        .padding()
}
#endif
