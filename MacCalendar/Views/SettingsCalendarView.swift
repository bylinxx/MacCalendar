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
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 标题和描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("日历设置")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("选择您想要在日历中显示的日历")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 日历列表
                if isAccessDenied {
                    SettingsCard {
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
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 24)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else if calendarManager.calendarInfos.isEmpty {
                    SettingsCard {
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
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
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
                                .animation(.spring(), value: calendarManager.calendarInfos)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                await calendarManager.loadCalendarInfo()
                isAccessDenied = calendarManager.authorizationStatus != .fullAccess && calendarManager.authorizationStatus != .notDetermined
            }
        }
    }
}
