//
//  SolarTermHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/3.
//

import Foundation

struct SolarTermHelper {
    enum SolarTerm: CaseIterable {
        // 正月
        case liChun, yuShui
        // 二月
        case jingZhe, chunFen
        // 三月
        case qingMing, guYu
        // 四月
        case liXia, xiaoMan
        // 五月
        case mangZhong, xiaZhi
        // 六月
        case xiaoShu, daShu
        // 七月
        case liQiu, chuShu
        // 八月
        case baiLu, qiuFen
        // 九月
        case hanLu, shuangJiang
        // 十月
        case liDong, xiaoXue
        // 十一月
        case daXue, dongZhi
        // 腊月
        case xiaoHan, daHan

        /// 节气的中文名称
        var chineseName: String {
            switch self {
            case .liChun: return "立春"
            case .yuShui: return "雨水"
            case .jingZhe: return "惊蛰"
            case .chunFen: return "春分"
            case .qingMing: return "清明"
            case .guYu: return "谷雨"
            case .liXia: return "立夏"
            case .xiaoMan: return "小满"
            case .mangZhong: return "芒种"
            case .xiaZhi: return "夏至"
            case .xiaoShu: return "小暑"
            case .daShu: return "大暑"
            case .liQiu: return "立秋"
            case .chuShu: return "处暑"
            case .baiLu: return "白露"
            case .qiuFen: return "秋分"
            case .hanLu: return "寒露"
            case .shuangJiang: return "霜降"
            case .liDong: return "立冬"
            case .xiaoXue: return "小雪"
            case .daXue: return "大雪"
            case .dongZhi: return "冬至"
            case .xiaoHan: return "小寒"
            case .daHan: return "大寒"
            }
        }
        
        /// 节气所在的大致月份
        var month: Int {
            switch self {
            case .liChun, .yuShui: return 2
            case .jingZhe, .chunFen: return 3
            case .qingMing, .guYu: return 4
            case .liXia, .xiaoMan: return 5
            case .mangZhong, .xiaZhi: return 6
            case .xiaoShu, .daShu: return 7
            case .liQiu, .chuShu: return 8
            case .baiLu, .qiuFen: return 9
            case .hanLu, .shuangJiang: return 10
            case .liDong, .xiaoXue: return 11
            case .daXue, .dongZhi: return 12
            case .xiaoHan, .daHan: return 1
            }
        }
        
        /// 节气计算所需的C值（20世纪和21世纪）
        var cValue: (c20thCentury: Double, c21stCentury: Double) {
            switch self {
            case .liChun:     return (4.6295, 3.87)
            case .yuShui:     return (19.4599, 18.73)
            case .jingZhe:    return (6.3826, 5.63)
            case .chunFen:    return (21.4155, 20.646)
            case .qingMing:   return (5.59, 4.81)
            case .guYu:       return (20.888, 20.1)
            case .liXia:      return (6.318, 5.52)
            case .xiaoMan:    return (21.86, 21.04)
            case .mangZhong:  return (6.5, 5.678)
            case .xiaZhi:     return (22.2, 21.37)
            case .xiaoShu:    return (7.928, 7.108)
            case .daShu:      return (23.65, 22.83)
            case .liQiu:      return (8.35, 7.5)
            case .chuShu:     return (23.95, 23.15)
            case .baiLu:      return (8.44, 7.646)
            case .qiuFen:     return (23.822, 23.042)
            case .hanLu:      return (9.098, 8.318)
            case .shuangJiang:return (24.218, 23.438)
            case .liDong:     return (8.218, 7.438)
            case .xiaoXue:    return (23.08, 22.36)
            case .daXue:      return (7.7, 7.18)
            case .dongZhi:    return (22.394, 21.94)
            case .xiaoHan:    return (6.11, 5.4055)
            case .daHan:      return (20.84, 20.12)
            }
        }
        
        /// 特殊年份修正规则
        var specialRule: (years: [Int], description: String)? {
            switch self {
            case .dongZhi:
                return ([2082], "2082年的冬至日期需要加1天")
            default:
                return nil
            }
        }
    }
    /// 获取指定日期的节气名称。
    ///
    /// - Parameter date: 需要查询的日期。
    /// - Returns: 如果该日期是二十四节气之一，则返回其中文名称（例如 "立春"）；否则返回 `nil`。
    public static func getSolarTerm(for date: Date) -> String? {
        let calendar = Calendar.Based
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        
        guard year >= 1901 && year <= 2100 else {
            return nil
        }

        let potentialSolarTerms = SolarTerm.allCases.filter { $0.month == month }
        
        for term in potentialSolarTerms {
            if calculateSolarTermDay(for: term, year: year) == day {
                return term.chineseName
            }
        }

        return nil
    }

    /// 根据年份和节气类型计算其所在的日期。
    /// - Parameters:
    ///   - term: 节气枚举。
    ///   - year: 年份。
    /// - Returns: 该节气在指定年份的具体日期（几号）。
    private static func calculateSolarTermDay(for term: SolarTerm, year: Int) -> Int {
        // 公式：[Y*D+C]-L
        // Y: 年份的后两位
        // D: 常数 0.2422
        // C: 20世纪或21世纪的节气常数
        // L: 闰年修正 [Y/4]
        
        let y = Double(year % 100) // 年份后两位
        let d = 0.2422
        
        // 根据年份选择不同的 C 值
        let c = (year < 2001) ? term.cValue.c20thCentury : term.cValue.c21stCentury
        
        let day = Int(y * d + c) - Int(y / 4.0)
        
        // 特殊情况修正：某些节气在特定年份需要加1天
        if let specialRule = term.specialRule, specialRule.years.contains(year) {
            return day + 1
        }
        
        return day
    }
}
