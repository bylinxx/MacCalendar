//
//  SettingsUpdateView.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/4/28.
//


import SwiftUI
import AppKit

enum UpdateStatus {
    case idle
    case checking
    case noUpdate
    case downloading
    case downloadComplete
    case error(String)
}

struct SettingsUpdateView: View {
    @ObservedObject private var updateManager = UpdateManager.shared
    @State private var updateStatus: UpdateStatus = .idle
    @State private var statusMessage: String = ""
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("当前版本")
                    Spacer()
                    Text(Bundle.main.appVersion ?? "1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("检查更新")
                    Spacer()
                    Button(action: {
                        checkForUpdates()
                    }) {
                        if updateManager.isChecking {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("检查更新")
                        }
                    }
                    .disabled(updateManager.isChecking || updateManager.isDownloading)
                }
            }
            
            Section {
                Group {
                    switch updateStatus {
                    case .idle:
                        EmptyView()
                    case .downloading:
                        HStack(spacing: 12) {
                            Text("下载中")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: updateManager.downloadProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                            
                            Text(String(format: "%.1f%%", updateManager.downloadProgress * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)
                            
                            Button(action: {
                                cancelDownload()
                            }) {
                                Text("取消")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(8)
                    default:
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: statusIcon)
                                .font(.system(size: 24))
                                .foregroundColor(statusColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(statusTitle)
                                    .font(.headline)
                                
                                if !statusMessage.isEmpty {
                                    Text(statusMessage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(16)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var statusIcon: String {
        switch updateStatus {
        case .idle: return "info.circle"
        case .checking: return "magnifyingglass"
        case .noUpdate: return "checkmark.circle"
        case .downloading: return "arrow.down.circle"
        case .downloadComplete: return "checkmark.circle"
        case .error: return "xmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch updateStatus {
        case .idle: return .secondary
        case .checking: return .blue
        case .noUpdate: return .green
        case .downloading: return .blue
        case .downloadComplete: return .green
        case .error: return .red
        }
    }
    
    private var statusTitle: String {
        switch updateStatus {
        case .idle: return "点击上方按钮检查更新"
        case .checking: return "检查更新中..."
        case .noUpdate: return "已经是最新版本"
        case .downloading: return "正在下载..."
        case .downloadComplete: return "正在安装"
        case .error(let error): return "错误: \(error)"
        }
    }
    
    private func checkForUpdates() {
        updateStatus = .checking
        statusMessage = ""
        
        Task {
            await updateManager.checkForUpdates()
            
            await MainActor.run {
                if updateManager.updateAvailable {
                    downloadAndInstallUpdate()
                } else if let error = updateManager.downloadError {
                    updateStatus = .error(error)
                } else {
                    updateStatus = .noUpdate
                }
            }
        }
    }
    
    private func downloadAndInstallUpdate() {
        updateStatus = .downloading
        statusMessage = "请稍候，正在下载更新包..."
        
        updateManager.downloadUpdate { dmgURL, error in
            DispatchQueue.main.async {
                if let dmgURL = dmgURL {
                    self.updateStatus = .downloadComplete
                    self.statusMessage = "正在安装更新，应用将自动重启..."
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.installUpdate(from: dmgURL)
                    }
                } else if let error = error {
                    self.updateStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func installUpdate(from dmgURL: URL) {
        updateManager.installUpdate(from: dmgURL) { success, errorMessage in
            DispatchQueue.main.async {
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NSApplication.shared.terminate(nil)
                    }
                } else {
                    self.updateStatus = .error(errorMessage ?? "挂载失败")
                }
            }
        }
    }
    
    private func cancelDownload() {
        updateManager.cancelDownload()
        updateStatus = .idle
        statusMessage = ""
    }
}
