//
//  UserSettings.swift
//  TVHomeRun
//
//  UserDefaults wrapper for persisting app settings
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    private enum Keys {
        static let serverURL = "serverURL"
        static let hasCompletedSetup = "hasCompletedSetup"
    }

    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: Keys.serverURL)
        }
    }

    @Published var hasCompletedSetup: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedSetup, forKey: Keys.hasCompletedSetup)
        }
    }

    init() {
        self.serverURL = UserDefaults.standard.string(forKey: Keys.serverURL) ?? ""
        self.hasCompletedSetup = UserDefaults.standard.bool(forKey: Keys.hasCompletedSetup)
    }

    func saveServerURL(_ url: String) {
        self.serverURL = url
        self.hasCompletedSetup = true
    }

    func reset() {
        serverURL = ""
        hasCompletedSetup = false
    }
}
