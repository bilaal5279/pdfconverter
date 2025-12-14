import Foundation
import SwiftData

@Model
final class ScannedDocument {
    var id: UUID
    var creationDate: Date
    var title: String
    var pagePaths: [String] // Stores relative paths to images on disk
    
    init(id: UUID = UUID(), creationDate: Date = Date(), title: String, pagePaths: [String] = []) {
        self.id = id
        self.creationDate = creationDate
        self.title = title
        self.pagePaths = pagePaths
    }
    
    var pageCount: Int {
        pagePaths.count
    }
}
