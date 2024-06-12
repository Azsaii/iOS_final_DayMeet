import Foundation

struct Post: Codable {
    var authorId: String
    var authorName: String
    var timestamp: Int
    var title: String
    var content: String
    var year: Int
    var week: Int
}
