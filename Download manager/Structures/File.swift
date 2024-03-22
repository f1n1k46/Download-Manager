import Foundation

struct File: Codable {
    var id: UUID = UUID()
    var fileName: String = ""
    var date: String = ""
    var size: Int64 = 0
    var previewURL: URL = URL(fileURLWithPath: "")
    var fileMime: String = ""
    var fileType: String = ""
    var fileIndex: Int = 0

    init() {}
    
    init(id: UUID, fileName: String, date: String, size: Int64, previewURL: URL, fileMime: String, fileType: String, fileIndex: Int) {
        self.id = id
        self.fileName = fileName
        self.date = date
        self.size = size
        self.previewURL = previewURL
        self.fileName = fileName
        self.fileMime = fileMime
        self.fileType = fileType
        self.fileIndex = fileIndex
    }
}
