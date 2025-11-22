//
//  Health.swift
//  TVHomeRun
//
//  Data model for health check response
//

import Foundation

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let uptime: Double
    let lastDiscovery: String?
    let isDiscovering: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case timestamp
        case uptime
        case lastDiscovery = "lastDiscovery"
        case isDiscovering = "isDiscovering"
    }

    var isHealthy: Bool {
        status.lowercased() == "ok"
    }
}
