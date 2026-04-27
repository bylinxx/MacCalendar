//
//  SettingsLaunchAtLoginView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

struct SettingsLaunchAtLoginView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = SettingsManager.launchAtLogin
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 标题和描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "gear")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("启动项设置")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("配置应用的启动行为")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 开机启动设置
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "switch")
                                .foregroundColor(.secondary)
                            Text("开机时自动启动")
                                .font(.headline)
                        }
                        HStack {
                            Text("启用后，应用将在系统启动时自动运行")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("", isOn: $launchAtLogin)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
