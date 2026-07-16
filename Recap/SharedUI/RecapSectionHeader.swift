import SwiftUI
struct RecapSectionHeader: View {
    let title: String
    var trailingIcon: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
            Spacer()
            if let trailingIcon {
                Button(action: { action?() }) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.recapGray300)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 25)
    }
}
