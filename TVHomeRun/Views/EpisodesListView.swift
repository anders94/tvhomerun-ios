//
//  EpisodesListView.swift
//  TVHomeRun
//
//  View displaying the list of episodes for a show
//

import SwiftUI

struct EpisodesListView: View {
    @ObservedObject var apiClient: APIClient
    let show: Show
    @State private var episodes: [Episode] = []
    @State private var isLoading = true
    @State private var selectedEpisode: Episode?

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading episodes...")
                        .font(.title2)
                }
            } else if episodes.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No episodes available")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(episodes) { episode in
                            Button(action: {
                                selectedEpisode = episode
                            }) {
                                EpisodeRowView(episode: episode)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(show.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedEpisode) { episode in
            VideoPlayerView(episode: episode, allEpisodes: episodes, apiClient: apiClient)
        }
        .alert("Connection Error", isPresented: $apiClient.showErrorAlert) {
            Button("OK") {
                apiClient.clearError()
            }
            Button("Retry") {
                Task {
                    await loadEpisodes()
                }
            }
        } message: {
            if let error = apiClient.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            await loadEpisodes()
        }
        .onChange(of: selectedEpisode) { oldValue, newValue in
            // When returning from video player (newValue becomes nil)
            if oldValue != nil && newValue == nil {
                Task {
                    await refreshWatchedEpisode()
                }
            }
        }
    }

    private func loadEpisodes() async {
        isLoading = true
        do {
            let response = try await apiClient.fetchEpisodes(for: show.id)
            await MainActor.run {
                // Episodes are already in newest-first order from the API
                episodes = response.episodes
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func refreshWatchedEpisode() async {
        do {
            let response = try await apiClient.fetchEpisodes(for: show.id)
            await MainActor.run {
                // If episode count changed, we have new episodes - repaint entire list
                if response.episodes.count != episodes.count {
                    episodes = response.episodes
                } else {
                    // Update all episodes in place to avoid redraw flicker
                    for updatedEpisode in response.episodes {
                        if let index = episodes.firstIndex(where: { $0.id == updatedEpisode.id }) {
                            episodes[index] = updatedEpisode
                        }
                    }
                }
            }
        } catch {
            // Silently fail - not critical if refresh fails
            print("Failed to refresh episodes: \(error)")
        }
    }
}

struct EpisodeRowView: View {
    let episode: Episode

    var body: some View {
        HStack(spacing: 15) {
            // Episode thumbnail
            AsyncImage(url: URL(string: episode.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                    .frame(width: 140, height: 90)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 90)
                        .clipped()
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 140, height: 90)
                @unknown default:
                    Color.gray.opacity(0.3)
                        .frame(width: 140, height: 90)
                }
            }
            .cornerRadius(8)
            .overlay(
                ZStack {
                    // Progress indicator overlay
                    if episode.progressPercentage > 0 {
                        VStack {
                            Spacer()
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.red)
                                    .frame(width: geometry.size.width * episode.progressPercentage,
                                           height: 4)
                            }
                            .frame(height: 4)
                        }
                    }

                    // Watched indicator
                    if episode.isWatched {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }

                    // Resume indicator
                    if let resumePos = episode.resumePosition, resumePos > 0, !episode.isWatched {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }
                }
            )

            // Episode info
            VStack(alignment: .leading, spacing: 6) {
                // Episode number and title
                Text(episode.episodeNumber)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)

                Text(episode.episodeTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                // Synopsis
                Text(episode.synopsis)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer()

                // Metadata
                HStack(spacing: 8) {
                    Label(episode.formattedAirDate, systemImage: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Label(episode.formattedDuration, systemImage: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if let resumePos = episode.resumePosition, resumePos > 0 {
                        Label("\(episode.resumeMinutes)m", systemImage: "eye")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
