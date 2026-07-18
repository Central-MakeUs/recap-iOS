import SwiftUI

struct CollectionHomeHeader: View {
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
        .frame(height: 31)
    }

    private func layoutButton(
        mode: CollectionHomeView.LayoutMode,
        icon: RecapIcon
    ) -> some View {
        Button {
            layoutMode = mode
        } label: {
            RecapIconView(
                icon: icon,
                size: 24,
                color: layoutMode == mode ? Color.recapGray700 : Color.recapGray200
            )
            .frame(width: 24, height: 24)
            .background(layoutMode == mode ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct CollectionHomeFavoritesLink: View {
    let count: Int

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.recapBackground)
                .frame(width: 30, height: 30)
                .overlay {
                    RecapIconView(icon: .star, size: 24, color: Color.recapBlue300)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("즐겨찾기")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(Color.recapGray900)

                Text(
                    "\(Text("\(count)").font(RecapFont.pretendard(size: 14, weight: .semibold))) recaps"
                )
                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                    .tracking(-0.28)
                    .foregroundStyle(Color.recapGray500)
            }

            Spacer()

            RecapIconView(icon: .forward, size: 24, color: Color.recapGray200)
        }
        .padding(.horizontal, 17)
        .frame(height: 76)
        .background(Color.recapBlue50)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

#Preview("보관함 헤더") {
    @Previewable @State var layoutMode = CollectionHomeView.LayoutMode.grid

    CollectionHomeHeader(layoutMode: $layoutMode)
        .padding()
}

#Preview("즐겨찾기 진입 카드") {
    CollectionHomeFavoritesLink(count: 3)
        .padding()
}
