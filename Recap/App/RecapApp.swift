//
//  RecapApp.swift
//  Recap
//
//  Created by oliver on 6/29/26.
//

import SwiftUI

@main
struct RecapApp: App {
    private let configuration: AppConfiguration
    private let dependencies: RecapDependencies

    init() {
        let configuration = AppConfiguration.live()
        self.configuration = configuration

        RecapFont.registerFonts()

        switch configuration.runtimeProfile {
        case .mock:
            dependencies = RecapDependencies.simulatorMock()
        case .live:
            KakaoSDKBootstrap.initialize(configuration: configuration)
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
}
