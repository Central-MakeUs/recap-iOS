import SwiftUI

struct InitialRangeSelectionView: View {
    @Binding var selectedRange: InitialRange
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.recapGray500)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("2 / 3")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.recapBlue300)
            }
            .padding(.horizontal, RecapTheme.Spacing.xLarge)
            .padding(.top, RecapTheme.Spacing.medium)

            VStack(alignment: .leading, spacing: RecapTheme.Spacing.medium) {
                Text("처음 정리할 스크린샷\n범위를 선택해주세요")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Color.recapGray900)
                    .lineSpacing(3)

                Text("먼저 최근 스크린샷부터 정리해보세요.\n이후 새로 저장되는 스크린샷은 자동으로 정리됩니다.")
                    .font(.subheadline)
                    .foregroundStyle(Color.recapGray500)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, RecapTheme.Spacing.xLarge)
            .padding(.top, RecapTheme.Spacing.xLarge)

            VStack(spacing: RecapTheme.Spacing.medium) {
                ForEach(InitialRange.allCases) { range in
                    RangeOptionCard(
                        range: range,
                        isSelected: selectedRange == range,
                        onSelect: { selectedRange = range }
                    )
                }
            }
            .padding(.horizontal, RecapTheme.Spacing.xLarge)
            .padding(.top, RecapTheme.Spacing.xLarge)

            Spacer()

            RecapButton(title: "이 범위로 정리 시작", style: .primary, action: onContinue)
                .padding(.horizontal, RecapTheme.Spacing.xLarge)
                .padding(.bottom, RecapTheme.Spacing.xxLarge)
        }
        .background(Color.recapBackground)
    }
}

private struct RangeOptionCard: View {
    let range: InitialRange
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        let option = RecapPresentation.initialRangeOption(for: range)

        Button(action: onSelect) {
            HStack(spacing: RecapTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: RecapTheme.Spacing.small) {
                        Text(option.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.recapGray900)
                        if option.isRecommended {
                            Text("추천")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.recapBlue300)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.recapBlue300.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }

                    Text(option.countText)
                        .font(.caption)
                        .foregroundStyle(Color.recapGray500)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.recapBlue300 : Color.recapGray100, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.recapBlue300)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(RecapTheme.Spacing.large)
            .recapCard(
                radius: RecapTheme.Radius.medium,
                borderColor: isSelected ? Color.recapBlue300 : Color.recapGray100,
                fill: isSelected ? Color.recapPrimarySoft : Color.white
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InitialRangeSelectionView(selectedRange: .constant(.thirtyDays), onBack: {}, onContinue: {})
}
