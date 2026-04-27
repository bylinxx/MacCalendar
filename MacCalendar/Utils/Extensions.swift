//
//  Extensions.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/4.
//

import Foundation
import SwiftUI

extension Calendar {
    static var Based: Calendar {
        return Calendar(identifier: .gregorian)
    }
}

public extension Bundle {
    var appVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var appBuildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }

    var fullVersion: String {
        let version = appVersion ?? "N/A"
        let build = appBuildNumber ?? "N/A"
        return "Version \(version) (\(build))"
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
