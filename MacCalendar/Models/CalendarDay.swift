//
//  CalendarDay.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI


struct CalendarDay:Hashable{
    /// 是否周数
    let is_weekNumber:Bool
    /// 周数
    let weekNumber:Int?
    /// 日期
    let date:Date?
    /// 简单农历
    let short_lunar:String?
    /// 完整农历
    let full_lunar:String?
    /// 节假日
    let holidays:[String]
    /// 节气
    let solar_term:String?
    /// 放假
    let offday :Bool?
    /// 事件
    let events:[CalendarEvent]
    
    init(
            is_weekNumber: Bool = false,
            weekNumber: Int? = nil,
            date: Date? = nil,
            short_lunar: String? = nil,
            full_lunar: String? = nil,
            holidays: [String] = [],
            solar_term: String? = nil,
            offday: Bool? = nil,
            events: [CalendarEvent] = []
        ) {
            self.is_weekNumber = is_weekNumber
            self.weekNumber = weekNumber
            self.date = date
            self.short_lunar = short_lunar
            self.full_lunar = full_lunar
            self.holidays = holidays
            self.solar_term = solar_term
            self.offday = offday
            self.events = events
        }
}
