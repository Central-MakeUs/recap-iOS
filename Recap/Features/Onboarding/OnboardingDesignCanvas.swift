import SwiftUI

struct OnboardingDesignCanvas<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 375

            ZStack(alignment: .topLeading) {
                Color.recapBackground
                content
            }
            .frame(width: 375, height: 812)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .topLeading
            )
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    func onboardingFrame(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        alignment: Alignment = .center
    ) -> some View {
        frame(width: width, height: height, alignment: alignment)
            .position(x: x + width / 2, y: y + height / 2)
    }
}
