//
//  OpenLibraryMetadata.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Fetch book metadata from Open Library — search the catalogue, look up editions
/// by ISBN, and read works and authors — with **no API key or authentication**.
///
/// Every endpoint used here is part of Open Library's free, keyless data API
/// (`openlibrary.org`). Cover artwork is served from `covers.openlibrary.org` and
/// exposed through ``OLBook/coverURL(size:)``.
///
/// Open Library asks callers to send a descriptive `User-Agent`; a default is
/// provided and can be overridden via ``Configuration``.
///
/// ## Quick Start
///
/// ```swift
/// import OpenLibraryMetadata
///
/// // Search the catalogue
/// let results = try await OpenLibraryMetadata.search("the hobbit", limit: 5)
/// print("\(results.numFound) works match")
/// for book in results.books {
///     print("\(book.title) — \(book.authors.joined(separator: ", ")) (\(book.firstPublishYear ?? 0))")
/// }
///
/// // Look up a specific edition by ISBN
/// let edition = try await OpenLibraryMetadata.book(isbn: "9780140328721")
/// print(edition.title)                       // "Fantastic Mr. Fox"
/// print(edition.coverURL?.absoluteString ?? "")
///
/// // Drill into the work and its author
/// if let workKey = edition.workKey {
///     let work = try await OpenLibraryMetadata.work(workKey)
///     print(work.description ?? "")
/// }
/// let author = try await OpenLibraryMetadata.author("OL34184A")
/// print("\(author.name) (\(author.birthDate ?? "?"))")
/// ```
public enum OpenLibraryMetadata {

    // MARK: - Configuration

    /// Options for talking to the Open Library API.
    public struct Configuration: Sendable {

        /// The `User-Agent` sent with every request. Open Library asks for a
        /// descriptive one identifying your application; the default identifies
        /// this library.
        public var userAgent: String

        /// Creates a configuration.
        ///
        /// - Parameter userAgent: The `User-Agent` header to send.
        public init(
            userAgent: String = "swift-openlibrary-metadata/1.0 (+https://github.com/arraypress)"
        ) {
            self.userAgent = userAgent
        }

        /// The default configuration, reading an optional `OPENLIBRARY_USER_AGENT`
        /// override from the environment.
        public static var `default`: Configuration {
            if let agent = ProcessInfo.processInfo.environment["OPENLIBRARY_USER_AGENT"], !agent.isEmpty {
                return Configuration(userAgent: agent)
            }
            return Configuration()
        }
    }

    // MARK: - Public API

    /// Searches the Open Library catalogue.
    ///
    /// Matches across titles, authors, and other indexed fields, returning one
    /// ``OLBook`` per matching *work* (all editions aggregated). Page through
    /// results with ``OLSearchResults/hasMore``.
    ///
    /// ```swift
    /// let results = try await OpenLibraryMetadata.search("dune", limit: 10, page: 1)
    /// for book in results.books { print(book.title) }
    /// ```
    ///
    /// - Parameters:
    ///   - query: The free-text query.
    ///   - limit: Maximum results per page (Open Library caps this at 100). Defaults to `20`.
    ///   - page: The 1-based page number. Defaults to `1`.
    ///   - configuration: Networking options. Defaults to ``Configuration/default``.
    /// - Returns: A page of ``OLSearchResults``.
    public static func search(
        _ query: String,
        limit: Int = 20,
        page: Int = 1,
        configuration: Configuration = .default
    ) async throws -> OLSearchResults {
        let items = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(max(1, min(limit, 100)))),
            URLQueryItem(name: "page", value: String(max(1, page))),
            URLQueryItem(name: "fields", value: OpenLibraryParser.searchFields)
        ]
        let data = try await OpenLibraryClient.get(
            path: "/search.json", queryItems: items, configuration: configuration
        )
        return OpenLibraryParser.searchResults(data, query: query)
    }

    /// Looks up a specific edition by its ISBN.
    ///
    /// Editions store their authors as identifiers rather than names; this method
    /// resolves the display names on a best-effort basis so ``OLBook/authors`` is
    /// populated. The edition's cover is available via ``OLBook/coverURL(size:)``.
    ///
    /// ```swift
    /// let book = try await OpenLibraryMetadata.book(isbn: "9780140328721")
    /// print("\(book.title) — \(book.authors.joined(separator: ", "))")
    /// ```
    ///
    /// - Parameters:
    ///   - isbn: A 10- or 13-digit ISBN (hyphens and spaces are ignored).
    ///   - configuration: Networking options. Defaults to ``Configuration/default``.
    /// - Throws: ``OpenLibraryMetadataError/invalidInput`` for an empty ISBN, or
    ///   ``OpenLibraryMetadataError/notFound`` if no edition matches.
    /// - Returns: The matching edition as an ``OLBook``.
    public static func book(
        isbn: String,
        configuration: Configuration = .default
    ) async throws -> OLBook {
        let cleaned = isbn.filter { $0.isNumber || $0 == "X" || $0 == "x" }
        guard !cleaned.isEmpty else { throw OpenLibraryMetadataError.invalidInput }

        let data = try await OpenLibraryClient.get(
            path: "/isbn/\(cleaned).json", configuration: configuration
        )
        let names = await resolveAuthorNames(
            OpenLibraryParser.editionAuthorKeys(data), configuration: configuration
        )
        return OpenLibraryParser.book(fromEdition: data, authorNames: names)
    }

    /// Fetches a work (the canonical entry grouping every edition of a book).
    ///
    /// - Parameters:
    ///   - id: A work identifier, e.g. `"OL45804W"` or `"/works/OL45804W"`.
    ///   - configuration: Networking options. Defaults to ``Configuration/default``.
    /// - Returns: The ``OLWork``.
    public static func work(
        _ id: String,
        configuration: Configuration = .default
    ) async throws -> OLWork {
        let cleaned = OpenLibraryParser.bareID(id)
        guard !cleaned.isEmpty else { throw OpenLibraryMetadataError.invalidInput }
        let data = try await OpenLibraryClient.get(
            path: "/works/\(cleaned).json", configuration: configuration
        )
        return OpenLibraryParser.work(data)
    }

    /// Fetches an author.
    ///
    /// - Parameters:
    ///   - id: An author identifier, e.g. `"OL34184A"` or `"/authors/OL34184A"`.
    ///   - configuration: Networking options. Defaults to ``Configuration/default``.
    /// - Returns: The ``OLAuthor``.
    public static func author(
        _ id: String,
        configuration: Configuration = .default
    ) async throws -> OLAuthor {
        let cleaned = OpenLibraryParser.bareID(id)
        guard !cleaned.isEmpty else { throw OpenLibraryMetadataError.invalidInput }
        let data = try await OpenLibraryClient.get(
            path: "/authors/\(cleaned).json", configuration: configuration
        )
        return OpenLibraryParser.author(data)
    }

    // MARK: - Helpers

    /// Resolves author display names from their Open Library keys, best-effort.
    ///
    /// Any key that fails to resolve is skipped rather than throwing, so a partial
    /// or empty result degrades gracefully.
    private static func resolveAuthorNames(
        _ keys: [String],
        configuration: Configuration
    ) async -> [String] {
        var names: [String] = []
        for key in keys {
            if let data = try? await OpenLibraryClient.get(
                path: "/authors/\(key).json", configuration: configuration
            ), let name = data["name"] as? String, !name.isEmpty {
                names.append(name)
            }
        }
        return names
    }
}
