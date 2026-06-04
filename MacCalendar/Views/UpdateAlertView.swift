//
//  UpdateAlertView.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/5/6.
//

import SwiftUI

struct UpdateAlertView: View {
    @ObservedObject var updateManager: UpdateManager
    let type: UpdateAlertType
    let onAction: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
            
            // Title
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Progress bar for downloading
            if case .downloading = type {
                VStack(spacing: 8) {
                    ProgressView(value: updateManager.downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 280)
                    Text(String(format: "进度: %.1f%%", updateManager.downloadProgress * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }    
            
            // Actions
            HStack(spacing: 12) {
                if showCancelButton {
                    Button("取消") {
                        if updateManager.isDownloading {
                            updateManager.cancelDownload()
                        }
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                }
                
                if showActionButton {
                    Button(actionTitle) {
                        if case .downloadComplete = type {
                            onDismiss()
                            exit(0)
                        } else {
                            onAction()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(32)
        .frame(width: 320)
    }
    
    private var iconName: String {
        switch type {
        case .checking: return "search"
        case .noUpdate: return "checkmark.circle"
        case .updateAvailable: return "sparkles"
        case .downloading: return "download"
        case .downloadComplete: return "checkmark.circle"
        case .error: return "xmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .checking: return .blue
        case .noUpdate: return .green
        case .updateAvailable: return .green
        case .downloading: return .blue
        case .downloadComplete: return .green
        case .error: return .red
        }
    }
    
    private var title: String {
        switch type {
        case .checking: return "检查更新中..."
        case .noUpdate: return "已是最新版本"
        case .updateAvailable(let version): return "发现新版本 \(version)"
        case .downloading: return "正在下载..."
        case .downloadComplete: return "下载完成"
        case .error: return "错误"
        }
    }
    
    private var message: String {
        switch type {
        case .checking: return "正在检查是否有新版本可用..."
        case .noUpdate: return "当前版本已是最新，无需更新。"
        case .updateAvailable: return "新版本已发布，点击下方按钮下载并安装更新。"
        case .downloading: return "请稍候，正在下载更新包..."
        case .downloadComplete: return "更新包已下载完成，请退出当前App再将新版本App拖放到 Applications 文件夹内替换完成安装。"
        case .error(let error): return error
        }
    }
    
    private var showCancelButton: Bool {
        switch type {
        case .checking, .updateAvailable, .downloadComplete, .noUpdate,.error: return false
        default: return true
        }
    }
    
    private var showActionButton: Bool {
        switch type {
        case .checking: return false
        case .updateAvailable: return true
        case .downloading: return false
        case .downloadComplete: return true
        case .error: return true
        case .noUpdate: return true
        }
    }
    
    private var actionTitle: String {
        switch type {
        case .updateAvailable: return "下载并安装"
        case .downloadComplete: return "关闭"
        case .error: return "确定"
        case .noUpdate: return "确定"
        default: return "确定"
        }
    }
}
