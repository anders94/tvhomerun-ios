//
//  Guide.swift
//  TVHomeRun
//
//  Data model for TV guide information
//

import Foundation

struct GuideResponse: Codable {
    let channels: [GuideChannel]

    enum CodingKeys: String, CodingKey {
        case channels = "guide"
    }
}

struct GuideChannel: Codable, Identifiable {
    var id: String { guideNumber }
    let guideNumber: String
    let guideName: String
    let guide: [GuideProgram]

    enum CodingKeys: String, CodingKey {
        case guideNumber = "GuideNumber"
        case guideName = "GuideName"
        case guide = "Guide"
    }
}

struct GuideProgram: Codable, Identifiable {
    var id: String { seriesId + String(startTime) }
    let seriesId: String
    let title: String
    let episodeNumber: String?
    let episodeTitle: String?
    let startTime: Int
    let endTime: Int
    let synopsis: String?
    let imageUrl: String?
    let filter: [String]?

    enum CodingKeys: String, CodingKey {
        case seriesId = "SeriesID"
        case title = "Title"
        case episodeNumber = "EpisodeNumber"
        case episodeTitle = "EpisodeTitle"
        case startTime = "StartTime"
        case endTime = "EndTime"
        case synopsis = "Synopsis"
        case imageUrl = "ImageURL"
        case filter = "Filter"
    }

    var formattedStartTime: String {
        let date = Date(timeIntervalSince1970: TimeInterval(startTime))
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    var durationMinutes: Int {
        return (endTime - startTime) / 60
    }
}

// For grouping programs by series
struct GuideSeries: Identifiable, Hashable {
    let id: String // seriesId
    let title: String
    let imageUrl: String?
    let programs: [GuideProgram]

    var upcomingCount: Int {
        programs.count
    }

    static func == (lhs: GuideSeries, rhs: GuideSeries) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
