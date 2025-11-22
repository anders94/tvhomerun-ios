//
//  ServerSetupView.swift
//  TVHomeRun
//
//  View for configuring the server URL
//

import SwiftUI

struct ServerSetupView: View {
    @EnvironmentObject var userSettings: UserSettings
    @StateObject private var apiClient: APIClient
    @State private var urlInput: String
    @State private var isValidating = false
    @State private var validationError: String?
    var onSettingsSaved: (() -> Void)? = nil

    init(userSettings: UserSettings, onSettingsSaved: (() -> Void)? = nil) {
        _urlInput = State(initialValue: userSettings.serverURL.isEmpty ? "http://" : userSettings.serverURL)
        _apiClient = StateObject(wrappedValue: APIClient(baseURL: userSettings.serverURL))
        self.onSettingsSaved = onSettingsSaved
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 15) {
                        Image(systemName: "play.tv.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("TV HomeRun")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Stream your recorded content")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                Section {
                    TextField("Server URL", text: $urlInput)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Server Configuration")
                } footer: {
                    if let error = validationError {
                        Text(error)
                            .foregroundColor(.red)
                    } else {
                        Text("Enter the URL of your TV HomeRun server (e.g., http://192.168.1.100:3000)")
                    }
                }

                Section {
                    Button(action: validateAndConnect) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                Text("Connecting...")
                            } else {
                                Text("Connect to Server")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isValidating || urlInput.isEmpty)
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    private func validateAndConnect() {
        validationError = nil
        isValidating = true

        // Clean up URL
        var cleanURL = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURL.hasPrefix("http://") && !cleanURL.hasPrefix("https://") {
            cleanURL = "http://" + cleanURL
        }
        // Remove trailing slash
        if cleanURL.hasSuffix("/") {
            cleanURL = String(cleanURL.dropLast())
        }

        apiClient.updateBaseURL(cleanURL)

        Task {
            do {
                let health = try await apiClient.checkHealth()
                if health.isHealthy {
                    await MainActor.run {
                        userSettings.saveServerURL(cleanURL)
                        isValidating = false
                        onSettingsSaved?()
                    }
                } else {
                    await MainActor.run {
                        validationError = "Server is not healthy: \(health.status)"
                        isValidating = false
                    }
                }
            } catch {
                await MainActor.run {
                    validationError = "Unable to connect: \(error.localizedDescription)"
                    isValidating = false
                }
            }
        }
    }
}
