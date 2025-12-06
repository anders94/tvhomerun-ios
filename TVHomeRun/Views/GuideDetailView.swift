//
//  GuideDetailView.swift
//  TVHomeRun
//
//  Detail view for upcoming episodes of a series with recording toggle
//

import SwiftUI

struct GuideDetailView: View {
    let series: GuideSeries
    @ObservedObject var apiClient: APIClient
    @State private var isRecordingEnabled = false

    var body: some View {
        List {
            // Recording toggle section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Record This Series")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Automatically record new episodes")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $isRecordingEnabled)
                        .labelsHidden()
                }
            }

            // Upcoming episodes section
            Section {
                ForEach(series.programs.sorted(by: { $0.startTime < $1.startTime })) { program in
                    GuideProgramRow(program: program)
                }
            } header: {
                Text("Upcoming Episodes")
            }
        }
        .navigationTitle(series.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: isRecordingEnabled) { _, newValue in
            Task {
                await toggleRecording(enabled: newValue)
            }
        }
    }

    private func toggleRecording(enabled: Bool) async {
        // TODO: Implement recording rule API calls when backend documentation is available
        // For now, this is a placeholder that acknowledges the user's action
        print("Recording \(enabled ? "enabled" : "disabled") for series: \(series.title)")
    }
}

struct GuideProgramRow: View {
    let program: GuideProgram

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let episodeTitle = program.episodeTitle, !episodeTitle.isEmpty {
                        Text(episodeTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    if let episodeNumber = program.episodeNumber, !episodeNumber.isEmpty {
                        Text(episodeNumber)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }

                    Text(program.formattedStartTime)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text("\(program.durationMinutes) minutes")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Program image
                if let imageUrl = program.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Color.gray.opacity(0.3)
                                ProgressView()
                            }
                            .frame(width: 60, height: 90)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 90)
                                .clipped()
                        case .failure:
                            ZStack {
                                Color.gray.opacity(0.3)
                                Image(systemName: "tv")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 60, height: 90)
                        @unknown default:
                            Color.gray.opacity(0.3)
                                .frame(width: 60, height: 90)
                        }
                    }
                    .cornerRadius(6)
                }
            }

            if let synopsis = program.synopsis, !synopsis.isEmpty {
                Text(synopsis)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}
