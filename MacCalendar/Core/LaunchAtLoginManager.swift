//
//  LaunchAtLoginManager.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import Foundation
import ServiceManagement

struct LaunchAtLoginManager {

    static var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    static var isLaunchAtLoginEnabled: Bool {
        status == .enabled
    }

    /// 返回 false 表示系统拒绝了这次变更，调用方需回读 status 纠正 UI
    @discardableResult
    static func setLaunchAtLogin(enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }

    static func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
