//
//  LiveVideoPlayerViewModel.swift
//  TVHomeRun
//
//  ViewModel for managing live TV streaming
//

import Foundation
import AVKit
import AVFoundation
import Combine

class LiveVideoPlayerViewModel: ObservableObject {
    @MainActor @Published var player: AVPlayer = AVPlayer()
    @MainActor @Published var isLoading = true
    @MainActor @Published var errorMessage: String?

    @MainActor @Published var channel: Channel

    private let apiClient: APIClient
    private let clientId: String
    private var heartbeatTimer: Timer?
    private var statusObserver: AnyCancellable?
    private var hasSetup = false

    init(channel: Channel, apiClient: APIClient) {
        self.channel = channel
        self.apiClient = apiClient
        // Generate unique client ID
        self.clientId = UUID().uuidString
    }

    @MainActor
    func setup() {
        guard !hasSetup else {
            return
        }
        hasSetup = true
        configureAudioSession()
        startStream()
    }

    @MainActor
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            try audioSession.setActive(true)
        } catch {
            errorMessage = "Audio configuration failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func startStream() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Call API to start watching
                let response = try await apiClient.startWatching(
                    channelNumber: channel.guideNumber,
                    clientId: clientId
                )

                // Check for error in response
                if let error = response.error {
                    await MainActor.run {
                        self.errorMessage = error
                        self.isLoading = false
                    }
                    return
                }

                if !response.success {
                    await MainActor.run {
                        self.errorMessage = response.message ?? "Failed to start stream"
                        self.isLoading = false
                    }
                    return
                }

                // Construct full URL - MUST be absolute for AVPlayer
                guard let baseURL = URL(string: apiClient.baseURL) else {
                    await MainActor.run {
                        self.errorMessage = "Invalid server URL"
                        self.isLoading = false
                    }
                    return
                }

                guard let playlistURL = URL(string: response.playlistUrl, relativeTo: baseURL)?.absoluteURL else {
                    await MainActor.run {
                        self.errorMessage = "Invalid stream URL"
                        self.isLoading = false
                    }
                    return
                }

                // Stream is ready - backend waits for it before responding
                await setupPlayerWithItem(url: playlistURL)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to start stream: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    @MainActor
    private func setupPlayerWithItem(url: URL) {
        // Create player item - simplest possible approach
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        // Observe player item status - same as recorded shows
        statusObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }

                switch status {
                case .readyToPlay:
                    self.isLoading = false
                    self.player.play()

                    // Delay heartbeat start to ensure player is stable
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                        self.startHeartbeat()
                    }
                case .failed:
                    if let error = playerItem.error {
                        self.errorMessage = "Failed to load stream: \(error.localizedDescription)"
                    } else {
                        self.errorMessage = "Failed to load live stream"
                    }
                    self.isLoading = false
                default:
                    break
                }
            }
    }

    @MainActor
    private func startHeartbeat() {
        // Don't create multiple timers
        guard heartbeatTimer == nil else {
            return
        }

        // Send heartbeat every 25 seconds
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.sendHeartbeat()
            }
        }
    }

    private func sendHeartbeat() async {
        do {
            _ = try await apiClient.sendHeartbeat(clientId: clientId)
        } catch APIError.serverError(404) {
            // 404 is expected if we just closed - client was already removed
        } catch {
            // Don't show error to user - heartbeat failures are not critical
        }
    }

    @MainActor
    func close() {
        player.pause()

        // Cancel heartbeat timer
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        // Cancel observers
        statusObserver?.cancel()
        statusObserver = nil

        // Notify server we're stopping
        Task {
            do {
                _ = try await apiClient.stopWatching(clientId: clientId)
            } catch {
                // Ignore errors during cleanup
            }
        }

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore errors during cleanup
        }
    }
}
