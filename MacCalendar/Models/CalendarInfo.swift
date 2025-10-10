//
//  CalendarInfo.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/10.
//

import Foundation
import SwiftUI

struct CalendarInfo: Identifiable, Hashable {
    let id: String // calendarIdentifier
    let title: String
    let color: Color
    var isSelected: Bool = false
}
