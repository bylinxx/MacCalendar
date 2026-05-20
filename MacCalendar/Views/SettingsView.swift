//
//  SettingsView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

struct SettingsView: View {
    @State private var selection: SettingsType = .customized
    @ObservedObject var calendarManager: CalendarManager
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = SettingsManager.appearanceMode
    
    var body: some View {
        NavigationSplitView {
            List(SettingsType.allCases, selection: $selection) { setting in
                Label(setting.rawValue, systemImage: setting.icon)
                    .tag(setting)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            selection.view
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environmentObject(calendarManager)
                .navigationTitle(selection.rawValue)
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}
