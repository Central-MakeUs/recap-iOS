//
//  ContentView.swift
//  Recap
//
//  Created by oliver on 6/29/26.
//

import SwiftUI

struct ContentView: View {
    private let dependencies: RecapDependencies

    init(dependencies: RecapDependencies) {
        self.dependencies = dependencies
    }

    var body: some View {
        RecapRootView(dependencies: dependencies)
    }
}

#Preview {
    ContentView(
        dependencies: .preview(
            sessionState: .signedOut(nil),
            onboardingProgress: .notStarted
        )
    )
}
