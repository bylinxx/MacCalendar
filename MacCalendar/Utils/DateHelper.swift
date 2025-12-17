//
//  DateHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import Foundation


struct DateHelper{
    static func formatDate(date: Date, format: String, localeIdentifier: String = Locale.current.identifier) -> String {
        var calendar = Calendar(identifier: .iso8601)
        // ISO 8601 标准：周一为第一天，第一周至少4天
        calendar.firstWeekday = 2 // 2 代表周一
        calendar.minimumDaysInFirstWeek = 4
        
        let formatter = DateFormatter()
        formatter.calendar = calendar;
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter.string(from: date)
    }
    
    /// 计算两个日期之间的时长，并返回格式化的字符串。
    ///
    /// - Parameters:
    ///   - startDate: 起始日期。
    ///   - endDate: 结束日期。
    /// - Returns: 格式化后的时长字符串，例如 "5小时30分", "2小时", "45分"。
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
