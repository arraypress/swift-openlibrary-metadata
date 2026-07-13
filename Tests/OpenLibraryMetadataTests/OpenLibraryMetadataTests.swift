//
//  OpenLibraryMetadataTests.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import OpenLibraryMetadata

final class OpenLibraryMetadataTests: XCTestCase {

    // MARK: - Search parsing

    func testParseSearchResults() throws {
        let results = OpenLibraryParser.searchResults(try json(Fixture.search), query: "the hobbit")

        XCTAssertEqual(results.query, "the hobbit")
        XCTAssertEqual(results.numFound, 412)
        XCTAssertEqual(results.start, 0)
        XCTAssertTrue(results.hasMore)
        XCTAssertEqual(results.books.count, 1)

        let book = results.books[0]
        XCTAssertEqual(book.key, "OL262758W")        // bare work ID, "/works/" stripped
        XCTAssertEqual(book.workKey, "OL262758W")
        XCTAssertEqual(book.title, "The Hobbit")
        XCTAssertEqual(book.authors, ["J.R.R. Tolkien"])
        XCTAssertEqual(book.authorKeys, ["OL26320A"])
        XCTAssertEqual(book.firstPublishYear, 1937)
        XCTAssertEqual(book.editionCount, 463)
        XCTAssertEqual(book.coverID, 14627509)
        XCTAssertEqual(book.pageCount, 310)
        XCTAssertEqual(book.isbns, ["9780007458424", "0007458428"])
        XCTAssertEqual(book.subjects, ["Fantasy", "Fiction"])
        XCTAssertEqual(book.languages, ["eng", "ita"])
    }

    // MARK: - Cover URLs

    func testCoverURLSizes() throws {
        let book = OpenLibraryParser.book(fromSearchDoc: try json(Fixture.searchDoc))
        XCTAssertEqual(book.coverURL?.absoluteString,
                       "https://covers.openlibrary.org/b/id/14627509-L.jpg")
        XCTAssertEqual(book.coverURL(size: .small)?.absoluteString,
                       "https://covers.openlibrary.org/b/id/14627509-S.jpg")
        XCTAssertEqual(book.coverURL(size: .medium)?.absoluteString,
                       "https://covers.openlibrary.org/b/id/14627509-M.jpg")
    }

    func testNoCoverYieldsNilURL() {
        let book = OpenLibraryParser.book(fromSearchDoc: ["title": "No Cover"])
        XCTAssertNil(book.coverID)
        XCTAssertNil(book.coverURL)
        XCTAssertNil(book.coverURL(size: .small))
    }

    // MARK: - Edition (ISBN) parsing

    func testParseEdition() throws {
        let data = try json(Fixture.edition)
        let names = ["Roald Dahl"]   // simulates best-effort author resolution
        let book = OpenLibraryParser.book(fromEdition: data, authorNames: names)

        XCTAssertEqual(book.key, "OL7353617M")       // edition ID
        XCTAssertEqual(book.workKey, "OL45804W")     // linked work
        XCTAssertEqual(book.title, "Fantastic Mr. Fox")
        XCTAssertEqual(book.authors, ["Roald Dahl"])
        XCTAssertEqual(book.authorKeys, ["OL34184A"])
        XCTAssertEqual(book.firstPublishYear, 1988)  // parsed from "October 1, 1988"
        XCTAssertEqual(book.isbns, ["9780140328721", "0140328726"])  // ISBN-13 then ISBN-10
        XCTAssertEqual(book.publishers, ["Puffin"])
        XCTAssertEqual(book.languages, ["eng"])
        XCTAssertEqual(book.pageCount, 96)
        // The -1 "no cover" sentinel is discarded; the first real ID wins.
        XCTAssertEqual(book.coverID, 15152634)
        XCTAssertEqual(book.coverURL?.absoluteString,
                       "https://covers.openlibrary.org/b/id/15152634-L.jpg")
    }

    func testEditionAuthorKeys() throws {
        let keys = OpenLibraryParser.editionAuthorKeys(try json(Fixture.edition))
        XCTAssertEqual(keys, ["OL34184A"])
    }

    // MARK: - Work parsing

