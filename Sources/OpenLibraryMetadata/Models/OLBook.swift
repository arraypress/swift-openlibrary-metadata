//
//  OLBook.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A book from Open Library — either a search result (a *work*) or a specific
/// *edition* fetched by ISBN.
///
/// Search hits describe the work as a whole (aggregating every edition), so they
/// carry ``editionCount`` and a representative ``coverID``. An edition fetched by
/// ``OpenLibraryMetadata/book(isbn:configuration:)`` describes one printing, so it
/// carries that edition's ``isbns``, ``pageCount``, and ``workKey``.
///
/// The cover artwork is available at three sizes via ``coverURL(size:)`` (or the
/// large-size ``coverURL`` convenience) whenever a ``coverID`` is present.
///
/// ```swift
/// let results = try await OpenLibraryMetadata.search("the hobbit")
/// for book in results.books {
///     print("\(book.title) — \(book.authors.joined(separator: ", "))")
///     if let cover = book.coverURL(size: .medium) { print(cover) }
/// }
/// ```
public struct OLBook: Sendable, Identifiable {

    /// The Open Library identifier: a work ID (e.g. `"OL45804W"`) for search
    /// results, or an edition ID (e.g. `"OL7353617M"`) for ISBN lookups.
    public let key: String

    /// The book's title.
    public let title: String

    /// The author display names, when available.
    ///
    /// Present on search results. Editions carry author *keys* rather than names;
    /// ``OpenLibraryMetadata/book(isbn:configuration:)`` resolves them on a
    /// best-effort basis.
    public let authors: [String]

    /// The Open Library author identifiers (e.g. `["OL34184A"]`), suitable for
    /// passing to ``OpenLibraryMetadata/author(_:configuration:)``.
    public let authorKeys: [String]

    /// The year the work was first published, if known.
    public let firstPublishYear: Int?

    /// ISBNs associated with this book (ISBN-13 first, then ISBN-10 for editions).
    public let isbns: [String]

    /// The Open Library cover image ID, used to build ``coverURL``.
    public let coverID: Int?

    /// The number of known editions of this work (search results only).
    public let editionCount: Int?

    /// Subject tags associated with the book.
    public let subjects: [String]

    /// Publisher names associated with the book.
    public let publishers: [String]

    /// Language codes (e.g. `"eng"`) associated with the book.
    public let languages: [String]

    /// The page count — the median across editions for search results, or the
    /// exact count for an edition.
    public let pageCount: Int?

    /// The identifier of the work this book belongs to (e.g. `"OL45804W"`),
    /// suitable for passing to ``OpenLibraryMetadata/work(_:configuration:)``.
    public let workKey: String?

    // MARK: - Computed

    /// The `id` for `Identifiable` conformance (the Open Library ``key``).
    public var id: String { key }

    /// The large cover image URL, if a ``coverID`` is present.
    public var coverURL: URL? { coverURL(size: .large) }

    /// Builds the cover image URL at the requested size.
    ///
    /// - Parameter size: The desired image size. Defaults to ``OLCoverSize/large``.
    /// - Returns: A `covers.openlibrary.org` URL, or `nil` if there is no cover.
    public func coverURL(size: OLCoverSize = .large) -> URL? {
        guard let coverID else { return nil }
        return CoverURL.book(coverID: coverID, size: size)
    }

    /// Creates a book.
    public init(
        key: String,
        title: String,
        authors: [String],
        authorKeys: [String],
        firstPublishYear: Int?,
        isbns: [String],
        coverID: Int?,
        editionCount: Int?,
        subjects: [String],
        publishers: [String],
        languages: [String],
        pageCount: Int?,
        workKey: String?
    ) {
        self.key = key
        self.title = title
        self.authors = authors
        self.authorKeys = authorKeys
        self.firstPublishYear = firstPublishYear
        self.isbns = isbns
        self.coverID = coverID
        self.editionCount = editionCount
        self.subjects = subjects
        self.publishers = publishers
        self.languages = languages
        self.pageCount = pageCount
        self.workKey = workKey
    }
}
