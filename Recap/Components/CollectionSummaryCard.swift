import SwiftUI

struct CollectionSummaryCard: View {
    let summary: CollectionSummary
    var compact = false

    var body: some View {
        let collection = RecapPresentation.collectionDisplay(for: summary.kind)

        HStack(spacing: RecapTheme.Spacing.medium) {
            RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                .fill(collection.dotColor.opacity(0.14))
                .frame(width: compact ? 16 : 34, height: compact ? 16 : 34)
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 5 : 9, style: .continuous)
                        .fill(collection.dotColor)
                        .frame(width: compact ? 8 : 12, height: compact ? 8 : 12)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(collection.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                Text(compact ? "\(summary.count)" : collection.subtitle)
                    .font(.caption)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .lineLimit(1)

                if !compact {
                    Text(summary.previewTitle)
                        .font(.caption2)
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }

            Spacer()

            if !compact {
                Text("\(summary.count)개")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.textTertiary)
            }
        }
        .padding(compact ? RecapTheme.Spacing.small : RecapTheme.Spacing.medium)
        .recapCard(radius: RecapTheme.Radius.medium)
    }
}

#Preview {
    VStack(spacing: RecapTheme.Spacing.medium) {
        CollectionSummaryCard(summary: SampleData.collectionSummaries[0])
        CollectionSummaryCard(summary: SampleData.collectionSummaries[1], compact: true)
    }
    .padding()
    .background(RecapTheme.ColorToken.background)
}
