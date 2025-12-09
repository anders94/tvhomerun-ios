//
//  ShowsListView.swift
//  TVHomeRun
//
//  View displaying the list of available shows
//

import SwiftUI

enum ContentTab: String, CaseIterable {
    case recordings = "Recorded"
    case live = "Live"
}

struct ShowsListView: View {
    @ObservedObject var apiClient: APIClient
    @EnvironmentObject var userSettings: UserSettings
    @State private var shows: [Show] = []
    @State private var isLoading = true
    @State private var selectedShow: Show?
    @State private var showServerSettings = false
    @State private var showGuide = false
    @State private var selectedTab: ContentTab = .recordings

    var body: some View {
        ZStack {
            if selectedTab == .recordings {
                // Recordings view
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading shows...")
                            .font(.title2)
                    }
                } else if shows.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tv.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No shows available")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(shows) { show in
                                Button(action: {
                                    selectedShow = show
                                }) {
                                    ShowCardView(show: show)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                    }
                }
            } else {
                // Live TV view
                LiveChannelsView(apiClient: apiClient)
            }
        }
        .navigationTitle("TVHomeRun")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showGuide = true
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
            ToolbarItem(placement: .principal) {
                Picker("Content Type", selection: $selectedTab) {
                    ForEach(ContentTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 220)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showServerSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .navigationDestination(item: $selectedShow) { show in
            EpisodesListView(apiClient: apiClient, show: show)
        }
        .sheet(isPresented: $showServerSettings) {
            ServerSetupView(userSettings: userSettings, onSettingsSaved: {
                showServerSettings = false
            })
        }
        .sheet(isPresented: $showGuide) {
            GuideView(apiClient: apiClient)
        }
        .alert("Connection Error", isPresented: $apiClient.showErrorAlert) {
            Button("OK") {
                apiClient.clearError()
            }
            Button("Retry") {
                Task {
                    await loadShows()
                }
            }
        } message: {
            if let error = apiClient.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            await loadShows()
        }
    }

    private func loadShows() async {
        isLoading = true
        do {
            let fetchedShows = try await apiClient.fetchShows()
            await MainActor.run {
                shows = fetchedShows
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct ShowCardView: View {
    let show: Show

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Show image
            AsyncImage(url: URL(string: show.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "tv")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                @unknown default:
                    Color.gray.opacity(0.3)
                        .aspectRatio(16/9, contentMode: .fit)
                }
            }
            .aspectRatio(16/9, contentMode: .fit)
            .clipped()
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                Text(show.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                HStack(spacing: 3) {
                    Text(show.category.capitalized)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    if show.episodeCount > 0 {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("\(show.episodeCount) ep")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}
