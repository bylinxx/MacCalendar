//
//  SettingsViewType.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

enum SettingsType:String,CaseIterable,Identifiable{
    case icon = "菜单栏显示"
    case calendar = "日程显示"
    case launchAtLogin = "启动项"
    case about = "关于"
    
    var id:String {self.rawValue}
    
    @ViewBuilder
    var view:some View {
        switch self {
        case .icon:
            SettingsIconView()
        case .calendar:
            SettingsCalendarView()
        case .launchAtLogin:
            SettingsLaunchAtLoginView()
        case .about:
            SettingsAboutView()
        }
    }
}
