import SwiftUI

struct CardEditHeader: View {
    let isSaveEnabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Text("스크린샷 정보 수정")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

            Spacer()

            Button("취소", action: onCancel)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)

            Button("완료", action: onSave)
                .foregroundStyle(isSaveEnabled ? RecapTheme.ColorToken.primary : CardDetailStyle.inputBorder)
                .disabled(!isSaveEnabled)
                .padding(.leading, 20)
        }
        .font(RecapFont.pretendard(size: 15, weight: .medium))
        .tracking(-0.3)
        .buttonStyle(.plain)
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .frame(height: 52)
    }
}

struct CardEditOriginalPreview: View {
    let card: InformationCard
    let onOpenOriginal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(card.dateText)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ZStack(alignment: .bottomTrailing) {
                RecapScreenshotThumbnail(kind: card.collection, assetName: card.detailImageAssetName)
                    .frame(height: CardDetailStyle.imageCardHeight)
                    .frame(maxWidth: .infinity)
                    .clipped()

                CardExpandButton(
                    foregroundColor: RecapTheme.ColorToken.textTertiary,
                    backgroundColor: .white,
                    action: onOpenOriginal
                )
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: CardDetailStyle.cornerRadius, style: .continuous))

            Text("원본 이미지는 수정 할 수 없어요. 텍스트 정보만 편집 가능해요")
                .font(RecapFont.pretendard(size: 10, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(Color(red: 56 / 255, green: 69 / 255, blue: 199 / 255))
                .padding(.top, 8)
        }
    }
}

struct CardEditTypeField: View {
    @Binding var collection: CollectionKind

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardEditFieldLabel(title: "유형")

            Menu {
                Picker("유형", selection: $collection) {
                    ForEach(CollectionKind.folderCases) { kind in
                        Text(RecapPresentation.collectionDisplay(for: kind).title)
                            .tag(kind)
                    }
                }
            } label: {
                HStack {
                    Text(RecapPresentation.collectionDisplay(for: collection).title)
                        .font(RecapFont.pretendard(size: 14, weight: .regular))
                        .tracking(-0.28)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                    Spacer()

                    Text("변경")
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(Color(red: 56 / 255, green: 69 / 255, blue: 199 / 255))
                }
                .padding(.horizontal, 12)
                .frame(height: 46)
                .cardEditFieldStyle()
            }
        }
    }
}

struct CardEditTextFieldGroup: View {
    let title: String
    @Binding var text: String
    let limit: Int
    let placeholder: String
    let showsRequiredError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardEditFieldLabel(title: title)

            TextField(placeholder, text: limitedText)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 46)
                .cardEditFieldStyle()

            HStack(spacing: 5) {
                if showsRequiredError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("필수 입력 항목입니다")
                        .font(RecapFont.pretendard(size: 12, weight: .medium))
                        .tracking(-0.24)
                }

                Spacer()

                Text("\(text.count)/\(limit)")
                    .font(RecapFont.pretendard(size: 12, weight: .medium))
                    .tracking(-0.24)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            }
            .foregroundStyle(CardDetailStyle.destructive)
        }
    }

    private var limitedText: Binding<String> {
        Binding(
            get: { text },
            set: { text = String($0.prefix(limit)) }
        )
    }
}

struct CardEditBodyField: View {
    @Binding var bodyText: String

    init(body: Binding<String>) {
        _bodyText = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardEditFieldLabel(title: "본문")

            TextEditor(text: limitedBody)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 7)
                .padding(.vertical, 6)
                .frame(height: 126)
                .cardEditFieldStyle()

            Text(String(format: "%03d/%03d", bodyText.count, CardEditDraft.bodyLimit))
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var limitedBody: Binding<String> {
        Binding(
            get: { bodyText },
            set: { bodyText = String($0.prefix(CardEditDraft.bodyLimit)) }
        )
    }
}

private struct CardEditFieldLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
    }
}

private extension View {
    func cardEditFieldStyle() -> some View {
        background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(CardDetailStyle.inputBorder, lineWidth: 1)
            }
    }
}
