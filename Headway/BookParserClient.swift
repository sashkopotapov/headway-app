import ComposableArchitecture
import Foundation

struct BookParserClient: Sendable {
    var loadBook: @Sendable (String) async throws -> Book
}

extension BookParserClient: DependencyKey {
    static var liveValue: Self {
        let parser = BookParser()
        return Self(
            loadBook: { filename in
                try await parser.loadBook(from: filename)
            }
        )
    }
}

extension DependencyValues {
    var parserClient: BookParserClient {
        get { self[BookParserClient.self] }
        set { self[BookParserClient.self] = newValue }
    }
}

private actor BookParser {
    private let decoder: JSONDecoder
    private var cache: [String: Book]

    fileprivate init() {
        decoder = JSONDecoder()
        cache = [:]
    }

    func loadBook(from filename: String) async throws -> Book {
        if let cachedBook = cache[filename] {
            return cachedBook
        }

        // Use a detached task to cache the result even if the parent task is cancelled.
        let book: Book = try await Task.detached(priority: .userInitiated) {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json")
            else { throw BookParserError.fileNotFound }

            do {
                let data = try Data(contentsOf: url)
                return try self.decoder.decode(Book.self, from: data)
            } catch let error as DecodingError {
                throw BookParserError.decodingError(error)
            } catch {
                throw BookParserError.invalidData
            }
        }
        .value

        cache[filename] = book
        return book
    }
}

enum BookParserError: Error {
    case fileNotFound
    case invalidData
    case decodingError(Error)
}