    func testParseWork() throws {
        let work = OpenLibraryParser.work(try json(Fixture.work))
        XCTAssertEqual(work.key, "OL45804W")
        XCTAssertEqual(work.title, "Fantastic Mr Fox")
        // description arrives as { "type": …, "value": … } and is flattened.
        XCTAssertEqual(work.description, "A clever fox outwits three farmers.")
        XCTAssertEqual(work.subjects, ["Animals", "Foxes", "Hunger"])
        XCTAssertEqual(work.firstPublishDate, "1970")
        XCTAssertEqual(work.authorKeys, ["OL34184A"])
        // -1 sentinel dropped; primary cover drives the URL.
        XCTAssertEqual(work.coverIDs, [6498519, 8904777])
        XCTAssertEqual(work.coverURL?.absoluteString,
                       "https://covers.openlibrary.org/b/id/6498519-L.jpg")
    }

    func testWorkDescriptionAsPlainString() throws {
        let work = OpenLibraryParser.work([
            "key": "/works/OL1W", "title": "X", "description": "Just a string."
        ])
        XCTAssertEqual(work.description, "Just a string.")
    }

    // MARK: - Author parsing

    func testParseAuthor() throws {
        let author = OpenLibraryParser.author(try json(Fixture.author))
        XCTAssertEqual(author.key, "OL34184A")
        XCTAssertEqual(author.name, "Roald Dahl")
        XCTAssertEqual(author.birthDate, "13 September 1916")
        XCTAssertEqual(author.deathDate, "23 November 1990")
        // bio arrives as { "type": …, "value": … } and is flattened.
        XCTAssertEqual(author.bio, "A British novelist and short story writer.")
        XCTAssertEqual(author.alternateNames, ["Roald Dalh"])
        XCTAssertEqual(author.photoID, 9395323)
        XCTAssertEqual(author.photoURL(size: .medium)?.absoluteString,
                       "https://covers.openlibrary.org/a/id/9395323-M.jpg")
    }

    func testAuthorBioAsPlainString() {
        let author = OpenLibraryParser.author(["key": "/authors/OL1A", "name": "Y", "bio": "Plain bio."])
        XCTAssertEqual(author.bio, "Plain bio.")
        XCTAssertNil(author.birthDate)
        XCTAssertNil(author.photoID)
    }

    // MARK: - Key normalisation

    func testBareIDStripsPrefix() {
        XCTAssertEqual(OpenLibraryParser.bareID("/works/OL45804W"), "OL45804W")
        XCTAssertEqual(OpenLibraryParser.bareID("/authors/OL34184A"), "OL34184A")
        XCTAssertEqual(OpenLibraryParser.bareID("OL7353617M"), "OL7353617M")
    }

    // MARK: - Input validation

    func testEmptyISBNThrows() async {
        do {
            _ = try await OpenLibraryMetadata.book(isbn: "  -- ")
            XCTFail("Expected invalidInput")
        } catch OpenLibraryMetadataError.invalidInput {
            // expected
        } catch {
            XCTFail("Expected invalidInput, got \(error)")
        }
    }

    // MARK: - Live network tests (opt-in, keyless)

