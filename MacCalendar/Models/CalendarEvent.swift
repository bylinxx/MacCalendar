//
//  CalendarEvent.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI

struct CalendarEvent:Identifiable,Hashable,Codable {
    let id:String
    /// 日历标题
    let calendar_title:String?
    /// 是否允许修改
    let allowsModify:Bool?
    /// 标题
    var title: String
    /// 位置
    let location:String?
    /// 是否全天
    var isAllDay:Bool
    /// 开始时间
    var startDate: Date
    /// 结束时间
    var endDate: Date
    /// 颜色
    let color:Color
    /// 备注
    var notes:String?
    /// 链接地址
    var url:URL?
}
