//
//  OLAuthor.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// An Open Library author.
///
/// ```swift
/// let author = try await OpenLibraryMetadata.author("OL34184A")
/// print(author.name)                 // "Roald Dahl"
/// print(author.birthDate ?? "")      // "13 September 1916"
/// print(author.bio ?? "")
/// if let photo = author.photoURL(size: .medium) { print(photo) }
/// ```
public struct OLAuthor: Sendable, Identifiable {

    /// The Open Library author identifier (e.g. `"OL34184A"`).
    public let key: String

    /// The author's display name.
    public let name: String

    /// The author's birth date, as free text (e.g. `"13 September 1916"`).
    public let birthDate: String?

    /// The author's death date, as free text, if applicable.
    public let deathDate: String?

    /// A prose biography of the author, if one exists.
    public let bio: String?

    /// Alternate spellings and transliterations of the author's name.
    public let alternateNames: [String]

    /// The author's photo image ID, used to build ``photoURL``.
    public let photoID: Int?

    // MARK: - Computed

    /// The `id` for `Identifiable` conformance (the Open Library ``key``).
    public var id: String { key }

    /// The large author photo URL, if a ``photoID`` is present.
    public var photoURL: URL? { photoURL(size: .large) }

    /// Builds the author photo URL at the requested size.
    ///
    /// - Parameter size: The desired image size. Defaults to ``OLCoverSize/large``.
    /// - Returns: A `covers.openlibrary.org` URL, or `nil` if there is no photo.
    public func photoURL(size: OLCoverSize = .large) -> URL? {
        guard let photoID else { return nil }
        return URL(string: "https://covers.openlibrary.org/a/id/\(photoID)-\(size.rawValue).jpg")
    }

    /// Creates an author.
    public init(
        key: String,
        name: String,
        birthDate: String?,
        deathDate: String?,
        bio: String?,
        alternateNames: [String],
        photoID: Int?
    ) {
        self.key = key
        self.name = name
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.bio = bio
        self.alternateNames = alternateNames
        self.photoID = photoID
    }
}
