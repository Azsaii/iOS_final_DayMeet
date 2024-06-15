import Foundation

struct Post: Codable {
    var authorId: String
    var authorName: String
    var content: String
    var day: Int
    var isPublic: Bool
    var month: Int
    var timestamp: Int
    var title: String
    var year: Int
}
