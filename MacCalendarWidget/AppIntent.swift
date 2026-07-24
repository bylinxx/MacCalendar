//
//  AppIntent.swift
//  MacCalendarWidget
//
//  Created by ruihelin on 2026/7/21.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "" }
    static var description: IntentDescription { "" }
}

struct ChangeMonthIntent: AppIntent {
    static var title: LocalizedStringResource { "切换月份" }
    static var description: IntentDescription { "切换日历显示的月份" }
    
    @Parameter(title: "偏移量", description: "月份偏移量，1表示下个月，-1表示上个月")
    var offset: Int
    
    init() {}
    
    init(offset: Int) {
        self.offset = offset
    }
    
    func perform() async throws -> some IntentResult {
        SettingsManager.widgetMonthOffset += offset
        SettingsManager.widgetLastUserActionTime = Date().timeIntervalSince1970
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct ResetMonthIntent: AppIntent {
    static var title: LocalizedStringResource { "回到今天" }
    static var description: IntentDescription { "将日历切换回当前月份" }
    
    func perform() async throws -> some IntentResult {
        SettingsManager.widgetMonthOffset = 0
        SettingsManager.widgetLastUserActionTime = Date().timeIntervalSince1970
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
