//
//  SettingsCalendar.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/10.
//

import SwiftUI

struct SettingsCalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        VStack(alignment: .leading) {
            List($calendarManager.calendarInfos) { $calendar in
                Toggle(isOn: $calendar.isSelected) {
                    HStack() {
                        Circle()
                            .fill(calendar.color)
                            .frame(width: 12, height: 12)
                        Text(calendar.title)
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            Spacer()
        }
        .onAppear {
            Task {
                await calendarManager.loadCalendarInfo()
            }
        }
    }
}
