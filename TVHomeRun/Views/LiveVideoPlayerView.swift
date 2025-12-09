//
//  LiveVideoPlayerView.swift
//  TVHomeRun
//
//  Video player for live TV streaming
//

import SwiftUI
import AVKit

struct LiveVideoPlayerView: View {
    @Environment(\.dismiss) var dismiss
    let channel: Channel
    let apiClient: APIClient

    @StateObject private var playerViewModel: LiveVideoPlayerViewModel

    init(channel: Channel, apiClient: APIClient) {
        self.channel = channel
        self.apiClient = apiClient
        _playerViewModel = StateObject(wrappedValue: LiveVideoPlayerViewModel(channel: channel, apiClient: apiClient))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Use native AVPlayerViewController with built-in controls - EXACTLY like recorded shows
            NativeVideoPlayer(player: playerViewModel.player)
                .ignoresSafeArea()
                .onAppear {
                    playerViewModel.setup()
                }
                .onDisappear {
                    playerViewModel.close()
                }

            // Error message - EXACTLY like recorded shows
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
