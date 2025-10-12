//
//  SettingsStartupView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

struct SettingsLaunchAtLoginView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        VStack{
            Toggle("开机时自动启动", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { oldValue, newValue in
                    LaunchAtLoginManager.setLaunchAtLogin(enabled: newValue)
                }
            
            Spacer()
        }
    }
    
    private func syncToggleWithSystem() {
        launchAtLogin = LaunchAtLoginManager.isLaunchAtLoginEnabled()
    }
}
