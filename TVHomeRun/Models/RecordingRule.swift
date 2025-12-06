//
//  RecordingRule.swift
//  TVHomeRun
//
//  Data model for recording rules
//

import Foundation

struct RecordingRulesResponse: Codable {
    let rules: [RecordingRule]

    enum CodingKeys: String, CodingKey {
        case rules = "rules"
    }
}

struct RecordingRule: Codable, Identifiable {
    let id: String
    let seriesId: String
    let title: String?
    let channelOnly: String?
    let teamOnly: Int?
    let recentOnly: Int?
    let startPadding: Int?
    let endPadding: Int?

    enum CodingKeys: String, CodingKey {
        case id = "RecordingRuleID"
        case seriesId = "SeriesID"
        case title = "Title"
        case channelOnly = "ChannelOnly"
        case teamOnly = "TeamOnly"
        case recentOnly = "RecentOnly"
        case startPadding = "StartPadding"
        case endPadding = "EndPadding"
    }
}

struct CreateRecordingRuleRequest: Codable {
    let seriesId: String
    let channelOnly: String?
    let teamOnly: Int?
    let recentOnly: Int?
    let startPadding: Int?
    let endPadding: Int?

    enum CodingKeys: String, CodingKey {
        case seriesId = "SeriesID"
        case channelOnly = "ChannelOnly"
        case teamOnly = "TeamOnly"
        case recentOnly = "RecentOnly"
        case startPadding = "StartPadding"
        case endPadding = "EndPadding"
    }
}

struct RecordingRuleResponse: Codable {
    let success: Bool
    let recordingRule: RecordingRule?

    enum CodingKeys: String, CodingKey {
        case success
        case recordingRule
    }
}
