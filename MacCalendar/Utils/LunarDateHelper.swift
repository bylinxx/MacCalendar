//
//  LunarDateHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/12.
//

import Foundation

struct LunarDateHelper {
    
    static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    static let zodiacSymbols = ["鼠", "牛", "虎", "兔", "龍", "蛇", "馬", "羊", "猴", "雞", "狗", "豬"]
    
    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .chinese)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "U"
        return formatter
    }()
    
    /**
     根据公历日期，准确获取其对应的天干地支纪年
     - Parameter date: 公历日期
     - Returns: 天干地支字符串，例如 "甲辰年"
     */
    static func getGanzhiYear(for date: Date) -> String {
        return yearFormatter.string(from: date)
    }
    
    /**
     根据公历日期，准确获取其对应的生肖
     - Parameter date: 公历日期
     - Returns: 生肖字符串，例如 "龍"
     */
    static func getZodiac(for date: Date) -> String {
        let chineseCalendar = Calendar(identifier: .chinese)
        let year = chineseCalendar.component(.year, from: date)
        
        // 地支计算公式：(年份 - 1) % 12
        // 例如：2024年是甲辰年，year 可能返回 41
        // (41 - 1) % 12 = 40 % 12 = 4
        // earthlyBranches[4] = "辰" (龙)
        // zodiacSymbols[4] = "龍"
        
        let branchIndex = (year - 1) % 12
        
        if branchIndex >= 0 && branchIndex < zodiacSymbols.count {
            return zodiacSymbols[branchIndex]
        }
        
        return ""
    }
}
