//
//  Extensions.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/4.
//

import Foundation
import SwiftUI

extension Calendar {
    static var mondayBased: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }
}

extension Bundle {
    public var appVersion: String? {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    public var appBuildNumber: String? {
        return self.infoDictionary?["CFBundleVersion"] as? String
    }
    
    public var fullVersion: String {
        let version = appVersion ?? "N/A"
        let build = appBuildNumber ?? "N/A"
        return "Version \(version) (\(build))"
    }
}

extension Color: Codable {
    // 定义用于存储颜色 RGBA 分量的结构体
    struct CodableColor: Codable {
        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double
    }

    // `encode(to:)` 方法：将 Color 编码成 CodableColor
    public func encode(to encoder: Encoder) throws {
        // 使用 UIColor 来获取 RGBA 组件
        // 注意：这需要 UIKit 或 AppKit
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        #elseif canImport(AppKit)
        let uiColor = NSColor(self)
        #endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let codableColor = CodableColor(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
        var container = encoder.singleValueContainer()
        try container.encode(codableColor)
    }

    // `init(from:)` 初始化器：从 CodableColor 解码成 Color
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codableColor = try container.decode(CodableColor.self)
        self.init(red: codableColor.red, green: codableColor.green, blue: codableColor.blue, opacity: codableColor.opacity)
    }
}
