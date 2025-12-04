//
//  APIClient.swift
//  TVHomeRun
//
//  API client with exponential backoff and error handling
//

import Foundation
import Combine

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .timeout:
            return "Connection timeout"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// Empty response for requests that don't return data
struct EmptyResponse: Codable {}

@MainActor
class APIClient: ObservableObject {
    @Published var isLoading = false
    @Published var error: APIError?
    @Published var showErrorAlert = false

    private var baseURL: String
    private let session: URLSession
    private let maxRetries = 3
    private let initialBackoff: TimeInterval = 1.0
    private let maxBackoff: TimeInterval = 5.0

    init(baseURL: String) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    func updateBaseURL(_ url: String) {
        self.baseURL = url
    }

    // MARK: - Health Check

    func checkHealth() async throws -> HealthResponse {
        try await performRequest(endpoint: "/health", responseType: HealthResponse.self)
    }

    // MARK: - Shows

    func fetchShows() async throws -> [Show] {
        let response: ShowsResponse = try await performRequest(
            endpoint: "/api/shows",
            responseType: ShowsResponse.self
        )
        return response.shows
    }

    // MARK: - Episodes

    func fetchEpisodes(for showId: Int) async throws -> EpisodesResponse {
        try await performRequest(
            endpoint: "/api/shows/\(showId)/episodes",
            responseType: EpisodesResponse.self
        )
    }

    func updateEpisodeProgress(episodeId: Int, position: Int, watched: Bool) async throws {
        struct ProgressUpdate: Codable {
            let position: Int
            let watched: Int
        }

        let body = ProgressUpdate(position: position, watched: watched ? 1 : 0)

        _ = try await performRequest(
            endpoint: "/api/episodes/\(episodeId)/progress",
            method: "PUT",
            body: body,
            responseType: EmptyResponse.self
        )
    }

    func deleteEpisode(episodeId: Int, rerecord: Bool = false) async throws {
        let rerecordParam = rerecord ? "?rerecord=true" : ""
        _ = try await performRequest(
            endpoint: "/api/episodes/\(episodeId)\(rerecordParam)",
            method: "DELETE",
            responseType: EmptyResponse.self
        )
    }

    // MARK: - Generic Request Handler with Exponential Backoff

    private func performRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        responseType: T.Type,
        retryCount: Int = 0
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add body for PUT/POST requests
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            do {
                // Handle empty responses for DELETE and other requests that may not return data
                if data.isEmpty || (data.count == 2 && data == Data("{}".utf8)) {
                    // Return empty response if T is EmptyResponse
                    if T.self == EmptyResponse.self {
                        return EmptyResponse() as! T
                    }
                }
                let decodedResponse = try decoder.decode(T.self, from: data)
                return decodedResponse
            } catch {
                throw APIError.decodingError(error)
            }

        } catch let error as APIError {
            // Already an APIError, check if we should retry
            if retryCount < maxRetries {
                return try await retryWithBackoff(
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    responseType: responseType,
                    retryCount: retryCount,
                    error: error
                )
            }
            throw error

        } catch {
            // Network error, check if we should retry
            let apiError = APIError.networkError(error)
            if retryCount < maxRetries {
                return try await retryWithBackoff(
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    responseType: responseType,
                    retryCount: retryCount,
                    error: apiError
                )
            }
            throw apiError
        }
    }

    private func retryWithBackoff<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable?,
        responseType: T.Type,
        retryCount: Int,
        error: APIError
    ) async throws -> T {
        let backoffTime = min(initialBackoff * pow(2.0, Double(retryCount)), maxBackoff)
        let totalWaitTime = (0..<retryCount).reduce(0.0) { total, retry in
            total + min(initialBackoff * pow(2.0, Double(retry)), maxBackoff)
        } + backoffTime

        // Only show error alert if we've been trying for at least 5 seconds
        if totalWaitTime >= 5.0 && retryCount == maxRetries - 1 {
            await MainActor.run {
                self.error = error
                self.showErrorAlert = true
            }
        }

        try await Task.sleep(nanoseconds: UInt64(backoffTime * 1_000_000_000))

        return try await performRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            responseType: responseType,
            retryCount: retryCount + 1
        )
    }

    func clearError() {
        error = nil
        showErrorAlert = false
    }
}
