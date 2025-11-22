//
//  Show.swift
//  TVHomeRun
//
//  Data model for TV shows
//

import Foundation

struct ShowsResponse: Codable {
    let shows: [Show]
    let count: Int
}

struct Show: Codable, Identifiable, Hashable {
    let id: Int
    let seriesId: String
    let title: String
    let category: String
    let imageUrl: String?
    let episodeCount: Int
    let totalDuration: Int
    let firstRecorded: String?
    let lastRecorded: String?
    let createdAt: String
    let updatedAt: String
    let deviceName: String
    let deviceIp: String
    let durationHours: Int

    enum CodingKeys: String, CodingKey {
        case id
        case seriesId = "series_id"
        case title
        case category
        case imageUrl = "image_url"
        case episodeCount = "episode_count"
        case totalDuration = "total_duration"
        case firstRecorded = "first_recorded"
        case lastRecorded = "last_recorded"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deviceName = "device_name"
        case deviceIp = "device_ip"
        case durationHours = "duration_hours"
    }
}
