//
//  SettingsUpdateView.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/4/28.
//

import SwiftUI

struct SettingsUpdateView: View {
    @AppStorage("updateCheckFrequency") private var updateCheckFrequency: UpdateCheckFrequency = SettingsManager.updateCheckFrequency
    @StateObject private var updateManager = UpdateManager.shared
    
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
                            Text("设置自动检查更新的频率")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 检查更新频率设置
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "refresh")
                                .foregroundColor(.secondary)
                            Text("检查更新频率")
                                .font(.headline)
                        }
                        
                        // 单选按钮列表
                        VStack(spacing: 8) {
                            ForEach(UpdateCheckFrequency.allCases) { frequency in
                                Button(action: {
                                    updateCheckFrequency = frequency
                                }) {
                                    HStack(spacing: 12) {
                                        RadioButton(selected: updateCheckFrequency == frequency)
                                        Text(frequency.rawValue)
                                            .font(.body)
                                            .foregroundColor(updateCheckFrequency == frequency ? .primary : .secondary)
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(Color(.controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
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
                                Task {
                                    await updateManager.checkForUpdates(force: true)
                                }
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
                            .disabled(updateManager.isChecking)
                        }
                    }
                }
                
                // 更新可用提示
                if updateManager.updateAvailable, let latestVersion = updateManager.latestVersion {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.green)
                                Text("发现新版本")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("新版本 \(latestVersion) 已发布！")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                if updateManager.isDownloading {
                                    VStack(spacing: 8) {
                                        ProgressView(value: updateManager.downloadProgress)
                                            .progressViewStyle(.linear)
                                        Text("正在下载...")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Button(action: {
                                        updateManager.downloadUpdate { dmgURL, error in
                                            if let dmgURL = dmgURL {
                                                updateManager.installUpdate(from: dmgURL)
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "download")
                                            Text("下载并安装")
                                        }
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                // 当前已是最新版本提示
                if !updateManager.updateAvailable && !updateManager.isChecking && updateManager.latestVersion != nil {
                    SettingsCard {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                            Text("当前已是最新版本")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                await updateManager.checkForUpdates(force: false)
            }
        }
    }
}
