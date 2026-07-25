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

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "亮色"
    case dark = "暗色"
    case system = "跟随系统"
    
    var id: Self { self }
    
    var nsAppearance: NSAppearance? {
        switch self {
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        case .system:
            return nil
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

struct SettingsManager {
    static let sharedDefaults = UserDefaults(suiteName: "group.Lin.MacCalendar")!
    
    @AppStorage("launchAtLogin", store: sharedDefaults) static var launchAtLogin = false
    @AppStorage("startMinimized", store: sharedDefaults) static var startMinimized = false
    @AppStorage("displayMode", store: sharedDefaults) static var displayMode: DisplayMode = .icon
    @AppStorage("customFormatString", store: sharedDefaults) static var customFormatString: String = "yyyy-MM-dd"
    @AppStorage("enableDoubleLine", store: sharedDefaults) static var enableDoubleLine = false
    @AppStorage("doubleLineTopFormat", store: sharedDefaults) static var doubleLineTopFormat: String = "HH:mm"
    @AppStorage("doubleLineBottomFormat", store: sharedDefaults) static var doubleLineBottomFormat: String = "MM-dd"
    @AppStorage("filterCalendar", store: sharedDefaults) static var filterCalendar: Data = Data()
    @AppStorage("firstDayInWeek", store: sharedDefaults) static var firstDayInWeek:FirstDayInWeek = .monday
    @AppStorage("showWeekNumber", store: sharedDefaults) static var showWeekNumber = false
    @AppStorage("widgetMonthOffset", store: sharedDefaults) static var widgetMonthOffset = 0
    @AppStorage("widgetLastUserActionTime", store: sharedDefaults) static var widgetLastUserActionTime = 0.0
    @AppStorage("updateCheckFrequency", store: sharedDefaults) static var updateCheckFrequency: UpdateCheckFrequency = .weekly
    @AppStorage("showDaysIndicator", store: sharedDefaults) static var showDaysIndicator = true
    @AppStorage("appearanceMode", store: sharedDefaults) static var appearanceMode: AppearanceMode = .system
    
    static func migrateSettingsIfNeeded() {
        let hasMigratedKey = "__hasMigratedToAppGroup"
        
        guard !sharedDefaults.bool(forKey: hasMigratedKey) else { return }
        
        let keysToMigrate = [
            "launchAtLogin",
            "startMinimized",
            "displayMode",
            "customFormatString",
            "enableDoubleLine",
            "doubleLineTopFormat",
            "doubleLineBottomFormat",
            "filterCalendar",
            "firstDayInWeek",
            "showWeekNumber",
            "widgetMonthOffset",
            "widgetLastUserActionTime",
            "updateCheckFrequency",
            "showDaysIndicator",
            "appearanceMode"
        ]
        
        for key in keysToMigrate {
            if let value = UserDefaults.standard.object(forKey: key),
               sharedDefaults.object(forKey: key) == nil {
                sharedDefaults.set(value, forKey: key)
            }
        }
        
        sharedDefaults.set(true, forKey: hasMigratedKey)
    }
}
