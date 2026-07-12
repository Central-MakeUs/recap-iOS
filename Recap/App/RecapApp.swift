//
//  RecapApp.swift
//  Recap
//
//  Created by oliver on 6/29/26.
//

import SwiftUI

@main
struct RecapApp: App {
    init() {
        RecapFont.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
