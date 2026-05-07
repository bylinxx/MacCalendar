//
//  UpdateManager.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/4/28.
//

import Foundation
import Combine

class UpdateManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = UpdateManager()

    private let githubRepoURL = "https://api.github.com/repos/bylinxx/MacCalendar/releases/latest"
    
    private var currentVersion: String {
        Bundle.main.appVersion ?? "1.0.0"
    }

    @Published var isChecking = false
    @Published var isDownloading = false
    @Published var downloadProgress = 0.0
    @Published var latestVersion: String?
    @Published var updateAvailable = false
    @Published var downloadURL: URL?
    @Published var downloadedFileURL: URL?  // 新增：保存下载后的本地文件路径
    @Published var downloadError: String?

    private var downloadCompletion: ((URL?, Error?) -> Void)?
    private var pendingDownloadURL: URL?
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    private override init() {
        super.init()
    }

    func checkForUpdates() async {
        guard !isChecking else { return }

        await MainActor.run {
            isChecking = true
            updateAvailable = false
            downloadURL = nil
            downloadedFileURL = nil
            latestVersion = nil
            downloadError = nil
        }

        defer {
            Task { @MainActor in
                isChecking = false
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: URL(string: githubRepoURL)!)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                await MainActor.run {
                    downloadError = "网络请求失败，状态码: \(httpResponse.statusCode)"
                }
                return
            }
            
            if let release = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let message = release["message"] as? String {
                    await MainActor.run {
                        downloadError = message
                    }
                    return
                }
                
                if let tagName = release["tag_name"] as? String {
                    let version = tagName.replacingOccurrences(of: "v", with: "")
                    
                    await MainActor.run {
                        latestVersion = version
                    }

                    let comparisonResult = compareVersions(currentVersion, version)
                    
                    if comparisonResult == .orderedAscending {
                        await MainActor.run {
                            updateAvailable = true
                        }
                        if let assets = release["assets"] as? [[String: Any]] {
                            for asset in assets {
                                if let downloadUrl = asset["browser_download_url"] as? String,
                                   downloadUrl.hasSuffix(".dmg") {
                                    await MainActor.run {
                                        self.downloadURL = URL(string: downloadUrl)
                                    }
                                    break
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                downloadError = error.localizedDescription
            }
        }
    }

    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let components1 = v1.components(separatedBy: ".").compactMap { Int($0) }
        let components2 = v2.components(separatedBy: ".").compactMap { Int($0) }

        for i in 0..<max(components1.count, components2.count) {
            let c1 = i < components1.count ? components1[i] : 0
            let c2 = i < components2.count ? components2[i] : 0

            if c1 < c2 { return .orderedAscending }
            if c1 > c2 { return .orderedDescending }
        }

        return .orderedSame
    }

    func downloadUpdate(completion: @escaping (URL?, Error?) -> Void) {
        guard let url = downloadURL, !isDownloading else {
            completion(nil, NSError(domain: "UpdateManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No download URL available"]))
            return
        }

        downloadCompletion = completion
        pendingDownloadURL = url
        isDownloading = true
        downloadProgress = 0.0
        downloadError = nil

        let task = downloadSession.downloadTask(with: url)
        task.resume()
    }

    func cancelDownload() {
        downloadSession.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        isDownloading = false
        downloadProgress = 0.0
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempURL = location

        do {
            let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupportDir.appendingPathComponent("MacCalendar")
            
            if !FileManager.default.fileExists(atPath: appDir.path) {
                try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
            }
            
            let destinationURL = appDir.appendingPathComponent("MacCalendar.dmg")

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.moveItem(at: tempURL, to: destinationURL)

            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadProgress = 1.0
                self.downloadedFileURL = destinationURL  // 保存本地文件路径
                self.downloadCompletion?(destinationURL, nil)
            }
        } catch {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadCompletion?(nil, error)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadProgress = progress
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadError = error.localizedDescription
                self.downloadCompletion?(nil, error)
            }
        }
    }

    func installUpdate(from dmgURL: URL, completion: @escaping (Bool, String?) -> Void) {
        let dmgPathStr = dmgURL.path
        
        guard FileManager.default.fileExists(atPath: dmgPathStr) else {
            completion(false, "下载的文件不存在")
            return
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: dmgPathStr)
            if let fileSize = attributes[.size] as? Int64 {
                if fileSize < 1024 {
                    completion(false, "下载的文件不完整，大小: \(fileSize) 字节")
                    return
                }
            }
        } catch {
            completion(false, "无法获取文件信息: \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/usr/bin/hdiutil"
            task.arguments = ["attach", dmgPathStr, "-nobrowse", "-noverify"]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                
                if task.terminationStatus == 0 {
                    var mountPoint: String?
                    for line in output.components(separatedBy: .newlines) {
                        if let range = line.range(of: "/Volumes/") {
                            mountPoint = String(line[range.lowerBound...])
                            break
                        }
                    }
                    
                    Thread.sleep(forTimeInterval: 0.5)
                    
                    if let mp = mountPoint {
                        let openTask = Process()
                        openTask.launchPath = "/usr/bin/open"
                        openTask.arguments = [mp]
                        try? openTask.run()
                        openTask.waitUntilExit()
                    } else {
                        let openTask = Process()
                        openTask.launchPath = "/usr/bin/open"
                        openTask.arguments = ["/Volumes"]
                        try? openTask.run()
                        openTask.waitUntilExit()
                    }
                    
                    DispatchQueue.main.async {
                        completion(true, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "挂载失败: exitCode=\(task.terminationStatus), error=\(errorOutput)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "执行挂载命令失败: \(error.localizedDescription)")
                }
            }
        }
    }
}