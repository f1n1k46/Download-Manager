import Foundation
import SwiftUI

@available(macOS 12.0.0, *)
struct Response: Codable {
    var files: [File]
}

@available(macOS 12.0, *)
struct MainUIView: View {
    @State private var showingPopup = false
    @State private var name = ""
    @State private var files = [File]()
    @State var downloadPath = ""
    let queryService = QueryService()
    @ObservedObject var downloadService = DownloadService()
    let queue = DispatchQueue(label: "com.example.myqueue", attributes: .concurrent)
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    Rectangle()
                        .foregroundColor(.clear)

                    Button(action: {
                        showingPopup = true
                    }, label: {
                        Label("Add file...", systemImage: "doc.fill.badge.plus")
                    })
                    .buttonStyle(MyButtonStyle())
                    .popover(isPresented: $showingPopup) {
                        VStack {
                            HStack {
                                Text("URL: ")
                                    .padding(.leading)
                                TextField("", text: $name)
                                    .padding(.trailing)
                            }
                            .padding(.top)

                            HStack {
                                Button(action: {
                                    downloadPath = name
                                    name = ""
                                    loadData(downloadURL: downloadPath)
                                }, label: {
                                    Label("Add", systemImage: "plus.rectangle.fill.on.rectangle.fill")
                                })
                                .buttonStyle(.automatic)
                                .padding()
                            }
                        }
                        .frame(width: 500, height: 100)
                    }
                }
                .frame(height: geometry.size.height * 0.1,alignment: .leading)
                
                Divider()
                    .frame(height: 2)

                ZStack {
                    Rectangle()
                        .foregroundColor(.clear)
                        
                    List(files, id: \.fileIndex) { item in
                        HStack {
                            VStack {
                                Text(item.fileName)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)

                            VStack {
                                Text(item.fileType)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)

                            VStack {
                                Text(item.date)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)

                            VStack {
                                Text(getFileSize(size: item.size))
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)

                            VStack {
                                Text("\(getFileSize(size: downloadService.downloads[item.id]?.downloadSpeed ?? 0))")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)

                            Button(action: {
                                guard let savePath = showSavePanel(fileName: item.fileName) else {
                                    return
                                }
                                downloadService.startQueueDownloads(item, saveURL: savePath)
                            }, label: {
                                Label("Download", systemImage: "arrow.down.app")
                            })
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)

                            HStack {
                                if ((downloadService.downloads[item.id]?.isDownloading) != nil) {
                                    ProgressView(value: downloadService.downloads[item.id]?.downloadProgress ?? 0.0)
                                        .foregroundColor(.red)
                                        .animation(.linear)
                                    Text("\(Int(((downloadService.downloads[item.id]?.downloadProgress ?? 0.0) * 100)))%")
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            
                        }
                    }
                }
                .frame(height: geometry.size.height * 0.9)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func loadData(downloadURL: String) {
        Task {
            queryService.download(fileUrl: downloadURL) { results, errorMessage in
                if let results = results {
                    files = results
                }
                
                if !errorMessage.isEmpty {
                    print("Search error: " + errorMessage)
                }
            }
        }
    }
}

private func getFileSize(size: Int64) -> String {
    if size == 0 {
        return "0 kb"
    }
    
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
    formatter.countStyle = .file
    
    let fileSizeString = formatter.string(fromByteCount: size)
    return fileSizeString
}

private func showSavePanel(fileName: String) -> URL? {
    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = fileName
    savePanel.canCreateDirectories = true
    savePanel.isExtensionHidden = false
    savePanel.allowsOtherFileTypes = false
    savePanel.title = "Save directory"
    savePanel.message = "Choose a folder and a name to store your file"
    savePanel.nameFieldLabel = "File name:"
    let response = savePanel.runModal()
    return response == .OK ? savePanel.url : nil
}

struct MyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule(style: .continuous))
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
    }
}
