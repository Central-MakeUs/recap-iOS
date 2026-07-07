import SwiftUI

struct TagChip: View {
    let title: String
    var color: Color = RecapTheme.ColorToken.primary
    var isSelected = false

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, RecapTheme.Spacing.medium)
            .padding(.vertical, RecapTheme.Spacing.small)
            .background(isSelected ? color : color.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
    }
}

#Preview {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        HStack {
            TagChip(title: "전체", isSelected: true)
            TagChip(title: "맛집")
            TagChip(title: "#성수동")
        }
        .padding()
    }
}
