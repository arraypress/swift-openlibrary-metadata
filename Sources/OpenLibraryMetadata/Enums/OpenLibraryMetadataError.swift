//
//  OpenLibraryMetadataError.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when calling the Open Library API.
///
/// ```swift
/// do {
///     let book = try await OpenLibraryMetadata.book(isbn: "9780140328721")
/// } catch OpenLibraryMetadataError.notFound {
///     print("No edition with that ISBN")
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum OpenLibraryMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// The provided input was empty or could not be turned into a valid request.
    case invalidInput

    /// The requested resource was not found (`404`).
    case notFound

    /// Open Library is rate-limiting requests (`429`). Slow down and retry.
    case rateLimited

    /// Open Library returned an error payload or unexpected status.
    case apiError(String)

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the response.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Could not build a valid Open Library request from the input (empty ISBN or identifier)."
        case .notFound:
            return "The requested Open Library resource was not found."
        case .rateLimited:
            return "Open Library is rate-limiting requests. Slow down and try again shortly."
        case .apiError(let message):
            return "Open Library API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
