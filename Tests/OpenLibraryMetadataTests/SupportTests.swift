//
//  SupportTests.swift
//  OpenLibraryMetadataTests
//
//  Created by David Sherlock on 2026.
//
//  The cover-URL namespaces pinned directly.
//

import XCTest
@testable import OpenLibraryMetadata

final class SupportTests: XCTestCase {

    func testCoverNamespaces() {
        XCTAssertEqual(
            CoverURL.author(photoID: 1, size: .large)?.absoluteString,
            "https://covers.openlibrary.org/a/id/1-\(OLCoverSize.large.rawValue).jpg",
            "author photos live under /a/"
        )
        XCTAssertEqual(
            CoverURL.book(coverID: 2, size: .small)?.absoluteString,
            "https://covers.openlibrary.org/b/id/2-\(OLCoverSize.small.rawValue).jpg",
            "book and work covers live under /b/"
        )
    }
}
