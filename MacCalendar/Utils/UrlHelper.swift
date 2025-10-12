//
//  UrlHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import Foundation

struct UrlHelper{
    /// 规范化一个 URL 对象。如果它没有网络协议（http/https），则尝试为其添加 https://。
    /// - Parameter url: 一个输入的 URL 对象。
    /// - Returns: 一个带有网络协议的 URL 对象。
    static func normalizeURL(from url: URL) -> URL {
        if let scheme = url.scheme, scheme.lowercased() == "http" || scheme.lowercased() == "https" {
            return url
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.scheme = "https"
        
        return components?.url ?? url
    }
}
