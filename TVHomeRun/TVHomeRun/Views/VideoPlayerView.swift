//
//  VideoPlayerView.swift
//  TVHomeRun
//
//  Custom video player with playback controls
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Environment(\.dismiss) var dismiss
    let episode: Episode
    let allEpisodes: [Episode]
    let apiClient: APIClient

    @StateObject private var playerViewModel: VideoPlayerViewModel

    init(episode: Episode, allEpisodes: [Episode], apiClient: APIClient) {
        self.episode = episode
        self.allEpisodes = allEpisodes
        self.apiClient = apiClient
        _playerViewModel = StateObject(wrappedValue: VideoPlayerViewModel(episode: episode, allEpisodes: allEpisodes, apiClient: apiClient))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Use native AVPlayerViewController with built-in controls
            NativeVideoPlayer(player: playerViewModel.player)
                .ignoresSafeArea()
                .onAppear {
                    playerViewModel.setup()
                }
                .onDisappear {
                    playerViewModel.close()
                }

            // Error message
            if let error = playerViewModel.errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
}

// Native AVPlayer wrapper with built-in controls
struct NativeVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Only update if player instance changed
        if uiViewController.player !== player {
            uiViewController.player = player
        }
    }
}
