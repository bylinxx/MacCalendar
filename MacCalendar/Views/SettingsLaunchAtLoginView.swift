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
        Form {
            Section {
                Toggle("开机时自动启动", isOn: $launchAtLogin)
            } footer: {
                Text("启用后，应用将在系统启动时自动运行")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
