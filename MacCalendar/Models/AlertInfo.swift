//
//  AlertInfo.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/12.
//

import Foundation

struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let onDismiss: (() -> Void)?
}
