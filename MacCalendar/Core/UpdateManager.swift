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
                    let version = (tagName.hasPrefix("v") || tagName.hasPrefix("V")) ? String(tagName.dropFirst()) : tagName
                    
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
            guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw URLError(.cannotCreateFile)
            }
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

    /// 挂载 DMG → 暂存 → 校验 → 生成后台安装脚本，App 退出后由脚本完成替换并重启；失败回退手动流程
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
            let result = self.performAutoInstall(dmgPath: dmgPathStr)
            DispatchQueue.main.async {
                completion(result.success, result.message)
            }
        }
    }
    
    private struct AutoInstallResult {
        let success: Bool
        let message: String?
    }
    
    /// 执行自动安装的前置流程。返回后 App 即可退出（或已回退手动流程）。
    private func performAutoInstall(dmgPath: String) -> AutoInstallResult {
        let fm = FileManager.default
        let pid = ProcessInfo.processInfo.processIdentifier
        
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return AutoInstallResult(success: false, message: "无法定位应用支持目录")
        }
        let stagingRoot = appSupport.appendingPathComponent("MacCalendar/Update", isDirectory: true)
        let mountRoot = stagingRoot.appendingPathComponent("mnt", isDirectory: true)
        
        try? fm.removeItem(at: stagingRoot)
        do {
            try fm.createDirectory(at: mountRoot, withIntermediateDirectories: true)
        } catch {
            return AutoInstallResult(success: false, message: "无法创建暂存目录: \(error.localizedDescription)")
        }
        
        let attach = runProcess("/usr/bin/hdiutil", ["attach", dmgPath, "-nobrowse", "-noverify", "-mountRoot", mountRoot.path])
        guard attach.status == 0 else {
            return AutoInstallResult(success: false, message: "挂载失败: \(attach.errOutput.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        
        guard let volumeDir = try? fm.contentsOfDirectory(at: mountRoot, includingPropertiesForKeys: nil).first,
              let sourceApp = try? fm.contentsOfDirectory(at: volumeDir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) else {
            _ = runProcess("/usr/bin/hdiutil", ["detach", mountRoot.path, "-force"])
            return AutoInstallResult(success: false, message: "安装包内未找到应用程序")
        }
        
        let stagedApp = stagingRoot.appendingPathComponent("MacCalendar.app")
        let ditto = runProcess("/usr/bin/ditto", [sourceApp.path, stagedApp.path])
        guard ditto.status == 0, fm.fileExists(atPath: stagedApp.path) else {
            _ = runProcess("/usr/bin/hdiutil", ["detach", mountRoot.path, "-force"])
            return AutoInstallResult(success: false, message: "拷贝新版本失败")
        }
        
        guard let bundle = Bundle(path: stagedApp.path),
              let executable = bundle.infoDictionary?["CFBundleExecutable"] as? String,
              fm.fileExists(atPath: stagedApp.appendingPathComponent("Contents/MacOS/\(executable)").path),
              let newVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String else {
            _ = runProcess("/usr/bin/hdiutil", ["detach", mountRoot.path, "-force"])
            try? fm.removeItem(at: stagedApp)
            return AutoInstallResult(success: false, message: "安装包校验失败，已取消自动安装")
        }
        
        _ = runProcess("/usr/bin/hdiutil", ["detach", volumeDir.path, "-force"])
        
        let destination = Bundle.main.bundleURL.path
        let destinationParent = (destination as NSString).deletingLastPathComponent
        guard fm.isWritableFile(atPath: destinationParent) else {
            _ = runProcess("/usr/bin/open", [stagingRoot.path])
            return AutoInstallResult(success: true, message: "已打开安装包，请手动将 MacCalendar 拖动到应用程序文件夹完成替换")
        }
        
        let logPath = stagingRoot.appendingPathComponent("install.log").path
        let scriptPath = stagingRoot.appendingPathComponent("install-update.sh").path
        let script = """
        #!/bin/sh
        # MacCalendar 自动更新辅助脚本（由 App 生成；App 退出后由 launchd 接管继续执行）
        # 参数: $1=旧App PID  $2=暂存的新App  $3=目标安装路径  $4=日志文件  $5=DMG 挂载点
        set -u
        PID="$1"
        STAGED_APP="$2"
        DEST="$3"
        LOG="$4"
        MOUNT_POINT="$5"
        
        log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG" 2>/dev/null || true; }
        
        # 1. 等待旧 App 完全退出（最多 2 分钟，超时也继续）
        COUNT=0
        while kill -0 "$PID" 2>/dev/null && [ "$COUNT" -lt 600 ]; do
            sleep 0.2
            COUNT=$((COUNT + 1))
        done
        log "旧进程已退出"
        
        # 2. 暂存的新 App 必须完好
        if [ ! -d "$STAGED_APP" ]; then
            log "暂存的新版本不存在，放弃自动安装"
            exit 1
        fi
        log "暂存校验通过"
        
        # 3. 先拷贝到 .new 再整体替换：任何一步失败都保留旧版本，不会变砖
        NEW_APP="${DEST}.new"
        rm -rf "$NEW_APP"
        if ! ditto "$STAGED_APP" "$NEW_APP"; then
            log "拷贝新版本失败"
            rm -rf "$NEW_APP"
            exit 1
        fi
        rm -rf "$DEST"
        if ! mv "$NEW_APP" "$DEST"; then
            log "替换失败，尝试恢复"
            [ -d "$NEW_APP" ] && mv "$NEW_APP" "$DEST"
            exit 1
        fi
        log "替换完成"
        
        # 4. 结束旧版 Widget 扩展进程：bundle 刚被整体替换，不重启会继续由持有旧代码（旧数据）的僵住进程渲染桌面组件
        pkill -f "MacCalendarWidgetExtension.appex" 2>/dev/null || true
        sleep 1
        pkill -9 -f "MacCalendarWidgetExtension.appex" 2>/dev/null || true
        log "已结束旧版 Widget 扩展进程"
        
        # 5. 清除隔离属性，避免 Gatekeeper 拦截自动更新的新版本
        xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
        
        # 6. 重启新版本
        open "$DEST"
        log "已启动新版本"
        
        # 7. 清理：卸载可能残留的 DMG 挂载，删除暂存目录
        [ -n "$MOUNT_POINT" ] && hdiutil detach "$MOUNT_POINT" -force 2>/dev/null || true
        rm -rf "$(dirname "$STAGED_APP")"
        log "安装完成"
        exit 0
        """
        
        guard fm.createFile(atPath: scriptPath, contents: script.data(using: .utf8)) else {
            _ = runProcess("/usr/bin/open", [stagingRoot.path])
            return AutoInstallResult(success: true, message: "已打开安装包，请手动将 MacCalendar 拖动到应用程序文件夹完成替换")
        }
        
        let helper = Process()
        helper.launchPath = "/bin/sh"
        helper.arguments = [scriptPath, String(pid), stagedApp.path, destination, logPath, volumeDir.path]
        do {
            try helper.run()
        } catch {
            _ = runProcess("/usr/bin/open", [stagingRoot.path])
            return AutoInstallResult(success: true, message: "已打开安装包，请手动将 MacCalendar 拖动到应用程序文件夹完成替换")
        }
        
        return AutoInstallResult(success: true, message: "正在安装更新 \(newVersion)，应用将自动重启")
    }
    
    /// 同步执行外部命令并收集输出（会阻塞当前线程，须在非主线程调用）
    private func runProcess(_ launchPath: String, _ arguments: [String]) -> (status: Int32, output: String, errOutput: String) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let errOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return (task.terminationStatus, output, errOutput)
        } catch {
            return (-1, "", error.localizedDescription)
        }
    }
}