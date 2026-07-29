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
    
    static let widgetBundleID = "Lin.MacCalendar.MacCalendarWidget"
    
    static let sharedDefaults: UserDefaults = .standard
    
    static var sharedSettingsFileURL: URL {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        if bundleID == widgetBundleID {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent("shared_settings.json")
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            return home
                .appendingPathComponent("Library")
                .appendingPathComponent("Containers")
                .appendingPathComponent(widgetBundleID)
                .appendingPathComponent("Data")
                .appendingPathComponent("Documents")
                .appendingPathComponent("shared_settings.json")
        }
    }
    
    static func loadSharedFromFile() -> SharedSettings? {
        let fileURL = sharedSettingsFileURL
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let settings = try JSONDecoder().decode(SharedSettings.self, from: data)
            return settings
        } catch {
            return nil
        }
    }
    
    static func saveSharedToFile(_ settings: SharedSettings) {
        let fileURL = sharedSettingsFileURL
        
        let directoryURL = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(settings)
            try data.write(to: fileURL, options: .atomic)
        } catch {}
    }
    
    static func readFromSharedFile() -> SharedSettings {
        return loadSharedFromFile() ?? SharedSettings()
    }
    
    static func writeToSharedFile(_ settings: SharedSettings) {
        saveSharedToFile(settings)
    }
    
    static func syncAllToSharedFile() {
        var settings = SharedSettings(
            launchAtLogin: sharedDefaults.bool(forKey: "launchAtLogin"),
            startMinimized: sharedDefaults.bool(forKey: "startMinimized"),
            displayModeRaw: sharedDefaults.string(forKey: "displayMode") ?? "图标",
            customFormatString: sharedDefaults.string(forKey: "customFormatString") ?? "yyyy-MM-dd",
            enableDoubleLine: sharedDefaults.bool(forKey: "enableDoubleLine"),
            doubleLineTopFormat: sharedDefaults.string(forKey: "doubleLineTopFormat") ?? "HH:mm",
            doubleLineBottomFormat: sharedDefaults.string(forKey: "doubleLineBottomFormat") ?? "MM-dd",
            filterCalendarBase64: sharedDefaults.data(forKey: "filterCalendar")?.base64EncodedString() ?? "",
            firstDayInWeekRaw: sharedDefaults.string(forKey: "firstDayInWeek") ?? "周一",
            showWeekNumber: sharedDefaults.bool(forKey: "showWeekNumber"),
            widgetMonthOffset: sharedDefaults.integer(forKey: "widgetMonthOffset"),
            widgetLastUserActionTime: sharedDefaults.double(forKey: "widgetLastUserActionTime"),
            updateCheckFrequencyRaw: sharedDefaults.string(forKey: "updateCheckFrequency") ?? "每周",
            showDaysIndicator: sharedDefaults.object(forKey: "showDaysIndicator") as? Bool ?? true,
            appearanceModeRaw: sharedDefaults.string(forKey: "appearanceMode") ?? "跟随系统"
        )
        
        if let existing = loadSharedFromFile() {
            settings.widgetMonthOffset = existing.widgetMonthOffset
            settings.widgetLastUserActionTime = existing.widgetLastUserActionTime
        }
        
        saveSharedToFile(settings)
    }
    
    // MARK: - Main App @AppStorage properties
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
}