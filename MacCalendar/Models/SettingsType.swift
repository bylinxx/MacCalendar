//
//  SettingsViewType.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

enum SettingsType:String,CaseIterable,Identifiable{
    case customized = "个性化"
    case calendar = "日程显示"
    case launchAtLogin = "启动项"
    case update = "检查更新"
    case about = "关于"
    
    var id:String {self.rawValue}
    
    var icon: String {
        switch self {
        case .customized: return "paintbrush"
        case .calendar: return "calendar"
        case .launchAtLogin: return "power"
        case .update: return "arrow.down.circle"
        case .about: return "info.circle"
        }
    }
    
    @ViewBuilder
    var view:some View {
        switch self {
        case .customized:
            SettingsIconView()
        case .calendar:
            SettingsCalendarView()
        case .launchAtLogin:
            SettingsLaunchAtLoginView()
        case .update:
            SettingsUpdateView()
        case .about:
            SettingsAboutView()
        }
    }
}
