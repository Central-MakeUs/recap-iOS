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
                RecapIconView(icon: icon, size: 16, color: Color.recapFilterText)
            }
            .foregroundStyle(Color.recapFilterText)
            .padding(.horizontal, 16)
            .frame(height: 35)
            .background(Color.recapControlFill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct RecapFilterPicker: View {
    let options: [String]
    @Binding var selection: String
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 10) {
                    Text(selection)
                    RecapIconView(
                        icon: .dropdown,
                        size: 16,
                        color: Color.recapFilterText
                    )
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(Color.recapFilterText)
                .padding(.horizontal, 16)
                .frame(width: 92, height: 32)
                .background(Color.recapControlFill)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(options.filter { $0 != selection }, id: \.self) { option in
                    Button(option) {
                        selection = option
                        isExpanded = false
                    }
                    .font(RecapFont.pretendard(size: 12, weight: .medium))
                    .tracking(-0.24)
                    .foregroundStyle(Color.recapGray300)
                    .frame(width: 92, height: 32)
                    .background(Color.recapControlFill)
                    .buttonStyle(.plain)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: isExpanded)
    }
}

#Preview("Filter") {
    @Previewable @State var selection = "최신순"
    @Previewable @State var isExpanded = true

    HStack(alignment: .top) {
        RecapFilterButton(title: "최신순")
        RecapFilterPicker(
            options: ["최신순", "즐겨찾기"],
            selection: $selection,
            isExpanded: $isExpanded
        )
    }
    .padding()
}
