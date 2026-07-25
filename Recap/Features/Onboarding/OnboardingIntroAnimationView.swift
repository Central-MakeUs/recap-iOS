import Lottie
import SwiftUI

struct OnboardingIntroAnimationView: UIViewRepresentable {
    let onFinished: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.clipsToBounds = true

        let animationView = LottieAnimationView(name: "recapsplash")
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .playOnce
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.clipsToBounds = true

        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        context.coordinator.playIfNeeded(animationView)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = uiView.subviews.first as? LottieAnimationView else {
            return
        }
        context.coordinator.playIfNeeded(animationView)
    }

    final class Coordinator {
        private let onFinished: () -> Void
        private var hasStarted = false

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }

        func playIfNeeded(_ animationView: LottieAnimationView) {
            guard !hasStarted else { return }
            hasStarted = true

            animationView.play { [onFinished] finished in
                guard finished else { return }
                Task { @MainActor in
                    onFinished()
                }
            }
        }
    }
}
