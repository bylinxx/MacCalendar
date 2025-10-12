//
//  CalendarError.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/12.
//

import Foundation

enum CalendarError: Error, LocalizedError {
    case noPermission
    case eventNotFound
    case calendarNotModifiable
    case catchError(Error)

    // 实现 LocalizedError 协议，为每种错误提供用户友好的描述
    var errorDescription: String? {
        switch self {
        case .noPermission:
            return "没有足够的日历访问权限，请在系统设置中允许本应用访问日历。"
        case .eventNotFound:
            return "未能找到需要修改的事件。"
        case .calendarNotModifiable:
            return "此事件所在的日历不允许修改内容。"
        case .catchError(let error):
            return error.localizedDescription
        }
    }
}
