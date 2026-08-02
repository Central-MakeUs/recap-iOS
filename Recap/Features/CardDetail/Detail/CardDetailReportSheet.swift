import SwiftUI

struct CardDetailReportSheet: View {
    @Binding private var selectedReason: CaptureReportReason?

    let onSubmit: (CaptureReportReason, String?) -> Void
    let onClose: () -> Void

    @State private var detail = ""
    @FocusState private var isDetailFocused: Bool

    init(
        selectedReason: Binding<CaptureReportReason?>,
        detail: String = "",
        onSubmit: @escaping (CaptureReportReason, String?) -> Void,
        onClose: @escaping () -> Void
    ) {
        _selectedReason = selectedReason
        self.onSubmit = onSubmit
        self.onClose = onClose
        _detail = State(initialValue: detail)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("어떤 문제인가요?")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray900)

            Text("신고 내용은 검토 후 서비스 개선에 반영돼요.")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, isOtherSelected ? 7 : 10)

            VStack(alignment: .leading, spacing: reasonSpacing) {
                ForEach(CaptureReportReason.allCases, id: \.rawValue) { reason in
                    reasonButton(reason)
                }
            }
            .padding(.top, isOtherSelected ? 36 : 34)

            if isOtherSelected {
                TextField(
                    "",
                    text: $detail,
                    prompt: Text("어떤 문제인지 알려주세요 (선택)")
                        .foregroundStyle(Color.recapGray300)
                )
                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                    .tracking(-0.28)
                    .foregroundStyle(Color.recapGray700)
                    .focused($isDetailFocused)
                    .padding(.horizontal, 13)
                    .frame(height: 46)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.recapGray200, lineWidth: 1)
                    }
                    .padding(.top, 17)
            }

            primaryButton
                .padding(.top, isOtherSelected ? 21 : 48)
        }
        .padding(.top, isOtherSelected ? 40 : 30)
        .padding(.horizontal, 16)
        .padding(.bottom, isOtherSelected ? 20 : 17)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var isOtherSelected: Bool {
        selectedReason == .other
    }

    private var reasonSpacing: CGFloat {
        isOtherSelected ? 30 : 20
    }

    private var primaryButton: some View {
        Button(action: performPrimaryAction) {
            Group {
                if selectedReason == nil {
                    Text("닫기")
                        .font(RecapFont.pretendard(size: 15, weight: .medium))
                        .tracking(-0.3)
                        .foregroundStyle(Color.recapGray700)
                } else {
                    Text("신고하기")
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(selectedReason == nil ? Color.white : Color.recapBlue300)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                if selectedReason == nil {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.recapGray100, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func reasonButton(_ reason: CaptureReportReason) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedReason = reason
            }
            if reason != .other {
                detail = ""
                isDetailFocused = false
            }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(
                            selectedReason == reason ? Color.recapBlue300 : Color.recapGray200,
                            lineWidth: 1
                        )

                    if selectedReason == reason {
                        Circle()
                            .fill(Color.recapBlue300)
                            .padding(3)
                    }
                }
                .frame(width: 20, height: 20)

                Text(reason.title)
                    .font(RecapFont.pretendard(size: 15, weight: .medium))
                    .tracking(-0.3)
                    .foregroundStyle(Color.recapGray700)
            }
            .frame(height: 21)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func performPrimaryAction() {
        if selectedReason == nil {
            onClose()
        } else {
            submit()
        }
    }

    private func submit() {
        guard let selectedReason else { return }
        let normalizedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        onSubmit(selectedReason, normalizedDetail.isEmpty ? nil : normalizedDetail)
    }
}

#Preview("정보카드 신고 메뉴 - 선택 전") {
    @Previewable @State var selectedReason: CaptureReportReason?

    CardDetailReportSheet(
        selectedReason: $selectedReason,
        onSubmit: { _, _ in },
        onClose: PreviewActions.noop
    )
}

#Preview("정보카드 신고 메뉴 - 기타") {
    @Previewable @State var selectedReason: CaptureReportReason? = .other

    CardDetailReportSheet(
        selectedReason: $selectedReason,
        onSubmit: { _, _ in },
        onClose: PreviewActions.noop
    )
}
