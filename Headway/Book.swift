import Foundation

struct Book: Decodable, Hashable {
    let title: String
    let author: String
    let publishedIn: Int
    let chapters: [Chapter]
    let coverFileName: String

    enum CodingKeys: String, CodingKey {
        case title
        case author
        case publishedIn = "published_in"
        case chapters
        case coverFileName = "cover_file_name"
    }
}

struct Chapter: Decodable, Hashable {
    let chapterNumber: Int
    let title: String
    let keyPoint: String
    let audioFileName: String
    let duration: TimeInterval
    let content: String

    enum CodingKeys: String, CodingKey {
        case chapterNumber = "chapter_number"
        case title
        case keyPoint = "key_point"
        case audioFileName = "audio_file_name"
        case duration
        case content
    }
}
