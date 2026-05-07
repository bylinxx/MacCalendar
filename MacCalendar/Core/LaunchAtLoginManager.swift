//
//  LaunchAtLoginManager.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import Foundation
import ServiceManagement

struct LaunchAtLoginManager {

    /// 设置 App 是否在登录时启动
    /// - Parameter enabled: true 表示注册为登录项, false 表示注销
    static func setLaunchAtLogin(enabled: Bool) {
        Task { @MainActor in
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
            }
        }
    }

    /// 检查 App 当前是否被设置为登录时启动
    /// - Returns: 如果是登录项则返回 true，否则返回 false
    static func isLaunchAtLoginEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
}
