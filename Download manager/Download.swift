import Foundation

class Download: ObservableObject {
    private var isDownloadingBool: Bool = false
    private let isDownloadingQueue = DispatchQueue(label: "com.example.isDownloadingQueue")
    
    var file: File = File()
    var downloadState: DownloadState = .none
    var isDownloading: Bool {
        get {
            return isDownloadingQueue.sync {
                return isDownloadingBool
            }
        }
        set {
            isDownloadingQueue.async {
                self.isDownloadingBool = newValue
            }
        }
    }
    var resumeData: Data?
    var downloadTask: URLSessionDownloadTask?
    var startTime: Date = Date()
    var saveURL: URL?
    @Published var downloadProgress: Float = 0.0
    @Published var downloadSpeed: Int64 = 0
}
