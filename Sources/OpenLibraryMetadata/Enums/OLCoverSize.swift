//
//  OLCoverSize.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The size of an Open Library cover or author photo.
///
/// Open Library serves each image at three fixed sizes; the raw value is the
/// suffix used in the image URL (`…-S.jpg`, `…-M.jpg`, `…-L.jpg`).
public enum OLCoverSize: String, Sendable, CaseIterable {

    /// Small thumbnail (roughly 39×58 for covers).
    case small = "S"

    /// Medium thumbnail (roughly 180×265 for covers).
    case medium = "M"

    /// Large image (roughly 500×735 for covers).
    case large = "L"
}
