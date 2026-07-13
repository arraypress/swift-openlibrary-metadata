# Swift Open Library Metadata

A Swift library for fetching book metadata from [Open Library](https://openlibrary.org) — search the catalogue, look up editions by ISBN, and read works and authors. No API key or authentication required — every endpoint used is part of Open Library's free, keyless data API.

## Features

- 🔎 **Search** — `search(_:)` across titles and authors, one `OLBook` per matching work, with pagination
- 📖 **ISBN lookup** — `book(isbn:)` resolves a specific edition (and its author names) from a 10- or 13-digit ISBN
- 📚 **Works & authors** — `work(_:)` and `author(_:)` for descriptions, subjects, biographies, and dates
- 🖼️ **Cover art** — computed `coverURL` plus a `coverURL(size:)` helper (small / medium / large) for covers and author photos
- 🔀 **Flexible identifiers** — accepts bare IDs (`"OL45804W"`) or full key paths (`"/works/OL45804W"`)
- 🧩 **Forgiving parsing** — handles Open Library fields that are sometimes a string and sometimes a `{ value }` object (descriptions, bios)
- 🔒 **No API key required** — public `openlibrary.org` endpoints
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS
- ⚡ **Async/await** native
- 🛡️ **Typed error handling**

## Requirements

- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 6.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-openlibrary-metadata.git", from: "1.0.0")
]
```

## Usage

### Search

Returns one `OLBook` per matching *work* (all editions aggregated), each with an
`editionCount` and a representative cover.

```swift
import OpenLibraryMetadata

let results = try await OpenLibraryMetadata.search("the hobbit", limit: 5)
print("\(results.numFound) works match")
for book in results.books {
    print("\(book.title) — \(book.authors.joined(separator: ", ")) (\(book.firstPublishYear ?? 0))")
    if let cover = book.coverURL(size: .medium) { print(cover) }
}
if results.hasMore {
    let next = try await OpenLibraryMetadata.search("the hobbit", limit: 5, page: 2)
    // …
}
```

### ISBN lookup

Resolves a specific edition. Editions store authors as identifiers rather than
names, so the author display names are resolved for you on a best-effort basis.

```swift
let book = try await OpenLibraryMetadata.book(isbn: "9780140328721")
print("\(book.title) — \(book.authors.joined(separator: ", "))")   // Fantastic Mr. Fox — Roald Dahl
print(book.coverURL?.absoluteString ?? "")
print(book.pageCount ?? 0)
```

### Work

The canonical entry grouping every edition of a book.

```swift
let work = try await OpenLibraryMetadata.work("OL45804W")   // or "/works/OL45804W"
print(work.title)
print(work.description ?? "")
print(work.subjects.prefix(5).joined(separator: ", "))
```

### Author

```swift
let author = try await OpenLibraryMetadata.author("OL34184A")
print("\(author.name) (\(author.birthDate ?? "?") – \(author.deathDate ?? "?"))")
print(author.bio ?? "")
if let photo = author.photoURL(size: .medium) { print(photo) }
```

### Composing lookups

The models carry identifiers, so you can drill from an ISBN down to the work and
its authors:

```swift
let book = try await OpenLibraryMetadata.book(isbn: "9780140328721")
if let workKey = book.workKey {
    let work = try await OpenLibraryMetadata.work(workKey)
    for key in work.authorKeys {
        let author = try await OpenLibraryMetadata.author(key)
        print(author.name)
    }
}
```

### Cover images

Cover art is served from `covers.openlibrary.org` at three sizes. `coverURL` is
the large image; `coverURL(size:)` picks a size.

```swift
book.coverURL                     // …/b/id/15152634-L.jpg
book.coverURL(size: .small)       // …/b/id/15152634-S.jpg
author.photoURL(size: .medium)    // …/a/id/9395323-M.jpg
```

### User-Agent

Open Library asks callers to send a descriptive `User-Agent`. A default is
provided; override it (or set `OPENLIBRARY_USER_AGENT`) to identify your app:

```swift
let config = OpenLibraryMetadata.Configuration(userAgent: "MyApp/2.1 (contact@example.com)")
let results = try await OpenLibraryMetadata.search("dune", configuration: config)
```

### Error handling

```swift
do {
    let book = try await OpenLibraryMetadata.book(isbn: isbn)
} catch OpenLibraryMetadataError.notFound {
    print("No edition with that ISBN")
} catch {
    print(error.localizedDescription)
}
```

## Models

| Type | Kind | Description |
|------|------|-------------|
| `OLBook` | struct | `key`, `title`, `authors`, `authorKeys`, `firstPublishYear`, `isbns`, `coverID`, `editionCount`, `subjects`, `publishers`, `languages`, `pageCount`, `workKey`, plus `coverURL` / `coverURL(size:)` |
| `OLSearchResults` | struct | `books`, `query`, `numFound`, `start`, plus `hasMore` |
| `OLWork` | struct | `key`, `title`, `description`, `subjects`, `coverIDs`, `firstPublishDate`, `authorKeys`, plus `coverURL` / `coverURL(size:)` |
| `OLAuthor` | struct | `key`, `name`, `birthDate`, `deathDate`, `bio`, `alternateNames`, `photoID`, plus `photoURL` / `photoURL(size:)` |
| `OLCoverSize` | enum | `.small` / `.medium` / `.large` |
| `OpenLibraryMetadataError` | enum | Typed errors with `errorDescription` |

## How It Works

Open Library exposes book data as JSON without a key: `/search.json` for the
catalogue, `/isbn/{isbn}.json` for editions (which redirects to
`/books/{id}.json`), `/works/{id}.json`, and `/authors/{id}.json`. This library
requests those endpoints, normalises the loosely-typed responses (fields that are
sometimes a string and sometimes a `{ value }` object, `-1` "no cover"
sentinels, key paths vs. bare IDs), and returns typed models. Cover artwork is
built as `covers.openlibrary.org` URLs from the relevant image IDs.

## Testing

```bash
swift test                          # offline unit tests (fixtures)
OPENLIBRARY_LIVE_TESTS=1 swift test # also run the live network tests
```

Add `OPENLIBRARY_PRINT=1` to print the resolved books, works, and authors from
the live tests.

## License

MIT

## Author

David Sherlock
