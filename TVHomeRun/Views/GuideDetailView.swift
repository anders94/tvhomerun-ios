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
    let isRecording: Bool
    @State private var isRecordingEnabled = false
    @State private var currentRecordingRule: RecordingRule?
    @State private var isLoadingRules = true
    @State private var isUpdating = false

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
        .task {
            // Set initial state immediately based on passed parameter
            isRecordingEnabled = isRecording
            isLoadingRules = false
            // Load recording rule in background to get the rule ID
            await loadRecordingStatus()
        }
        .onChange(of: isRecordingEnabled) { oldValue, newValue in
            // Only act on user changes, not initial load
            if !isLoadingRules && oldValue != newValue {
                Task {
                    await toggleRecording(enabled: newValue)
                }
            }
        }
        .disabled(isUpdating)
    }

    private func loadRecordingStatus() async {
        do {
            let response = try await apiClient.fetchRecordingRules()
            await MainActor.run {
                // Store the recording rule (we need the ID for deletion)
                currentRecordingRule = response.rules.first { $0.seriesId == series.id }
            }
        } catch {
            // Silently fail - user can still toggle to create rule
        }
    }

    private func toggleRecording(enabled: Bool) async {
        isUpdating = true
        do {
            if enabled {
                // Create new recording rule
                let response = try await apiClient.createRecordingRule(seriesId: series.id)
                await MainActor.run {
                    if let rule = response.recordingRule {
                        currentRecordingRule = rule
                    }
                    isUpdating = false
                }
            } else {
                // Delete existing recording rule
                if let ruleId = currentRecordingRule?.id {
                    try await apiClient.deleteRecordingRule(ruleId: ruleId)
                    await MainActor.run {
                        currentRecordingRule = nil
                        isUpdating = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                // Revert toggle on error
                isRecordingEnabled = !enabled
                currentRecordingRule = enabled ? nil : currentRecordingRule
                isUpdating = false
            }
            // Error is already handled by APIClient's error alert
        }
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
