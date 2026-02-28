//
//  LunarDateHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/12.
//

import Foundation

struct LunarDateHelper {

    static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    static let zodiacSymbols = ["鼠", "牛", "虎", "兔", "龍", "蛇", "馬", "羊", "猴", "雞", "狗", "豬"]
    static let lunarDaySymbols = ["初一","初二","初三","初四","初五","初六","初七","初八","初九","初十", "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十", "廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"]

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
        return yearFormatter.string(from: date) + "年"
    }

    /**
     根据公历日期，获取其对应的天干地支纪月
     - Parameter date: 公历日期
     - Returns: 天干地支字符串，例如 "辛丑月"
     */
    static func getGanzhiMonth(for date: Date) -> String {
        let chineseCalendar = Calendar(identifier: .chinese)
        let year = chineseCalendar.component(.year, from: date)
        let month = chineseCalendar.component(.month, from: date)

        guard month >= 1 && month <= 12 else { return "" }

        // 月干支计算：年干 × 2 + 月数 = 月干（取尾数）
        // 月支固定：(月数 + 1) % 12
        let yearStemIndex = (year - 1) % 10
        let monthStemIndex = (yearStemIndex * 2 + month) % 10
        let monthBranchIndex = (month + 1) % 12

        return heavenlyStems[monthStemIndex] + earthlyBranches[monthBranchIndex] + "月"
    }

    /**
     根据公历日期，获取农历日
     - Parameter date: 公历日期
     - Returns: 农历日字符串，例如 "初一"
     */
    static func getLunarDay(for date: Date) -> String {
        let chineseCalendar = Calendar(identifier: .chinese)
        let lunarDay = chineseCalendar.component(.day, from: date)
        guard lunarDay >= 1 && lunarDay <= 30 else { return "" }
        return lunarDaySymbols[lunarDay - 1]
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
