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
    var customIconOptionRaw: String
    
    init(
        launchAtLogin: Bool = false,
        startMinimized: Bool = false,
        displayModeRaw: String = "自定义",
        customFormatString: String = "",
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
        appearanceModeRaw: String = "跟随系统",
        customIconOptionRaw: String = "默认图标"
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
        self.customIconOptionRaw = customIconOptionRaw
    }
    
    enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case startMinimized
        case displayModeRaw
        case customFormatString
        case enableDoubleLine
        case doubleLineTopFormat
        case doubleLineBottomFormat
        case filterCalendarBase64
        case firstDayInWeekRaw
        case showWeekNumber
        case widgetMonthOffset
        case widgetLastUserActionTime
        case updateCheckFrequencyRaw
        case showDaysIndicator
        case appearanceModeRaw
        case customIconOptionRaw
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        startMinimized = try container.decodeIfPresent(Bool.self, forKey: .startMinimized) ?? false
        displayModeRaw = try container.decodeIfPresent(String.self, forKey: .displayModeRaw) ?? "自定义"
        customFormatString = try container.decodeIfPresent(String.self, forKey: .customFormatString) ?? ""
        enableDoubleLine = try container.decodeIfPresent(Bool.self, forKey: .enableDoubleLine) ?? false
        doubleLineTopFormat = try container.decodeIfPresent(String.self, forKey: .doubleLineTopFormat) ?? "HH:mm"
        doubleLineBottomFormat = try container.decodeIfPresent(String.self, forKey: .doubleLineBottomFormat) ?? "MM-dd"
        filterCalendarBase64 = try container.decodeIfPresent(String.self, forKey: .filterCalendarBase64) ?? ""
        firstDayInWeekRaw = try container.decodeIfPresent(String.self, forKey: .firstDayInWeekRaw) ?? "周一"
        showWeekNumber = try container.decodeIfPresent(Bool.self, forKey: .showWeekNumber) ?? false
        widgetMonthOffset = try container.decodeIfPresent(Int.self, forKey: .widgetMonthOffset) ?? 0
        widgetLastUserActionTime = try container.decodeIfPresent(Double.self, forKey: .widgetLastUserActionTime) ?? 0.0
        updateCheckFrequencyRaw = try container.decodeIfPresent(String.self, forKey: .updateCheckFrequencyRaw) ?? "每周"
        showDaysIndicator = try container.decodeIfPresent(Bool.self, forKey: .showDaysIndicator) ?? true
        appearanceModeRaw = try container.decodeIfPresent(String.self, forKey: .appearanceModeRaw) ?? "跟随系统"
        customIconOptionRaw = try container.decodeIfPresent(String.self, forKey: .customIconOptionRaw) ?? "默认图标"
    }
    
    var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeRaw) ?? .custom }
        set { displayModeRaw = newValue.rawValue }
    }
    
    var customIconOption: IconDisplayOption {
        get { IconDisplayOption(rawValue: customIconOptionRaw) ?? .defaultIcon }
        set { customIconOptionRaw = newValue.rawValue }
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