//
//  SettingsManager.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import Foundation
import SwiftUI


enum DisplayMode: String, CaseIterable, Identifiable {
    case icon = "图标"
    case date = "日期"
    case time = "时间"
    case custom = "自定义"
    
    var id: Self { self }
}

enum FirstDayInWeek:String,CaseIterable,Identifiable{
    case monday = "周一"
    case sunday = "周日"
    
    var id:Self{self}
}

enum WeekNumberDisplayMode: String, CaseIterable, Identifiable {
    case show = "显示"
    case hide = "隐藏"

    var id: Self { self }
}

struct SettingsManager {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("displayMode") static var displayMode: DisplayMode = .icon
    @AppStorage("customFormatString") static var customFormatString: String = "yyyy-MM-dd"
    @AppStorage("filterCalendar") static var filterCalendar: Data = Data()
    @AppStorage("firstDayInWeek") static var firstDayInWeek:FirstDayInWeek = .monday
    @AppStorage("weekNumberDisplayMode") static var weekNumberDisplayMode: WeekNumberDisplayMode = .hide
}
