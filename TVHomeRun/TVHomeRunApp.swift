//
//  TVHomeRunApp.swift
//  TVHomeRun
//
//  Created by Anders Brownworth on 11/22/25.
//

import SwiftUI

@main
struct TVHomeRunApp: App {
    @StateObject private var userSettings = UserSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
        }
    }
}
