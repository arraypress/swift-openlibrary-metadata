//
//  CoverURL.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//
//  covers.openlibrary.org in one place. The scheme's one trap is the
//  path prefix: author photos live under /a/, book and work covers
//  under /b/ — three models each carried a copy of this rule.
//

import Foundation

/// Assembly of Open Library cover and photo URLs.
enum CoverURL {

    /// An author photo URL (the `/a/` namespace).
    static func author(photoID: Int, size: OLCoverSize) -> URL? {
        URL(string: "https://covers.openlibrary.org/a/id/\(photoID)-\(size.rawValue).jpg")
    }

    /// A book or work cover URL (the `/b/` namespace).
    static func book(coverID: Int, size: OLCoverSize) -> URL? {
        URL(string: "https://covers.openlibrary.org/b/id/\(coverID)-\(size.rawValue).jpg")
    }
}
