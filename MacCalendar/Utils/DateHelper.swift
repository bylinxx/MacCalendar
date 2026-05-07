//
//  DateHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import Foundation


struct DateHelper{
    static func formatDate(date: Date, format: String, localeIdentifier: String = Locale.current.identifier) -> String {
        var calendar = Calendar(identifier: .gregorian)
        let isMondayFirst = SettingsManager.firstDayInWeek == .monday
        calendar.firstWeekday = isMondayFirst ? 2 : 1
        calendar.minimumDaysInFirstWeek = 1
        
        // 如果是单纯请求周数，直接返回计算值，不走 Formatter
        if format == "w" || format == "ww" {
            let week = calendar.component(.weekOfYear, from: date)
            return format == "ww" ? String(format: "%02d", week) : "\(week)"
        }
        
        // 处理混合格式（例如 "第 w 周"）
        var finalFormat = format
        if format.contains("w") {
            let week = calendar.component(.weekOfYear, from: date)
            // 将格式字符串中的 w 或 ww 替换为真实计算的数字
            finalFormat = format.replacingOccurrences(of: "ww", with: String(format: "%02d", week))
                               .replacingOccurrences(of: "w", with: "\(week)")
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.calendar = calendar
        formatter.dateFormat = finalFormat
        
        return formatter.string(from: date)
    }
    
    /// 计算两个日期之间的时长，并返回格式化的字符串。
    ///
    /// - Parameters:
    ///   - startDate: 起始日期。
    ///   - endDate: 结束日期。
    /// - Returns: 格式化后的时长字符串，例如 "5小时30分", "2小时", "45分"。
    static func daysFromToday(to date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: targetDay)
        let days = components.day ?? 0
        
        if days == 0 {
            return "今天"
        } else if days == 1 {
            return "明天"
        } else if days == -1 {
            return "昨天"
        } else if days > 0 {
            return "距离今天 \(days) 天后"
        } else {
            return "距离今天 \(abs(days)) 天前"
        }
    }
    
    static func formattedDuration(from startDate: Date, to endDate: Date) -> String? {
        // 为了确保结果为正数，自动识别较早和较晚的日期
        let earlierDate = min(startDate, endDate)
        let laterDate = max(startDate, endDate)
        
        let calendar = Calendar.Based
        
        let components = calendar.dateComponents([.hour, .minute], from: earlierDate, to: laterDate)
        
        // 从计算结果中安全地获取小时和分钟数，如果为 nil 则默认为 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 && minutes > 0 {
            // 小时和分钟都存在
            return "\(hours)小时\(minutes)分"
        } else if hours > 0 {
            // 只有小时（分钟为0）
            return "\(hours)小时"
        } else if minutes > 0 {
            // 只有分钟（小时为0）
            return "\(minutes)分"
        } else {
            // 时长为0
            return nil
        }
    }
}
