//
//  CalendarEvent.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI

struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(color: Color) {
        // 提取 RGBA
        guard let cgColor = color.cgColor, let components = cgColor.components, components.count >= 3 else {
            self.red = 0; self.green = 0; self.blue = 0; self.opacity = 1
            return
        }
        self.red = Double(components[0])
        self.green = Double(components[1])
        self.blue = Double(components[2])
        self.opacity = Double(cgColor.alpha)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}


struct CalendarEvent:Identifiable,Hashable,Codable {
    let id:String
    /// 日历标题
    let calendar_title:String?
    /// 是否允许修改
    let allowsModify:Bool?
    /// 标题
    var title: String
    /// 位置
    var location:String?
    /// 是否全天
    var isAllDay:Bool
    /// 开始时间
    var startDate: Date
    /// 结束时间
    var endDate: Date
    /// 颜色
    let color:CodableColor
    /// 备注
    var notes:String?
    /// 链接地址
    var url:URL?
}
