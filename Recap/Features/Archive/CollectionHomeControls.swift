import SwiftUI

struct CollectionHomeHeader: View {
    let segment: CollectionHomeView.Segment
    @Binding var layoutMode: CollectionHomeView.LayoutMode

    var body: some View {
        HStack(spacing: 6) {
            Image("RecapArchiveIcon")
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 14)
                .frame(width: 24, height: 24)

            Text("보관함")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(Color.recapGray900)

            Spacer()

            if segment == .type {
                Text("보기")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapGray500)

                HStack(spacing: 6) {
                    layoutButton(mode: .grid, icon: .grid)
                    layoutButton(mode: .list, icon: .list)
                }
                .padding(.horizontal, 5)
                .frame(width: 64, height: 31)
                .background(Color.recapControlFill)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
        .frame(height: 31)
    }

    private func layoutButton(mode: CollectionHomeView.LayoutMode, icon: RecapIcon) -> some View {
        Button {
            layoutMode = mode
        } label: {
            RecapIconView(
                icon: icon,
                size: 16,
                color: layoutMode == mode ? Color.recapBlue300 : Color.recapGray300
            )
                .frame(width: 24, height: 24)
                .background(layoutMode == mode ? Color.white : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct CollectionHomeSegmentControl: View {
    @Binding var selection: CollectionHomeView.Segment

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CollectionHomeView.Segment.allCases) { item in
                Button {
                    selection = item
                } label: {
                    Text(item.rawValue)
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(selection == item ? .white : Color.recapGray300)
                        .frame(width: 87, height: 35)
                        .background(selection == item ? Color.recapBlue300 : Color.recapControlFill)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
