//
//  UpdateManager.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/4/28.
//

import Foundation
import Combine

class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    private let githubRepoURL = "https://api.github.com/repos/ruihelin/MacCalendar/releases/latest"
    private let lastCheckDateKey = "LastUpdateCheckDate"
    private let currentVersion = Bundle.main.appVersion ?? "1.0.0"
    
    @Published var isChecking = false
    @Published var isDownloading = false
    @Published var downloadProgress = 0.0
    @Published var latestVersion: String?
    @Published var updateAvailable = false
    @Published var downloadURL: URL?
    
    private init() {}
    
    func checkForUpdates(force: Bool = false) async {
        guard !isChecking else { return }
        
        let shouldCheck = await shouldPerformCheck()
        if !force && !shouldCheck {
            return
        }
        
        isChecking = true
        defer { isChecking = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: githubRepoURL)!)
            if let release = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let tagName = release["tag_name"] as? String {
                
                let version = tagName.replacingOccurrences(of: "v", with: "")
                latestVersion = version
                
                if compareVersions(version, currentVersion) == .orderedDescending {
                    updateAvailable = true
                    if let assets = release["assets"] as? [[String: Any]] {
                        // 查找DMG文件
                        for asset in assets {
                            if let downloadUrl = asset["browser_download_url"] as? String,
                               downloadUrl.hasSuffix(".dmg") {
                                downloadURL = URL(string: downloadUrl)
                                break
                            }
                        }
                    }
                } else {
                    updateAvailable = false
                }
            }
            
            UserDefaults.standard.set(Date(), forKey: lastCheckDateKey)
        } catch {
            print("Failed to check for updates: \(error)")
        }
    }
    
    private func shouldPerformCheck() async -> Bool {
        let frequency = SettingsManager.updateCheckFrequency
        if frequency == .off {
            return false
        }
        
        guard let lastCheck = UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date else {
            return true
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastCheck)
        
        switch frequency {
        case .daily:
            return timeInterval > 24 * 60 * 60
        case .weekly:
            return timeInterval > 7 * 24 * 60 * 60
        case .off:
            return false
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
        
        isDownloading = true
        downloadProgress = 0.0
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let tempURL = tempURL else {
                    completion(nil, NSError(domain: "UpdateManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Download failed"]))
                    return
                }
                
                do {
                    let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                    let destinationURL = downloadsDir.appendingPathComponent("MacCalendar.dmg")
                    
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    completion(destinationURL, nil)
                } catch {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    func installUpdate(from dmgURL: URL) {
        let script = """
        tell application "Finder"
            mount volume POSIX file "\(dmgURL.path)"
            delay 2
            set sourceApp to POSIX path of (disk item "MacCalendar.app" of folder "MacCalendar" of disk "MacCalendar")
            set destApp to POSIX path of (application file "MacCalendar.app" of folder "Applications" of startup disk)
            do shell script "cp -Rf " & quoted form of sourceApp & " " & quoted form of destApp
            delay 1
            eject disk "MacCalendar"
            do shell script "open /Applications/MacCalendar.app"
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }
}
