//
//  SettingsUpdateView.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/4/28.
//

import SwiftUI

enum UpdateAlertType {
    case checking
    case noUpdate
    case updateAvailable(String)
    case downloading
    case downloadComplete
    case error(String)
}

struct SettingsUpdateView: View {
    private var updateManager: UpdateManager { UpdateManager.shared }
    @State private var showAlert = false
    @State private var alertType: UpdateAlertType = .checking
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 标题和描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("检查更新")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("检查应用更新")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 手动检查更新按钮
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "search")
                                .foregroundColor(.secondary)
                            Text("检查更新")
                                .font(.headline)
                        }
                        
                        HStack {
                            Text("当前版本: \(Bundle.main.appVersion ?? "1.0.0")")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                checkForUpdates()
                            }) {
                                if updateManager.isChecking {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("检查更新")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(updateManager.isChecking || updateManager.isDownloading)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAlert) {
            UpdateAlertView(
                updateManager: updateManager,
                type: alertType,
                onAction: handleAlertAction,
                onDismiss: { showAlert = false }
            )
        }
    }
    
    private func handleAlertAction() {
        switch alertType {
        case .updateAvailable:
            downloadAndInstallUpdate()
        case .downloadComplete, .error, .noUpdate:
            showAlert = false
        default:
            break
        }
    }
    
    private func checkForUpdates() {
        alertType = .checking
        showAlert = true
        
        Task {
            await updateManager.checkForUpdates()
            
            await MainActor.run {
                if updateManager.updateAvailable, let version = updateManager.latestVersion {
                    alertType = .updateAvailable(version)
                } else if let error = updateManager.downloadError {
                    alertType = .error(error)
                } else {
                    alertType = .noUpdate
                }
            }
        }
    }
    
    private func downloadAndInstallUpdate() {
        alertType = .downloading
        updateManager.downloadUpdate { dmgURL, error in
            DispatchQueue.main.async {
                if let dmgURL = dmgURL {
                    self.alertType = .downloadComplete
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.installUpdate(from: dmgURL)
                    }
                } else if let error = error {
                    self.alertType = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func installUpdate(from dmgURL: URL) {
        updateManager.installUpdate(from: dmgURL) { success, errorMessage in
            DispatchQueue.main.async {
                if !success {
                    self.alertType = .error(errorMessage ?? "安装失败")
                }
            }
        }
    }
}