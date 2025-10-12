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
        let ganzhiYear = getGanzhiYear(for: date)
        
        guard ganzhiYear.count >= 2 else { return "" }
        let branchCharacter = String(ganzhiYear[ganzhiYear.index(ganzhiYear.startIndex, offsetBy: 1)])
        
        if let branchIndex = earthlyBranches.firstIndex(of: branchCharacter) {
            return zodiacSymbols[branchIndex]
        }
        
        return ""
    }
}
