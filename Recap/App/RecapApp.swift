//
//  RecapApp.swift
//  Recap
//
//  Created by oliver on 6/29/26.
//

import SwiftUI

@main
struct RecapApp: App {
    private let dependencies: RecapDependencies

    init() {
        let configuration = AppConfiguration.live()
        RecapFont.registerFonts()
        KakaoSDKBootstrap.initialize(configuration: configuration)
        dependencies = RecapDependencies.live(configuration: configuration)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(dependencies: dependencies)
                .onOpenURL { url in
                    _ = KakaoSDKBootstrap.handleOpenURL(url)
                }
        }
    }
}
