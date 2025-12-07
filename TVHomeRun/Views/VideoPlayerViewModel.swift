//
//  VideoPlayerViewModel.swift
//  TVHomeRun
//
//  ViewModel for managing video playback state and controls
//

import Foundation
import AVKit
import AVFoundation
import Combine

class VideoPlayerViewModel: ObservableObject {
    @MainActor @Published var player: AVPlayer = AVPlayer()
    @MainActor @Published var isPlaying = false
    @MainActor @Published var isLoading = true
    @MainActor @Published var showControls = true
    @MainActor @Published var progress: Double = 0
    @MainActor @Published var currentTimeString = "0:00"
    @MainActor @Published var durationString = "0:00"
    @MainActor @Published var errorMessage: String?

    @MainActor @Published var currentEpisode: Episode
    private let allEpisodes: [Episode]
    private let apiClient: APIClient

    private var timeObserver: Any?
    private var controlsTimer: Timer?
    private var statusObserver: AnyCancellable?
    private var endObserver: AnyCancellable?
    private var progressSaveObserver: Any?
    private var lastSavedPosition: Int = 0
    private var hasSetup = false

    var hasNextEpisode: Bool {
        guard let currentIndex = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }) else {
            return false
        }
        return currentIndex < allEpisodes.count - 1
    }

    var hasPreviousEpisode: Bool {
        guard let currentIndex = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }) else {
            return false
        }
        return currentIndex > 0
    }

    init(episode: Episode, allEpisodes: [Episode], apiClient: APIClient) {
        self.currentEpisode = episode
        self.allEpisodes = allEpisodes
        self.apiClient = apiClient

        print("VideoPlayerViewModel init with episode: \(episode.episodeNumber)")
    }

    @MainActor
    func setup() {
        guard !hasSetup else {
            print("Setup already called, skipping")
            return
        }
        hasSetup = true
        print("Setting up player for the first time")
        configureAudioSession()
        setupPlayer(with: currentEpisode)
        setupControlsTimer()
    }

    @MainActor
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            try audioSession.setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
            errorMessage = "Audio configuration failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func setupPlayer(with episode: Episode) {
        print("setupPlayer called for: \(episode.episodeNumber)")
        isLoading = true
        errorMessage = nil

        // Clean up old observers (if any)
        if timeObserver != nil || statusObserver != nil || endObserver != nil {
            cleanup()
        }

        print("Attempting to play URL: \(episode.playUrl)")

        guard let url = URL(string: episode.playUrl) else {
            errorMessage = "Invalid video URL: \(episode.playUrl)"
            isLoading = false
            return
        }

        print("Valid URL created: \(url)")

        // Create player item
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        // Set up time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateProgress()
            }
        }

        // Set up periodic progress save observer (every 30 seconds)
        let saveInterval = CMTime(seconds: 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        progressSaveObserver = player.addPeriodicTimeObserver(forInterval: saveInterval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            Task { @MainActor in
                await self.saveProgressToServer()
            }
        }

        // Observe player item status
        statusObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                print("Player status changed to: \(status.rawValue)")

                switch status {
                case .readyToPlay:
                    print("Player ready to play")
                    self.isLoading = false

                    // Resume from saved position if available
                    if let resumePos = episode.resumePosition, resumePos > 0 {
                        let seekTime = CMTime(seconds: Double(resumePos), preferredTimescale: 1)
                        self.player.seek(to: seekTime) { _ in
                            Task { @MainActor in
                                self.player.play()
                                self.isPlaying = true
                            }
                        }
                        print("Resuming from position: \(resumePos) seconds")
                    } else {
                        self.player.play()
                        self.isPlaying = true
                    }
                case .failed:
                    print("Player failed")
                    if let error = playerItem.error {
                        print("Error: \(error.localizedDescription)")
                        self.errorMessage = "Failed to load video: \(error.localizedDescription)"
                    } else {
                        self.errorMessage = "Failed to load video"
                    }
                    self.isLoading = false
                default:
                    print("Player status unknown")
                    break
                }
            }

        // Observe playback end
        endObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }

                // Mark as watched when playback ends
                Task {
                    await self.markAsWatched()

                    // Auto-play next episode if available
                    if self.hasNextEpisode {
                        await MainActor.run {
                            self.playNextEpisode()
                        }
                    }
                }
            }
    }

    @MainActor
    private func updateProgress() {
        let currentTime = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0

        if duration.isFinite && duration > 0 {
            progress = currentTime / duration
            currentTimeString = formatTime(currentTime)
            durationString = formatTime(duration)
        }
    }

    private func formatTime(_ timeInSeconds: Double) -> String {
        guard timeInSeconds.isFinite else { return "0:00" }
        let totalSeconds = Int(timeInSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func saveProgressToServer() async {
        let currentTime = Int(player.currentTime().seconds)

        // Don't save if position hasn't changed significantly (at least 5 seconds)
        guard currentTime > 0 && abs(currentTime - lastSavedPosition) >= 5 else {
            return
        }

        // Don't save if we're near the end (within last 30 seconds)
        let duration = player.currentItem?.duration.seconds ?? 0
        guard duration.isFinite && currentTime < Int(duration) - 30 else {
            return
        }

        print("Saving progress: \(currentTime) seconds for episode \(currentEpisode.id)")

        do {
            try await apiClient.updateEpisodeProgress(
                episodeId: currentEpisode.id,
                position: currentTime,
                watched: false
            )
            lastSavedPosition = currentTime
        } catch {
            print("Failed to save progress: \(error)")
            // Don't block playback on network errors
        }
    }

    private func markAsWatched() async {
        print("Marking episode \(currentEpisode.id) as watched")

        let duration = Int(player.currentItem?.duration.seconds ?? 0)

        do {
            try await apiClient.updateEpisodeProgress(
                episodeId: currentEpisode.id,
                position: duration,
                watched: true
            )
        } catch {
            print("Failed to mark as watched: \(error)")
        }
    }

    @MainActor
    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        resetControlsTimer()
    }

    @MainActor
    func skipForward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 30, preferredTimescale: 1))
        player.seek(to: newTime)
        resetControlsTimer()
    }

    @MainActor
    func skipBackward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        player.seek(to: newTime)
        resetControlsTimer()
    }

    @MainActor
    func playNextEpisode() {
        guard let currentIndex = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }),
              currentIndex < allEpisodes.count - 1 else {
            return
        }

        let nextEpisode = allEpisodes[currentIndex + 1]
        currentEpisode = nextEpisode
        setupPlayer(with: nextEpisode)
        resetControlsTimer()
    }

    @MainActor
    func playPreviousEpisode() {
        guard let currentIndex = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }),
              currentIndex > 0 else {
            return
        }

        let previousEpisode = allEpisodes[currentIndex - 1]
        currentEpisode = previousEpisode
        setupPlayer(with: previousEpisode)
        resetControlsTimer()
    }

    @MainActor
    func toggleControls() {
        showControls.toggle()
        if showControls {
            resetControlsTimer()
        } else {
            controlsTimer?.invalidate()
        }
    }

    @MainActor
    private func setupControlsTimer() {
        resetControlsTimer()
    }

    @MainActor
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                if self.isPlaying {
                    self.showControls = false
                }
            }
        }
    }

    @MainActor
    private func cleanup() {
        print("Cleaning up observers")
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let progressSaveObserver = progressSaveObserver {
            player.removeTimeObserver(progressSaveObserver)
            self.progressSaveObserver = nil
        }
        statusObserver?.cancel()
        statusObserver = nil
        endObserver?.cancel()
        endObserver = nil
    }

    @MainActor
    func close() {
        print("Closing player")

        // Save progress before closing
        Task {
            await saveProgressToServer()
        }

        player.pause()
        cleanup()
        controlsTimer?.invalidate()

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("Audio session deactivated")
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}
