import SwiftUI

struct CardDetailReportSheet: View {
    let onSubmit: (CaptureReportReason, String?) -> Void

    @State private var selectedReason: CaptureReportReason?
    @State private var detail = ""
    @FocusState private var isDetailFocused: Bool

    init(
        selectedReason: CaptureReportReason? = nil,
        detail: String = "",
        onSubmit: @escaping (CaptureReportReason, String?) -> Void
    ) {
        self.onSubmit = onSubmit
        _selectedReason = State(initialValue: selectedReason)
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
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 30) {
                ForEach(CaptureReportReason.allCases, id: \.rawValue) { reason in
                    reasonButton(reason)
                }
            }
            .padding(.top, 36)

            if selectedReason == .other {
                TextField("어떤 문제인지 알려주세요 (선택)", text: $detail)
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

            Spacer(minLength: 20)

            Button(action: submit) {
                Text("신고하기")
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedReason == nil ? Color.recapGray200 : Color.recapBlue300)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedReason == nil)
        }
        .padding(.top, 39)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func reasonButton(_ reason: CaptureReportReason) -> some View {
        Button {
            selectedReason = reason
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

    private func submit() {
        guard let selectedReason else { return }
        let normalizedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        onSubmit(selectedReason, normalizedDetail.isEmpty ? nil : normalizedDetail)
    }
}

#Preview("정보카드 신고 메뉴") {
    CardDetailReportSheet(selectedReason: .other) { _, _ in }
}
