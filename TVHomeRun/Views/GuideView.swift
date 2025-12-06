//
//  GuideView.swift
//  TVHomeRun
//
//  View for browsing and searching upcoming TV programs
//

import SwiftUI

struct GuideView: View {
    @ObservedObject var apiClient: APIClient
    @State private var guideSeries: [GuideSeries] = []
    @State private var filteredSeries: [GuideSeries] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var recordedSeriesIds: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading guide...")
                            .font(.title2)
                    }
                } else if filteredSeries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: searchText.isEmpty ? "tv" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "No upcoming programs" : "No results found")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(filteredSeries) { series in
                            NavigationLink(value: series) {
                                GuideSeriesRow(
                                    series: series,
                                    isRecording: recordedSeriesIds.contains(series.id)
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Program Guide")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search shows")
            .onChange(of: searchText) { _, newValue in
                filterSeries(query: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .navigationDestination(for: GuideSeries.self) { series in
                GuideDetailView(
                    series: series,
                    apiClient: apiClient,
                    isRecording: recordedSeriesIds.contains(series.id)
                )
            }
            .task {
                await loadGuide()
            }
        }
    }

    private func loadGuide(forceRefresh: Bool = false) async {
        isLoading = true
        do {
            // Load guide and recording rules in parallel
            async let guideResponse = apiClient.fetchGuide(forceRefresh: forceRefresh)
            async let recordingRulesResponse = apiClient.fetchRecordingRules()

            let (guide, rules) = try await (guideResponse, recordingRulesResponse)

            await MainActor.run {
                // Store recorded series IDs
                recordedSeriesIds = Set(rules.rules.map { $0.seriesId })

                // Group programs by series
                var seriesDict: [String: GuideSeries] = [:]
                for channel in guide.channels {
                    for program in channel.guide {
                        // Create a new program instance with channel ID
                        var programWithChannel = program
                        programWithChannel.channelId = channel.guideNumber

                        if var existingSeries = seriesDict[program.seriesId] {
                            existingSeries = GuideSeries(
                                id: existingSeries.id,
                                title: existingSeries.title,
                                imageUrl: existingSeries.imageUrl,
                                programs: existingSeries.programs + [programWithChannel]
                            )
                            seriesDict[program.seriesId] = existingSeries
                        } else {
                            seriesDict[program.seriesId] = GuideSeries(
                                id: program.seriesId,
                                title: program.title,
                                imageUrl: program.imageUrl,
                                programs: [programWithChannel]
                            )
                        }
                    }
                }

                guideSeries = seriesDict.values.sorted { $0.title < $1.title }
                filterSeries(query: searchText)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func filterSeries(query: String) {
        if query.isEmpty {
            filteredSeries = guideSeries
        } else {
            filteredSeries = guideSeries.filter {
                $0.title.localizedCaseInsensitiveContains(query)
            }
        }
    }
}

struct GuideSeriesRow: View {
    let series: GuideSeries
    let isRecording: Bool

    var body: some View {
        HStack(spacing: 15) {
            // Series image with recording indicator
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: series.imageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                        }
                        .frame(width: 80, height: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .clipped()
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "tv")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 80, height: 120)
                    @unknown default:
                        Color.gray.opacity(0.3)
                            .frame(width: 80, height: 120)
                    }
                }
                .frame(width: 80, height: 120)
                .cornerRadius(8)

                // Red recording indicator dot
                if isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 4, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(series.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("\(series.upcomingCount) upcoming \(series.upcomingCount == 1 ? "episode" : "episodes")")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                if let firstProgram = series.programs.first {
                    Text("Next: \(firstProgram.formattedStartTime)")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
