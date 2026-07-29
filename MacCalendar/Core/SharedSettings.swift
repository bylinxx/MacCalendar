//
//  SharedSettings.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/7/29.
//

import Foundation

struct SharedSettings: Codable {
    var launchAtLogin: Bool
    var startMinimized: Bool
    var displayModeRaw: String
    var customFormatString: String
    var enableDoubleLine: Bool
    var doubleLineTopFormat: String
    var doubleLineBottomFormat: String
    var filterCalendarBase64: String
    var firstDayInWeekRaw: String
    var showWeekNumber: Bool
    var widgetMonthOffset: Int
    var widgetLastUserActionTime: Double
    var updateCheckFrequencyRaw: String
    var showDaysIndicator: Bool
    var appearanceModeRaw: String
    
    init(
        launchAtLogin: Bool = false,
        startMinimized: Bool = false,
        displayModeRaw: String = "图标",
        customFormatString: String = "yyyy-MM-dd",
        enableDoubleLine: Bool = false,
        doubleLineTopFormat: String = "HH:mm",
        doubleLineBottomFormat: String = "MM-dd",
        filterCalendarBase64: String = "",
        firstDayInWeekRaw: String = "周一",
        showWeekNumber: Bool = false,
        widgetMonthOffset: Int = 0,
        widgetLastUserActionTime: Double = 0.0,
        updateCheckFrequencyRaw: String = "每周",
        showDaysIndicator: Bool = true,
        appearanceModeRaw: String = "跟随系统"
    ) {
        self.launchAtLogin = launchAtLogin
        self.startMinimized = startMinimized
        self.displayModeRaw = displayModeRaw
        self.customFormatString = customFormatString
        self.enableDoubleLine = enableDoubleLine
        self.doubleLineTopFormat = doubleLineTopFormat
        self.doubleLineBottomFormat = doubleLineBottomFormat
        self.filterCalendarBase64 = filterCalendarBase64
        self.firstDayInWeekRaw = firstDayInWeekRaw
        self.showWeekNumber = showWeekNumber
        self.widgetMonthOffset = widgetMonthOffset
        self.widgetLastUserActionTime = widgetLastUserActionTime
        self.updateCheckFrequencyRaw = updateCheckFrequencyRaw
        self.showDaysIndicator = showDaysIndicator
        self.appearanceModeRaw = appearanceModeRaw
    }
    
    var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeRaw) ?? .icon }
        set { displayModeRaw = newValue.rawValue }
    }
    
    var firstDayInWeek: FirstDayInWeek {
        get { FirstDayInWeek(rawValue: firstDayInWeekRaw) ?? .monday }
        set { firstDayInWeekRaw = newValue.rawValue }
    }
    
    var updateCheckFrequency: UpdateCheckFrequency {
        get { UpdateCheckFrequency(rawValue: updateCheckFrequencyRaw) ?? .weekly }
        set { updateCheckFrequencyRaw = newValue.rawValue }
    }
    
    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }
    
    var filterCalendarData: Data {
        get { Data(base64Encoded: filterCalendarBase64) ?? Data() }
        set { filterCalendarBase64 = newValue.base64EncodedString() }
    }
}