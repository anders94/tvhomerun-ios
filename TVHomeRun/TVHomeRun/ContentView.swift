//
//  ContentView.swift
//  TVHomeRun
//
//  Root content view that handles navigation based on setup state
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var showSettings = true
    @State private var isCheckingConnectivity = true

    var body: some View {
        Group {
            if isCheckingConnectivity {
                // Checking connectivity
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Connecting...")
                        .font(.title2)
                }
            } else if showSettings {
                ServerSetupView(userSettings: userSettings, onSettingsSaved: {
                    showSettings = false
                })
            } else {
                NavigationStack {
                    ShowsListView(apiClient: APIClient(baseURL: userSettings.serverURL))
                }
            }
        }
        .task {
            await checkInitialConnectivity()
        }
    }

    private func checkInitialConnectivity() async {
        // If no URL is set, show settings
        guard !userSettings.serverURL.isEmpty else {
            await MainActor.run {
                showSettings = true
                isCheckingConnectivity = false
            }
            return
        }

        // Try to connect to the server
        let apiClient = APIClient(baseURL: userSettings.serverURL)
        do {
            let health = try await apiClient.checkHealth()
            await MainActor.run {
                if health.isHealthy {
                    // Connection works, go to shows
                    showSettings = false
                } else {
                    // Server not healthy, show settings
                    showSettings = true
                }
                isCheckingConnectivity = false
            }
        } catch {
            // Connection failed, show settings
            await MainActor.run {
                showSettings = true
                isCheckingConnectivity = false
            }
        }
    }
}
