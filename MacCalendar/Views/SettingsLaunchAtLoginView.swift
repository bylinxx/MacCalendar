//
//  SettingsLaunchAtLoginView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI
import AppKit
import ServiceManagement

struct SettingsLaunchAtLoginView: View {
    @State private var isEnabled = false
    @State private var requiresApproval = false

    var body: some View {
        Form {
            Section {
                Toggle("开机时自动启动", isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        LaunchAtLoginManager.setLaunchAtLogin(enabled: newValue)
                        refresh()
                    }
                ))

                if requiresApproval {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("系统已阻止该登录项，需在系统设置中允许")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("打开系统设置") {
                            LaunchAtLoginManager.openSystemSettingsLoginItems()
                        }
                        .controlSize(.small)
                    }
                }
            } footer: {
                Text("启用后，应用将在系统启动时自动运行")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
    }

    private func refresh() {
        let status = LaunchAtLoginManager.status
        isEnabled = status == .enabled
        requiresApproval = status == .requiresApproval
        SettingsManager.launchAtLogin = isEnabled
    }
}
