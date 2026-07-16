import SwiftUI
struct RecapIncompleteCallout: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text("미완성")
                .font(RecapFont.pretendard(size: 11, weight: .bold))
                .tracking(-0.12)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.recapUnimplemented)
                .clipShape(Capsule())
            Text(title)
                .font(RecapFont.pretendard(size: 15, weight: .semibold))
                .foregroundStyle(Color.recapGray900)
            Text(message)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray500)
        }
        .padding(18)
        .background(Color.recapWarningSoft)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.recapUnimplemented, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
