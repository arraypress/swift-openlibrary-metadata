//
//  OpenLibraryParser.swift
//  OpenLibraryMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses Open Library API response objects into typed models.
///
/// Open Library returns several fields as *either* a plain string *or* a
/// `{ "type": …, "value": … }` object (notably `description` and `bio`);
/// ``textValue(_:)`` normalises both shapes.
enum OpenLibraryParser {

    /// The fields requested from the search endpoint. The default search response
    /// omits ISBNs, subjects, publishers, and page counts, so they are requested
    /// explicitly.
    static let searchFields = [
        "key", "title", "author_name", "author_key", "first_publish_year",
        "isbn", "cover_i", "edition_count", "subject", "language",
        "publisher", "number_of_pages_median"
    ].joined(separator: ",")

    // MARK: - Search

    /// Parses a `/search.json` response into ``OLSearchResults``.
    static func searchResults(_ d: [String: Any], query: String) -> OLSearchResults {
        let docs = (d["docs"] as? [[String: Any]] ?? []).map(book(fromSearchDoc:))
        return OLSearchResults(
            books: docs,
            query: query,
            numFound: intValue(d["numFound"]) ?? intValue(d["num_found"]) ?? docs.count,
            start: intValue(d["start"]) ?? 0
        )
    }

    /// Parses a single search document (a *work*) into an ``OLBook``.
    static func book(fromSearchDoc d: [String: Any]) -> OLBook {
        let workID = bareID(d["key"] as? String ?? "")
        return OLBook(
            key: workID,
            title: d["title"] as? String ?? "",
            authors: stringArray(d["author_name"]),
            authorKeys: stringArray(d["author_key"]).map(bareID),
            firstPublishYear: intValue(d["first_publish_year"]),
            isbns: stringArray(d["isbn"]),
            coverID: positiveInt(d["cover_i"]),
            editionCount: intValue(d["edition_count"]),
            subjects: stringArray(d["subject"]),
            publishers: stringArray(d["publisher"]),
            languages: stringArray(d["language"]),
            pageCount: intValue(d["number_of_pages_median"]),
            workKey: workID.isEmpty ? nil : workID
        )
    }

    // MARK: - Edition (ISBN)

    /// The author identifiers referenced by an edition (e.g. `["OL34184A"]`).
    static func editionAuthorKeys(_ d: [String: Any]) -> [String] {
        keyList(d["authors"])
    }

    /// Parses an edition response (from `/isbn/{isbn}.json`) into an ``OLBook``.
    ///
    /// - Parameters:
    ///   - d: The decoded edition JSON.
    ///   - authorNames: Author display names resolved from the edition's author
    ///     keys (editions do not embed names).
    static func book(fromEdition d: [String: Any], authorNames: [String] = []) -> OLBook {
        let isbns = stringArray(d["isbn_13"]) + stringArray(d["isbn_10"])
        let works = keyList(d["works"])
        return OLBook(
            key: bareID(d["key"] as? String ?? ""),
            title: d["title"] as? String ?? "",
            authors: authorNames,
            authorKeys: editionAuthorKeys(d),
            firstPublishYear: year(from: d["publish_date"] as? String),
            isbns: isbns,
            coverID: coverIDs(d["covers"]).first,
            editionCount: nil,
            subjects: stringArray(d["subjects"]),
            publishers: stringArray(d["publishers"]),
            languages: keyList(d["languages"]),
            pageCount: intValue(d["number_of_pages"]),
            workKey: works.first
        )
    }

    // MARK: - Work

    /// Parses a `/works/{id}.json` response into an ``OLWork``.
    static func work(_ d: [String: Any]) -> OLWork {
        OLWork(
            key: bareID(d["key"] as? String ?? ""),
            title: d["title"] as? String ?? "",
            description: textValue(d["description"]),
            subjects: stringArray(d["subjects"]),
            coverIDs: coverIDs(d["covers"]),
            firstPublishDate: nonEmpty(d["first_publish_date"]),
            authorKeys: workAuthorKeys(d["authors"])
        )
    }

    // MARK: - Author

    /// Parses an `/authors/{id}.json` response into an ``OLAuthor``.
    static func author(_ d: [String: Any]) -> OLAuthor {
        OLAuthor(
            key: bareID(d["key"] as? String ?? ""),
            name: d["name"] as? String ?? "",
            birthDate: nonEmpty(d["birth_date"]),
            deathDate: nonEmpty(d["death_date"]),
            bio: textValue(d["bio"]),
            alternateNames: stringArray(d["alternate_names"]),
            photoID: coverIDs(d["photos"]).first
        )
    }

    // MARK: - Helpers

    /// Reduces an Open Library key path to its bare identifier
    /// (`"/works/OL45804W"` → `"OL45804W"`).
    static func bareID(_ key: String) -> String {
        key.split(separator: "/").last.map(String.init) ?? key
    }

    /// Normalises a value that may be a plain `String` or a `{ "value": … }`
    /// object into a non-empty string.
    private static func textValue(_ value: Any?) -> String? {
        if let string = value as? String { return string.isEmpty ? nil : string }
        if let object = value as? [String: Any], let string = object["value"] as? String {
            return string.isEmpty ? nil : string
        }
        return nil
    }

    /// Extracts bare identifiers from an array of `{ "key": … }` objects
    /// (e.g. an edition's `authors`, `works`, or `languages`).
    private static func keyList(_ value: Any?) -> [String] {
        guard let array = value as? [[String: Any]] else { return [] }
        return array.compactMap { $0["key"] as? String }.map(bareID)
    }

    /// Extracts bare author identifiers from a work's `authors`, each shaped as
    /// `{ "author": { "key": … } }`.
    private static func workAuthorKeys(_ value: Any?) -> [String] {
        guard let array = value as? [[String: Any]] else { return [] }
        return array.compactMap { ($0["author"] as? [String: Any])?["key"] as? String }.map(bareID)
    }

    /// Extracts valid cover/photo IDs, discarding the `-1` "no image" sentinel.
    private static func coverIDs(_ value: Any?) -> [Int] {
        guard let array = value as? [Any] else { return [] }
        return array.compactMap { intValue($0) }.filter { $0 > 0 }
    }

    /// Extracts the first four-digit year (1000–2999) from a free-text date.
    private static func year(from string: String?) -> Int? {
        guard let string else { return nil }
        for part in string.split(whereSeparator: { !$0.isNumber }) where part.count == 4 {
            if let value = Int(part), (1000...2999).contains(value) { return value }
        }
        return nil
    }

    /// Returns the string if it is a non-empty `String`, else `nil`.
    private static func nonEmpty(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return string
    }

    private static func stringArray(_ value: Any?) -> [String] {
        value as? [String] ?? []
    }

    /// An `Int` from an `Int`, `Double`, or numeric `String`.
    private static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double) }
        if let string = value as? String { return Int(string) }
        return nil
    }

    /// A strictly-positive `Int`, or `nil` (used to drop the `-1` cover sentinel).
    private static func positiveInt(_ value: Any?) -> Int? {
        guard let int = intValue(value), int > 0 else { return nil }
        return int
    }
}
