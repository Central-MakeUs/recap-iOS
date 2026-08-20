//
//  RecapApp.swift
//  Recap
//
//  Created by oliver on 6/29/26.
//

import SwiftUI

@main
struct RecapApp: App {
#if DEMO_SHOWCASE
    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
#else
    private let configuration: AppConfiguration
    private let dependencies: RecapDependencies

    init() {
        let configuration = AppConfiguration.live()
        self.configuration = configuration


        switch configuration.runtimeProfile {
        #if DEBUG
        case .mock:
            dependencies = RecapDependencies.simulatorMock()
        #endif
        case .live:
            // 키가 없으면 SDK가 초기화되지 않고, 로그인 시 SDK 내부 `try!`가 크래시를 낸다.
            // Debug 빌드에서 즉시 드러나게 하고 릴리스에서는 로그인 실패로 처리된다.
            let didInitializeKakaoSDK = KakaoSDKBootstrap.initialize(configuration: configuration)
            assert(didInitializeKakaoSDK, "KAKAO_NATIVE_APP_KEY가 비어 카카오 SDK를 초기화하지 못했다. Config/Secrets.xcconfig를 확인할 것.")
            dependencies = RecapDependencies.live(configuration: configuration)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(dependencies: dependencies)
                .onOpenURL { url in
                    guard configuration.runtimeProfile == .live else { return }
                    _ = KakaoSDKBootstrap.handleOpenURL(url)
                }
        }
    }
#endif
}
