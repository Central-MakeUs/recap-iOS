import SwiftUI
struct RecapInlineEmptyView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.recapThumbnail)
                .frame(width: 48, height: 48)
            Text(title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .foregroundStyle(Color.recapGray900)
            Text(message)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .foregroundStyle(Color.recapGray300)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}
