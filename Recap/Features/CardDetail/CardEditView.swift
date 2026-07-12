import SwiftUI

struct CardEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    @State private var draft: CardEditDraft?

    private var card: InformationCard? {
        cardStore.card(id: cardID)
    }

    var body: some View {
        Group {
            if let card, let draft {
                editForm(card: card, draft: draft)
            } else {
                MissingCardView(cardID: cardID)
            }
        }
        .navigationTitle("스크린샷 정보 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소", action: cancel)
                    .font(RecapFont.pretendard(size: 15, weight: .medium))
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("완료", action: save)
                    .font(RecapFont.pretendard(size: 15, weight: .semibold))
                    .disabled(draft?.isSavable != true)
            }
        }
        .onAppear(perform: syncDraft)
    }

    private func editForm(card: InformationCard, draft: CardEditDraft) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                originalPreview(for: card)

                editFieldGroup(title: "유형") {
                    Menu {
                        Picker("유형", selection: draftBinding.collection) {
                            ForEach(CollectionKind.folderCases) { kind in
                                Text(RecapPresentation.collectionDisplay(for: kind).title)
                                    .tag(kind)
                            }
                        }
                    } label: {
                        HStack {
                            Text(RecapPresentation.collectionDisplay(for: draft.collection).title)
                                .font(RecapFont.pretendard(size: 15, weight: .medium))
                                .tracking(-0.3)
                                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                            Spacer()

                            Text("변경")
                                .font(RecapFont.pretendard(size: 13, weight: .semibold))
                                .tracking(-0.26)
                                .foregroundStyle(RecapTheme.ColorToken.primary)
                        }
                        .frame(height: 45)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
                        }
                    }
                }

                editFieldGroup(title: "제목", limitText: "\(draft.title.count)/30") {
                    RecapEditTextField(text: draftBinding.title, lineLimit: 1)
                }

                editFieldGroup(title: "한 줄 요약", limitText: "\(draft.summary.count)/80") {
                    RecapEditTextField(text: draftBinding.summary, lineLimit: 2)
                }

                editFieldGroup(title: "본문", limitText: "\(draft.body.count)/500") {
                    RecapEditTextEditor(text: draftBinding.body)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(RecapTheme.ColorToken.background)
    }

    private func originalPreview(for card: InformationCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.dateText)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)

            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(height: 182)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text("원본 이미지는 수정할 수 없어요. 텍스트 정보만 편집 가능해요")
                .font(RecapFont.pretendard(size: 11, weight: .medium))
                .tracking(-0.22)
                .foregroundStyle(RecapTheme.ColorToken.primary)
        }
    }

    private func editFieldGroup<Content: View>(
        title: String,
        limitText: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

            content()

            if let limitText {
                Text(limitText)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var draftBinding: Binding<CardEditDraft> {
        Binding(
            get: {
                if let draft {
                    return draft
                }
                if let card {
                    return CardEditDraft(card: card)
                }
                return CardEditDraft(
                    collection: .capture,
                    title: "",
                    summary: "",
                    body: ""
                )
            },
            set: { draft = $0 }
        )
    }

    private func syncDraft() {
        guard draft == nil, let card else { return }
        draft = CardEditDraft(card: card)
    }

    private func cancel() {
        dismiss()
    }

    private func save() {
        guard let draft, draft.isSavable else { return }
        cardStore.updateCard(id: cardID, with: draft.normalized())
        dismiss()
    }
}

private struct RecapEditTextField: View {
    @Binding var text: String
    let lineLimit: Int

    var body: some View {
        TextField("", text: $text, axis: lineLimit == 1 ? .horizontal : .vertical)
            .font(RecapFont.pretendard(size: 15, weight: .medium))
            .tracking(-0.3)
            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            .lineLimit(lineLimit)
            .padding(.horizontal, 13)
            .padding(.vertical, 13)
            .frame(minHeight: 45, alignment: .topLeading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
            }
    }
}

private struct RecapEditTextEditor: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(RecapFont.pretendard(size: 15, weight: .medium))
            .tracking(-0.3)
            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(minHeight: 124)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
            }
    }
}

#Preview {
    NavigationStack {
        CardEditView(cardID: SampleData.cards[1].id)
            .environment(PreviewStores.recapCardStore())
    }
}
