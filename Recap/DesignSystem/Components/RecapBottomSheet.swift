import SwiftUI

struct RecapBottomSheetDragIndicator {
    let width: CGFloat
    let height: CGFloat
    let topPadding: CGFloat

    static let standard = RecapBottomSheetDragIndicator(
        width: 36,
        height: 5,
        topPadding: 5
    )
}

extension View {
    func recapBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        height: CGFloat,
        cornerRadius: CGFloat,
        dragIndicator: RecapBottomSheetDragIndicator? = .standard,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            RecapBottomSheetModifier(
                isPresented: isPresented,
                height: height,
                cornerRadius: cornerRadius,
                dragIndicator: dragIndicator,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }
}

private struct RecapBottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool

    let height: CGFloat
    let cornerRadius: CGFloat
    let dragIndicator: RecapBottomSheetDragIndicator?
    let onDismiss: (() -> Void)?
    let sheetContent: () -> SheetContent

    @State private var isCoverPresented = false

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(isCoverPresented)
            .fullScreenCover(isPresented: $isCoverPresented, onDismiss: onDismiss) {
                RecapBottomSheetContainer(
                    isPresented: $isPresented,
                    isCoverPresented: $isCoverPresented,
                    height: height,
                    cornerRadius: cornerRadius,
                    dragIndicator: dragIndicator,
                    content: sheetContent
                )
                .presentationBackground(.clear)
            }
            .onChange(of: isPresented, initial: true) { _, shouldPresent in
                guard shouldPresent else { return }
                setCoverPresentedWithoutAnimation(true)
            }
    }

    private func setCoverPresentedWithoutAnimation(_ isPresented: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isCoverPresented = isPresented
        }
    }
}

private struct RecapBottomSheetContainer<Content: View>: View {
    @Binding var isPresented: Bool
    @Binding var isCoverPresented: Bool

    let height: CGFloat
    let cornerRadius: CGFloat
    let dragIndicator: RecapBottomSheetDragIndicator?
    let content: () -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var isSheetVisible = false
    @State private var transitionTask: Task<Void, Never>?

    private let presentationDuration = 0.28
    private let dismissalDuration = 0.22

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.30)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .frame(height: height, alignment: .top)
                .background(Color.white)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        topTrailingRadius: cornerRadius
                    )
                )
                .overlay(alignment: .top) {
                    if let dragIndicator {
                        Capsule()
                            .fill(Color.recapGray200)
                            .frame(
                                width: dragIndicator.width,
                                height: dragIndicator.height
                            )
                            .padding(.top, dragIndicator.topPadding)
                    }
                }
                .compositingGroup()
                .offset(y: isSheetVisible ? dragOffset : height)
                .simultaneousGesture(dismissGesture)
        }
        .ignoresSafeArea(.container)
        .accessibilityAction(.escape, dismiss)
        .onAppear(perform: presentSheet)
        .onChange(of: isPresented) { _, shouldPresent in
            if shouldPresent {
                presentSheet()
            } else {
                dismissSheet()
            }
        }
        .onDisappear {
            transitionTask?.cancel()
        }
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                let shouldDismiss = value.translation.height > 80
                    || value.predictedEndTranslation.height > 160

                if shouldDismiss {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func dismiss() {
        isPresented = false
    }

    private func presentSheet() {
        transitionTask?.cancel()
        transitionTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, isPresented else { return }

            withAnimation(.easeOut(duration: presentationDuration)) {
                isSheetVisible = true
            }
        }
    }

    private func dismissSheet() {
        transitionTask?.cancel()
        transitionTask = Task { @MainActor in
            withAnimation(.easeIn(duration: dismissalDuration)) {
                isSheetVisible = false
                dragOffset = 0
            }

            try? await Task.sleep(for: .seconds(dismissalDuration))
            guard !Task.isCancelled else { return }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                isCoverPresented = false
            }
        }
    }
}

#if DEBUG
#Preview("공통 바텀 시트") {
    @Previewable @State var isPresented = true

    Color.recapBackground
        .ignoresSafeArea()
        .recapBottomSheet(
            isPresented: $isPresented,
            height: 288,
            cornerRadius: 20
        ) {
            Text("바텀 시트")
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        }
}
#endif
