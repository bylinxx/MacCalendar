//
//  ContentView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        VStack(spacing:0) {
            CalendarView(calendarManager: calendarManager)
            Divider()
                .padding([.top,.bottom],10)
            EventListView(calendarManager: calendarManager)
        }
        .padding()
    }
}
