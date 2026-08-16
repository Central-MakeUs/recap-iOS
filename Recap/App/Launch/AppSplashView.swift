import SwiftUI

struct AppSplashView: View {
    let onFinished: @MainActor @Sendable () -> Void

    var body: some View {
        GeometryReader { proxy in
            AppSplashAnimationView(onFinished: onFinished)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Color.recapBlue300)
        .ignoresSafeArea()
        .accessibilityLabel("Recap 시작 화면")
    }
}

#if DEBUG
#Preview("App splash") {
    AppSplashView(onFinished: {})
}
#endif
