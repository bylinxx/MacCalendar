//
//  WidgetDataHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/7/22.
//

import Foundation
import SwiftUI

struct WidgetCalendarDay {
    let date: Date
    let dayOfMonth: Int
    let isToday: Bool
    let isCurrentMonth: Bool
    let shortLunar: String
    let fullLunar: String
    let holidays: [String]
    let solarTerm: String?
    let offday: Bool?
    let weekDay: Int
}

struct WidgetCalendarData {
    let currentDate: Date
    let year: Int
    let month: Int
    let days: [WidgetCalendarDay]
    let weekdays: [String]
}

struct WidgetDataHelper {
    
    static let calendar = Calendar.Based
    
    static func getCalendarData(for date: Date = Date(), today: Date = Date()) -> WidgetCalendarData {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        let basicDays = CalendarGridHelper.generateBasicCalendarData(for: date, firstDayInWeek: 2, today: today)
        
        let widgetDays = basicDays.map { day in
            WidgetCalendarDay(
                date: day.date,
                dayOfMonth: day.dayOfMonth,
                isToday: day.isToday,
                isCurrentMonth: day.isCurrentMonth,
                shortLunar: day.shortLunar,
                fullLunar: day.fullLunar,
                holidays: day.holidays,
                solarTerm: day.solarTerm,
                offday: day.offday,
                weekDay: day.weekDay
            )
        }
        
        return WidgetCalendarData(
            currentDate: date,
            year: year,
            month: month,
            days: widgetDays,
            weekdays: CalendarGridHelper.weekdays
        )
    }
    
    static func getTodayInfo() -> WidgetCalendarDay? {
        let data = getCalendarData()
        return data.days.first { $0.isToday }
    }
    
    static func getMonthTitle(date: Date) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return "\(year) / \(month)"
    }
    
    static func getWeekNumber(for date: Date) -> Int {
        return CalendarGridHelper.calculateWeekOfYear(for: date)
    }
}