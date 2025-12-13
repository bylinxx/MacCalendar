//
//  OffdayData.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/12/12.
//

import Foundation

struct OffdayDataItem: Codable {
    let date: String
    let isOffDay: Bool
}

struct OffdayDataResponse: Codable {
    let days: [OffdayDataItem]
}
