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
        .fixedSize()
        .overlay(
            GeometryReader{ proxy in
                Color.clear
                    .preference(
                        key: SizeKey.self, value: proxy.size
                    )
            }
        )
    }
}

struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
