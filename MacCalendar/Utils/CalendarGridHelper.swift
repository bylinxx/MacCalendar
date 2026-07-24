//
//  CalendarGridHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2026/7/23.
//

import Foundation

struct CalendarGridHelper {
    
    static let calendar = Calendar.Based
    static let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    
    static func generateDateGrid(for date: Date, firstDayInWeek: Int = 2) -> [Date]? {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return nil }
        
        var gridDates: [Date] = []
        let firstDayOfMonth = monthInterval.start
        let range = calendar.range(of: .day, in: .month, for: date)!
        
        let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = (weekdayOfFirst - firstDayInWeek + 7) % 7
        if offset > 0 {
            for i in (1...offset).reversed() {
                if let prevDay = calendar.date(byAdding: .day, value: -i, to: firstDayOfMonth) {
                    gridDates.append(prevDay)
                }
            }
        }
        
        for i in 0..<range.count {
            if let day = calendar.date(byAdding: .day, value: i, to: firstDayOfMonth) {
                gridDates.append(day)
            }
        }
        
        let totalDays = gridDates.count
        let remaining = totalDays % 7
        if remaining > 0 {
            let lastDay = gridDates.last!
            for i in 1...(7 - remaining) {
                if let nextDay = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    gridDates.append(nextDay)
                }
            }
        }
        
        return gridDates
    }
    
    static func calculateWeekOfYear(for date: Date?, firstDayInWeek: Int = 2) -> Int {
        guard let date = date else { return 0 }
        
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.current
        cal.firstWeekday = firstDayInWeek
        cal.minimumDaysInFirstWeek = 1
        
        return cal.component(.weekOfYear, from: date)
    }
    
    static func formatDate(_ date: Date, format: String, localeIdentifier: String = "zh_CN") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter.string(from: date)
    }
    
    struct BasicCalendarDay {
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
    
    static func generateBasicCalendarData(for date: Date, firstDayInWeek: Int = 2, today: Date = Date()) -> [BasicCalendarDay] {
        let lunarCalendar = Calendar(identifier: .chinese)
        
        guard let gridDates = generateDateGrid(for: date, firstDayInWeek: firstDayInWeek) else { return [] }
        
        var basicDays: [BasicCalendarDay] = []
        
        for day in gridDates {
            let dayOfMonth = calendar.component(.day, from: day)
            let isToday = calendar.isDate(day, equalTo: today, toGranularity: .day)
            let isCurrentMonth = calendar.isDate(day, equalTo: date, toGranularity: .month)
            let weekDay = calendar.component(.weekday, from: day)
            
            let lunarDateComponents = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: day)
            let lunarMonth = lunarDateComponents.month ?? 1
            let lunarDay = lunarDateComponents.day ?? 1
            
            var daysInLunarMonth = 0
            if let range = lunarCalendar.range(of: .day, in: .month, for: day) {
                daysInLunarMonth = range.count
            }
            
            let ganzhiYear = LunarDateHelper.getGanzhiYear(for: day)
            let zodiac = LunarDateHelper.getZodiac(for: day)
            let shortLunar = (lunarDay == 1) ? LunarDateHelper.getLunarMonth(for: day) : LunarDateHelper.getLunarDay(for: day)
            let fullLunar = "\(ganzhiYear) (\(zodiac)) \(LunarDateHelper.getLunarMonth(for: day))\(LunarDateHelper.getLunarDay(for: day))"
            
            let solarTerm = SolarTermHelper.getSolarTerm(for: day)
            let holidays = HolidayHelper.getHolidays(date: day, lunarMonth: lunarMonth, lunarDay: lunarDay, daysInLunarMonth: daysInLunarMonth)
            let offday = OffdayHelper.checkOffdayStatus(for: day)
            
            basicDays.append(BasicCalendarDay(
                date: day,
                dayOfMonth: dayOfMonth,
                isToday: isToday,
                isCurrentMonth: isCurrentMonth,
                shortLunar: shortLunar,
                fullLunar: fullLunar,
                holidays: holidays,
                solarTerm: solarTerm,
                offday: offday,
                weekDay: weekDay
            ))
        }
        
        return basicDays
    }
}
