//
//  SettingsCalendarView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI
import EventKit

struct SettingsCalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var isAccessDenied = false
    
    var body: some View {
        Form {
            if isAccessDenied {
                Section {
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "lock")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("日历访问权限被拒绝")
                            .font(.headline)
                        Text("请在系统设置中允许此应用访问您的日历")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                        }) {
                            Text("前往系统设置")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else if calendarManager.calendarInfos.isEmpty {
                Section {
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("未找到日历")
                            .font(.headline)
                        Text("请在系统日历应用中创建日历")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                Section {
                    ForEach(calendarManager.calendarInfos) { calendar in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(calendar.color)
                                .frame(width: 12, height: 12)
                            Text(calendar.title)
                                .font(.body)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { calendar.isSelected },
                                set: { isOn in
                                    if let index = calendarManager.calendarInfos.firstIndex(where: { $0.id == calendar.id }) {
                                        calendarManager.calendarInfos[index].isSelected = isOn
                                    }
                                }
                            ))
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                await calendarManager.loadCalendarInfo()
                isAccessDenied = calendarManager.authorizationStatus != .fullAccess && calendarManager.authorizationStatus != .notDetermined
            }
        }
    }
}
