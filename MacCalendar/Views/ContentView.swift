//
//  ContentView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        VStack(spacing:0) {
            HStack {
                Spacer()
                Button("打开系统日历") {
                    openSystemCalendar()
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            CalendarView(calendarManager: calendarManager)
            Divider()
                .padding([.top,.bottom],10)
            EventListView(calendarManager: calendarManager)
        }
        .frame(width: SettingsManager.weekNumberDisplayMode == .show ? 335 : 300)
        .padding()
        .fixedSize()
        .overlay(
            GeometryReader{ proxy in
                Color.clear
                    .preference(
                        key: SizeKey.self, value: proxy.size
                    )
            }
        )
    }

    private func openSystemCalendar() {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            return
        }
        if let url = URL(string: "calshow://") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
