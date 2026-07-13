//
//  OLWork.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// An Open Library *work* — the canonical entry that groups every edition of a
/// book (all printings, translations, and formats).
///
/// ```swift
/// let work = try await OpenLibraryMetadata.work("OL45804W")
/// print(work.title)
/// print(work.description ?? "")
/// for key in work.authorKeys {
///     let author = try await OpenLibraryMetadata.author(key)
///     print(author.name)
/// }
/// ```
public struct OLWork: Sendable, Identifiable {

    /// The Open Library work identifier (e.g. `"OL45804W"`).
    public let key: String

    /// The work's title.
    public let title: String

    /// A prose description of the work, if one exists.
    public let description: String?

    /// Subject tags associated with the work.
    public let subjects: [String]

    /// Cover image IDs for the work, best-first. Use ``coverURL(size:)`` to build
    /// a URL from the primary cover.
    public let coverIDs: [Int]

    /// The date the work was first published, as free text (e.g. `"1937"`).
    public let firstPublishDate: String?

    /// The Open Library author identifiers (e.g. `["OL34184A"]`), suitable for
    /// passing to ``OpenLibraryMetadata/author(_:configuration:)``.
    public let authorKeys: [String]

    // MARK: - Computed

    /// The `id` for `Identifiable` conformance (the Open Library ``key``).
    public var id: String { key }

    /// The large cover image URL, if the work has a cover.
    public var coverURL: URL? { coverURL(size: .large) }

    /// Builds the primary cover image URL at the requested size.
    ///
    /// - Parameter size: The desired image size. Defaults to ``OLCoverSize/large``.
    /// - Returns: A `covers.openlibrary.org` URL, or `nil` if there is no cover.
    public func coverURL(size: OLCoverSize = .large) -> URL? {
        guard let coverID = coverIDs.first else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverID)-\(size.rawValue).jpg")
    }

    /// Creates a work.
    public init(
        key: String,
        title: String,
        description: String?,
        subjects: [String],
        coverIDs: [Int],
        firstPublishDate: String?,
        authorKeys: [String]
    ) {
        self.key = key
        self.title = title
        self.description = description
        self.subjects = subjects
        self.coverIDs = coverIDs
        self.firstPublishDate = firstPublishDate
        self.authorKeys = authorKeys
    }
}
