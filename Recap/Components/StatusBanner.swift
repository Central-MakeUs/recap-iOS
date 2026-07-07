import SwiftUI

struct StatusBanner: View {
    let status: HomeStatus

    var body: some View {
        let display = RecapPresentation.statusDisplay(for: status)

        HStack(alignment: .top, spacing: RecapTheme.Spacing.medium) {
            Image(systemName: display.iconName)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(display.tint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: RecapTheme.Spacing.small) {
                Text(display.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(display.message)
                    .font(.caption)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let progress = display.progress {
                    VStack(alignment: .leading, spacing: RecapTheme.Spacing.xSmall) {
                        HStack {
                            Text("진행 상태")
                            Spacer()
                            Text("2 / 3개 완료")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RecapTheme.ColorToken.primary)

                        ProgressView(value: progress)
                            .tint(RecapTheme.ColorToken.primary)
                    }
                }
            }
        }
        .padding(RecapTheme.Spacing.large)
        .recapCard(fill: display.background)
    }
}

struct ConfirmationBanner: View {
    var body: some View {
        HStack(spacing: RecapTheme.Spacing.medium) {
            Image(systemName: "exclamationmark")
                .font(.caption.weight(.black))
                .foregroundStyle(RecapTheme.ColorToken.warning)
                .frame(width: 24, height: 24)
                .background(RecapTheme.ColorToken.warningSoft)
                .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("확인이 필요한 카드 1개")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                Text("분류가 애매한 카드는 따로 확인할 수 있어요")
                    .font(.caption)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            }

            Spacer()

            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.warning)
        }
        .padding(RecapTheme.Spacing.medium)
        .recapCard(borderColor: Color(red: 0.970, green: 0.830, blue: 0.560), fill: RecapTheme.ColorToken.warningSoft)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: RecapTheme.Spacing.medium) {
            ForEach(HomeStatus.allCases) { status in
                StatusBanner(status: status)
            }
            ConfirmationBanner()
        }
        .padding()
    }
    .background(RecapTheme.ColorToken.background)
}
