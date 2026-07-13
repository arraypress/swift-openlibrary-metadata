//
//  OpenLibraryClient.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performs GET requests against the keyless Open Library API.
///
/// No API key or authentication is required. Open Library asks callers to send a
/// descriptive `User-Agent` identifying the application; a default is provided in
/// ``OpenLibraryMetadata/Configuration`` and can be overridden.
///
/// Some endpoints (notably `/isbn/{isbn}.json`) respond with a `302` redirect to
/// the canonical resource; `URLSession` follows these automatically.
enum OpenLibraryClient {

    /// The base host for the Open Library data API.
    static let host = "https://openlibrary.org"

    /// Performs a GET request and decodes the JSON body into a dictionary.
    ///
    /// - Parameters:
    ///   - path: The request path (e.g. `/works/OL45804W.json`).
    ///   - queryItems: Optional query parameters.
    ///   - configuration: Networking options (the `User-Agent` header).
    /// - Throws: ``OpenLibraryMetadataError`` for network, status, or parsing failures.
    /// - Returns: The decoded top-level JSON object.
    static func get(
        path: String,
        queryItems: [URLQueryItem] = [],
        configuration: OpenLibraryMetadata.Configuration
    ) async throws -> [String: Any] {
        guard var components = URLComponents(string: host + path) else {
            throw OpenLibraryMetadataError.networkError("Invalid request URL")
        }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else {
            throw OpenLibraryMetadataError.networkError("Invalid request URL")
        }

        var request = URLRequest(url: url)
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OpenLibraryMetadataError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            switch http.statusCode {
            case 404: throw OpenLibraryMetadataError.notFound
            case 429: throw OpenLibraryMetadataError.rateLimited
            default:  throw OpenLibraryMetadataError.apiError("HTTP \(http.statusCode)")
            }
        }

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw OpenLibraryMetadataError.parsingError("Invalid JSON response")
        }
        return json
    }
}
