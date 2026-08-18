import SwiftUI

/// 왼쪽으로 밀면 뒤에 있던 버튼이 드러나는 행.
///
/// SwiftUI의 `swipeActions`는 `List` 안에서만 동작하는데, 목록 화면들이
/// Figma 수치대로 행을 그리려고 `LazyVStack`을 쓰고 있어 쓸 수 없다.
/// 그래서 끌기 제스처로 같은 동작을 만든다.
///
/// 열린 행은 한 번에 하나여야 하므로 어느 행이 열렸는지는 바깥이 들고 있는다.
/// 목록이 그 값을 공유하면 다른 행을 밀 때 먼저 열린 행이 닫힌다.
/// 제네릭 타입 안에는 저장 프로퍼티를 둘 수 없어 밖에 뺀다.
private enum Layout {
    static let actionWidth: CGFloat = 74
    /// 드러난 너비의 이 비율을 넘게 끌면 손을 뗐을 때 열린다.
    static let openThreshold: CGFloat = 0.4
    /// 세로로 이 배수보다 더 움직였으면 스크롤로 보고 넘긴다.
    static let horizontalBias: CGFloat = 1.4
}

struct RecapSwipeActionRow<Content: View>: View {
    struct Action: Identifiable {
        let id = UUID()
        let title: String
        let foregroundColor: Color
        let backgroundColor: Color
        let handler: () -> Void

        init(
            title: String,
            foregroundColor: Color,
            backgroundColor: Color,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.foregroundColor = foregroundColor
            self.backgroundColor = backgroundColor
            self.handler = handler
        }
    }

    /// 카드 목록이 쓰는 두 버튼. 세 화면이 같아야 해서 여기 둔다.
    static func cardActions(
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> [Action] {
        [
            Action(
                title: "수정",
                foregroundColor: Color.recapGray700,
                backgroundColor: Color.recapGray50,
                handler: onEdit
            ),
            Action(
                title: "삭제",
                foregroundColor: Color.recapDestructiveText,
                backgroundColor: Color.recapDestructiveSoft,
                handler: onDelete
            )
        ]
    }

    let rowID: AnyHashable
    let actions: [Action]
    @Binding var openRowID: AnyHashable?
    var isEnabled = true

    @ViewBuilder let content: () -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var isDragHorizontal: Bool?

    private var isOpen: Bool { openRowID == rowID }

    private var revealWidth: CGFloat {
        Layout.actionWidth * CGFloat(actions.count)
    }

    private var offset: CGFloat {
        let base = isOpen ? -revealWidth : 0
        return min(0, max(-revealWidth, base + dragOffset))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if isEnabled {
                actionStrip
            }

            content()
                .background(Color.recapBackground)
                // 열린 행을 누르면 아래 화면으로 가는 대신 닫기만 한다.
                //
                // 이 덮개는 반드시 `offset` 앞에 와야 한다. 뒤에 붙이면 밀리기 전
                // 자리에 깔려서 드러난 버튼까지 덮어버린다.
                .overlay {
                    if isOpen {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: close)
                    }
                }
                .offset(x: offset)
        }
        .animation(.snappy(duration: 0.25), value: isOpen)
        .gesture(isEnabled ? dragGesture : nil)
        .onChange(of: isEnabled) { _, enabled in
            if !enabled { close() }
        }
    }

    private var actionStrip: some View {
        HStack(spacing: 0) {
            ForEach(actions) { action in
                Button {
                    action.handler()
                    close()
                } label: {
                    Text(action.title)
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(action.foregroundColor)
                        .frame(width: Layout.actionWidth)
                        .frame(maxHeight: .infinity)
                        .background(action.backgroundColor)
                }
                .buttonStyle(.plain)
            }
        }
        // 닫혀 있을 때는 버튼이 행 뒤에 완전히 가려지지만, 보조 기술에는
        // 여전히 노출된다. 열렸을 때만 짚이도록 막는다.
        .accessibilityHidden(!isOpen)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if isDragHorizontal == nil {
                    isDragHorizontal = abs(value.translation.width)
                        > abs(value.translation.height) * Layout.horizontalBias
                }
                guard isDragHorizontal == true else { return }

                // 다른 행이 열려 있었다면 이 행을 밀기 시작할 때 닫는다.
                if openRowID != nil, !isOpen {
                    openRowID = nil
                }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                defer { isDragHorizontal = nil }
                guard isDragHorizontal == true else { return }

                let settled = (isOpen ? -revealWidth : 0) + value.translation.width
                let shouldOpen = settled < -revealWidth * Layout.openThreshold
                dragOffset = 0
                openRowID = shouldOpen ? rowID : nil
            }
    }

    private func close() {
        dragOffset = 0
        openRowID = nil
    }
}

#if DEBUG
private struct RecapSwipeActionRowPreview: View {
    @State private var openRowID: AnyHashable?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SampleData.recentCards.prefix(3).compactMap(Card.init(snapshot:))) { card in
                RecapSwipeActionRow(
                    rowID: card.captureID,
                    actions: RecapSwipeActionRow.cardActions(onEdit: {}, onDelete: {}),
                    openRowID: $openRowID
                ) {
                    RecapInformationCardRow(card: card)
                }
            }
        }
        .background(Color.recapBackground)
    }
}

#Preview("스와이프 액션 행") {
    RecapSwipeActionRowPreview()
}

#Preview("스와이프 액션 - 열림") {
    let card = Card(snapshot: SampleData.recentCards[0])

    RecapSwipeActionRow(
        rowID: card.captureID,
        actions: RecapSwipeActionRow.cardActions(onEdit: {}, onDelete: {}),
        openRowID: .constant(card.captureID)
    ) {
        RecapInformationCardRow(card: card)
    }
    .frame(height: 118)
    .background(Color.recapBackground)
}
#endif
