import Foundation
import Dispatch

class DownloadService: NSObject, ObservableObject, URLSessionDownloadDelegate {
    private var downloadsInternal: [UUID: Download] = [:]
    let queue = DispatchQueue(label: "com.example.myqueue", attributes: .concurrent)
    let configuration = URLSessionConfiguration.background(withIdentifier: "com.example.backgroundDownload")
    var urlSession: URLSession?
    var savePath: URL?
    @Published var downloadBoolTic = false
    let semaphore: DispatchSemaphore
    let maxConcurrentDownloads: Int
    var downloads: [UUID: Download] {
        get {
            return queue.sync {
                return downloadsInternal
            }
        }
        set {
            queue.async {
                self.downloadsInternal = newValue
            }
        }
    }
    
    
    override init() {
        maxConcurrentDownloads = ProcessInfo().processorCount
        semaphore = DispatchSemaphore(value: maxConcurrentDownloads)
        super.init()
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func isFileExist(destinationPath: String) -> Bool {
        return FileManager.default.fileExists(atPath: destinationPath)
    }
    
    func startDownload(_ file: File, saveURL: URL) {
        let download = Download()
        download.file = file
        download.saveURL = saveURL
        download.startTime = Date()
        download.downloadTask = urlSession?.downloadTask(with: file.previewURL)
        download.downloadTask?.resume()
        download.isDownloading = true
        download.downloadState = .start
        downloads[file.id] = download
    }
    
    func calculateSpeed(for downloadTask: URLSessionDownloadTask) -> Int64 {
        guard let download = downloads.first(where: { $0.value.downloadTask == downloadTask })?.value else {
            return 0
        }
        
        let bytesWritten = downloadTask.countOfBytesReceived
        let timeElapsed = Date().timeIntervalSince(download.startTime)
        let speed = Int64(Double(bytesWritten) / timeElapsed)
        return speed
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        guard let download = downloads.first(where: { $0.value.downloadTask == downloadTask })?.value else {
            return
        }
        guard let destinationURL = download.saveURL else {
            return
        }
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
        } catch {
            print("Error moving file: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            download.isDownloading = false
            download.downloadState = .alreadyDownloaded
            self.downloadBoolTic = !self.downloadBoolTic
        }
        if download.file.size == 0 {
            download.downloadProgress = 1
        }
        download.downloadSpeed = 0
        self.semaphore.signal()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let download = downloads.first(where: { $0.value.downloadTask == downloadTask })?.value else {
            return
        }
        
        if download.file.size == 0 {
            return
        }
        
        DispatchQueue.main.async {
            self.downloadBoolTic = !self.downloadBoolTic
            download.downloadProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            download.downloadSpeed = self.calculateSpeed(for: downloadTask)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed: \(error.localizedDescription)")
        }
    }
    
    func startQueueDownloads(_ file: File, saveURL: URL) {
        queue.async {
            self.semaphore.wait()
            self.startDownload(file, saveURL: saveURL)
        }
    }
}

enum DownloadState: Int, CustomStringConvertible {
    case none = 0
    case start
    case pause
    case resume
    case cancel
    case alreadyDownloaded
    
    var description: String {
        switch self {
        case .start:
            return "Download is started"
        case .resume:
            return "Download is resumed"
        case .pause:
            return "Download is paused"
        case .alreadyDownloaded:
            return "Download is finished"
        case .cancel:
            return "Download is canceled"
            
        default:
            return ""
        }
    }
}
