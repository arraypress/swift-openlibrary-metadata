//
//  OLSearchResults.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A page of Open Library search results, with pagination metadata.
///
/// ```swift
/// let results = try await OpenLibraryMetadata.search("dune", limit: 10, page: 1)
/// print("\(results.numFound) works match")
/// for book in results.books {
///     print(book.title)
/// }
/// if results.hasMore { /* fetch page 2 */ }
/// ```
public struct OLSearchResults: Sendable {

    /// The books (works) on this page.
    public let books: [OLBook]

    /// The query that produced these results.
    public let query: String

    /// The total number of matching works across all pages.
    public let numFound: Int

    /// The zero-based offset of the first result on this page.
    public let start: Int

    /// Whether more results exist beyond this page.
    public var hasMore: Bool { start + books.count < numFound }

    /// Creates a page of search results.
    public init(
        books: [OLBook],
        query: String,
        numFound: Int,
        start: Int
    ) {
        self.books = books
        self.query = query
        self.numFound = numFound
        self.start = start
    }
}
