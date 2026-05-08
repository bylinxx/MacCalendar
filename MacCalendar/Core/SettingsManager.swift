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

enum UpdateCheckFrequency: String, CaseIterable, Identifiable {
    case daily = "每天"
    case weekly = "每周"
    case off = "关闭"
    
    var id: Self { self }
}

struct SettingsManager {
    @AppStorage("launchAtLogin") static var launchAtLogin = false
    @AppStorage("startMinimized") static var startMinimized = false
    @AppStorage("displayMode") static var displayMode: DisplayMode = .icon
    @AppStorage("customFormatString") static var customFormatString: String = "yyyy-MM-dd"
    @AppStorage("enableDoubleLine") static var enableDoubleLine = false
    @AppStorage("doubleLineTopFormat") static var doubleLineTopFormat: String = "HH:mm"
    @AppStorage("doubleLineBottomFormat") static var doubleLineBottomFormat: String = "MM-dd"
    @AppStorage("filterCalendar") static var filterCalendar: Data = Data()
    @AppStorage("firstDayInWeek") static var firstDayInWeek:FirstDayInWeek = .monday
    @AppStorage("showWeekNumber") static var showWeekNumber = false
    @AppStorage("updateCheckFrequency") static var updateCheckFrequency: UpdateCheckFrequency = .weekly
    @AppStorage("showDaysIndicator") static var showDaysIndicator = true
}
