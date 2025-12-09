//
//  LiveChannelsView.swift
//  TVHomeRun
//
//  View for displaying live TV channels and current programs
//

import SwiftUI

struct LiveChannelsView: View {
    let apiClient: APIClient
    @State private var channels: [Channel] = []
    @State private var currentPrograms: [String: CurrentProgram] = [:]
    @State private var isLoading = true
    @State private var selectedChannel: Channel?
    @State private var showPlayer = false

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading channels...")
                        .font(.title2)
                }
            } else if channels.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tv")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No channels available")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            } else {
                List(channels) { channel in
                    Button {
                        selectedChannel = channel
                        showPlayer = true
                    } label: {
                        ChannelRow(
                            channel: channel,
                            currentProgram: currentPrograms[channel.guideNumber]
                        )
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .task {
            await loadChannels()
        }
        .refreshable {
            await loadChannels()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let channel = selectedChannel {
                LiveVideoPlayerView(
                    channel: channel,
                    apiClient: apiClient
                )
            }
        }
    }

    private func loadChannels() async {
        isLoading = true
        do {
            // Load channels and current programs in parallel
            async let channelsResponse = apiClient.fetchLiveChannels()
            async let programsResponse = apiClient.fetchCurrentPrograms()

            let (channels, programs) = try await (channelsResponse, programsResponse)

            await MainActor.run {
                self.channels = channels.channels.sorted { $0.guideNumber < $1.guideNumber }

                // Build dictionary for quick lookup
                var programsDict: [String: CurrentProgram] = [:]
                for program in programs.programs {
                    programsDict[program.guideNumber] = program
                }
                self.currentPrograms = programsDict

                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct ChannelRow: View {
    let channel: Channel
    let currentProgram: CurrentProgram?

    var body: some View {
        HStack(spacing: 15) {
            // Channel logo with tile background
            ZStack {
                // Background tile
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.85))

                AsyncImage(url: URL(string: channel.imageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    case .failure:
                        Image(systemName: "tv")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "tv")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                // Channel info
                HStack(spacing: 8) {
                    Text(channel.guideNumber)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text(channel.guideName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    if let affiliate = channel.affiliate {
                        Text(affiliate)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                // Current program
                if let program = currentProgram {
                    Text(program.title)
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                        .lineLimit(1)

                    if let episodeTitle = program.episodeTitle {
                        Text(episodeTitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Text(program.formattedTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("No program information")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