    func testLiveSearch() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["OPENLIBRARY_LIVE_TESTS"] == "1",
                          "Set OPENLIBRARY_LIVE_TESTS=1 to run live network tests.")
        let results = try await OpenLibraryMetadata.search("the hobbit", limit: 5)
        XCTAssertGreaterThan(results.numFound, 0)
        XCTAssertFalse(results.books.isEmpty)

        let top = results.books[0]
        XCTAssertFalse(top.title.isEmpty)
        XCTAssertFalse(top.authors.isEmpty)

        if ProcessInfo.processInfo.environment["OPENLIBRARY_PRINT"] == "1" {
            print("=== search 'the hobbit': \(results.numFound) works ===")
            for book in results.books {
                print("• \(book.title) — \(book.authors.joined(separator: ", ")) (\(book.firstPublishYear ?? 0)) [\(book.editionCount ?? 0) editions]")
                print("  cover: \(book.coverURL?.absoluteString ?? "none")")
            }
        }
    }

    func testLiveISBNLookup() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["OPENLIBRARY_LIVE_TESTS"] == "1",
                          "Set OPENLIBRARY_LIVE_TESTS=1 to run live network tests.")
        let book = try await OpenLibraryMetadata.book(isbn: "9780140328721")
        XCTAssertFalse(book.title.isEmpty)
        XCTAssertTrue(book.isbns.contains("9780140328721"))
        XCTAssertNotNil(book.workKey)

        if ProcessInfo.processInfo.environment["OPENLIBRARY_PRINT"] == "1" {
            print("=== ISBN 9780140328721 ===")
            print("\(book.title) — \(book.authors.joined(separator: ", "))")
            print("cover: \(book.coverURL?.absoluteString ?? "none")  · work: \(book.workKey ?? "?")")
        }
    }

    func testLiveWorkAndAuthor() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["OPENLIBRARY_LIVE_TESTS"] == "1",
                          "Set OPENLIBRARY_LIVE_TESTS=1 to run live network tests.")
        let work = try await OpenLibraryMetadata.work("OL45804W")
        XCTAssertFalse(work.title.isEmpty)
        XCTAssertFalse(work.authorKeys.isEmpty)

        let author = try await OpenLibraryMetadata.author(work.authorKeys[0])
        XCTAssertFalse(author.name.isEmpty)

        if ProcessInfo.processInfo.environment["OPENLIBRARY_PRINT"] == "1" {
            print("=== work OL45804W ===")
            print("\(work.title) — first published \(work.firstPublishDate ?? "?")")
            print("author: \(author.name) (\(author.birthDate ?? "?") – \(author.deathDate ?? "?"))")
        }
    }

    // MARK: - Helpers

    private func json(_ string: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(string.utf8)) as? [String: Any])
    }
}

// MARK: - Fixtures (mirror verified Open Library shapes)

private enum Fixture {

    /// A single `/search.json` document (a work).
    static let searchDoc = """
    { "key": "/works/OL262758W", "title": "The Hobbit",
      "author_name": ["J.R.R. Tolkien"], "author_key": ["OL26320A"],
      "first_publish_year": 1937, "edition_count": 463, "cover_i": 14627509,
      "number_of_pages_median": 310,
      "isbn": ["9780007458424", "0007458428"],
      "subject": ["Fantasy", "Fiction"], "language": ["eng", "ita"],
      "publisher": ["Houghton Mifflin"] }
    """

    /// A `/search.json` response wrapping one document.
    static let search = """
    { "numFound": 412, "start": 0, "num_found": 412, "docs": [ \(searchDoc) ] }
    """

    /// An edition (from `/isbn/9780140328721.json`), including the `-1` cover sentinel.
    static let edition = """
    { "key": "/books/OL7353617M", "title": "Fantastic Mr. Fox",
      "authors": [ { "key": "/authors/OL34184A" } ],
      "publish_date": "October 1, 1988", "publishers": ["Puffin"],
      "covers": [15152634, 8739161, -1],
      "works": [ { "key": "/works/OL45804W" } ],
      "languages": [ { "key": "/languages/eng" } ],
      "number_of_pages": 96,
      "isbn_10": ["0140328726"], "isbn_13": ["9780140328721"] }
    """

    /// A work (from `/works/OL45804W.json`), with a `{ value }` description.
    static let work = """
    { "key": "/works/OL45804W", "title": "Fantastic Mr Fox",
      "description": { "type": "/type/text", "value": "A clever fox outwits three farmers." },
      "subjects": ["Animals", "Foxes", "Hunger"],
      "covers": [6498519, -1, 8904777],
      "first_publish_date": "1970",
      "authors": [ { "author": { "key": "/authors/OL34184A" }, "type": { "key": "/type/author_role" } } ] }
    """

    /// An author (from `/authors/OL34184A.json`), with a `{ value }` bio.
    static let author = """
    { "key": "/authors/OL34184A", "name": "Roald Dahl",
      "birth_date": "13 September 1916", "death_date": "23 November 1990",
      "bio": { "type": "/type/text", "value": "A British novelist and short story writer." },
      "alternate_names": ["Roald Dalh"],
      "photos": [9395323, 9395316, -1] }
    """
}
