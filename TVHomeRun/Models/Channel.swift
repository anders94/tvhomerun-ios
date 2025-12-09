//
//  Channel.swift
//  TVHomeRun
//
//  Data models for Live TV channels and streaming
//

import Foundation

// Response from /api/live/channels
struct ChannelsResponse: Codable {
    let channels: [Channel]
    let count: Int
    let timestamp: String
}

struct Channel: Codable, Identifiable {
    let guideNumber: String
    let guideName: String
    let affiliate: String?
    let imageUrl: String?

    var id: String { guideNumber }

    enum CodingKeys: String, CodingKey {
        case guideNumber = "guide_number"
        case guideName = "guide_name"
        case affiliate
        case imageUrl = "image_url"
    }
}

// Response from /api/guide/now
struct CurrentProgramsResponse: Codable {
    let programs: [CurrentProgram]
    let count: Int
    let timestamp: String
}

struct CurrentProgram: Codable {
    let guideNumber: String
    let guideName: String
    let affiliate: String?
    let seriesId: String
    let title: String
    let episodeNumber: String?
    let episodeTitle: String?
    let startTime: Int
    let endTime: Int
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case guideNumber = "guide_number"
        case guideName = "guide_name"
        case affiliate
        case seriesId = "series_id"
        case title
        case episodeNumber = "episode_number"
        case episodeTitle = "episode_title"
        case startTime = "start_time"
        case endTime = "end_time"
        case imageUrl = "image_url"
    }

    var formattedTime: String {
        let start = Date(timeIntervalSince1970: TimeInterval(startTime))
        let end = Date(timeIntervalSince1970: TimeInterval(endTime))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        let ampm = DateFormatter()
        ampm.dateFormat = "a"
        return "\(formatter.string(from: start))-\(formatter.string(from: end)) \(ampm.string(from: end))"
    }
}

// Response from /api/live/watch
struct WatchResponse: Codable {
    let success: Bool
    let tunerId: String
    let playlistUrl: String
    let channelNumber: String
    let error: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case tunerId
        case playlistUrl
        case channelNumber
        case error
        case message
    }
}

// Response from /api/live/heartbeat and /api/live/stop
struct LiveTVResponse: Codable {
    let success: Bool
    let message: String
}
