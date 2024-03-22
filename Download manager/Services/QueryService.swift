import Foundation
import SwiftUI

class QueryService {
    let defaultSession = URLSession(configuration: .default)
    var errorMessage = ""
    var files: [File] = []
    var dataTask: URLSessionDataTask?

    typealias JSONDictionary = [String: Any]
    typealias QueryResult = ([File]?, String) -> Void
    
    
    func download(fileUrl: String, completion: @escaping QueryResult) {
        dataTask?.cancel()
        if let url = URL(string: fileUrl) {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            
            dataTask = defaultSession.dataTask(with: request) { [weak self] data, response, error in
                defer {
                    self?.dataTask = nil
                }
                
                if let error = error {
                    self?.errorMessage += "DataTask error: " + error.localizedDescription + "\n"
                } else if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    self?.updateSearchResults(data, response, url)
                    DispatchQueue.main.async {
                        completion(self?.files, self?.errorMessage ?? "")
                    }
                } else {
                    print("We faced with data problem...")
                }
            }
        dataTask?.resume()
      }
  }
  
    private func updateSearchResults(_ data: Data, _ response: HTTPURLResponse, _ url: URL) {
        let index = files.count + 1
        let fileSize = response.allHeaderFields["Content-Length"] as? String ?? "Unknown size"
        let fileType = response.allHeaderFields["Content-Type"] as? String ?? "Unknown type"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let date = dateFormatter.string(from: Date())
        
        let fileName = response.suggestedFilename ?? url.lastPathComponent
        let mimeType = response.mimeType ?? "Unknown mime"
        let fileUrl = response.url ?? URL(string: "")

        files.append(File(id: UUID(), fileName: fileName, date: date, size: Int64(fileSize) ?? 0, previewURL: fileUrl!, fileMime: mimeType, fileType: fileType, fileIndex: index))
    }
}
