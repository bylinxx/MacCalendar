//
//  MacCalendarWidget.swift
//  MacCalendarWidget
//
//  Created by ruihelin on 2026/7/21.
//

import WidgetKit
import SwiftUI
import AppIntents

struct MacCalendarWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MacCalendarWidgetEntry {
        let shared = SettingsManager.readFromSharedFile()
        let displayDate = calculateDisplayDate(for: Date(), context: context, customOffset: 0)
        let calendarData = WidgetDataHelper.getCalendarData(for: displayDate, today: Date(), firstDayInWeek: shared.firstDayInWeek)
        return MacCalendarWidgetEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            calendarData: calendarData,
            showWeekNumber: shared.showWeekNumber,
            firstDayInWeek: shared.firstDayInWeek
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> MacCalendarWidgetEntry {
        let shared = SettingsManager.readFromSharedFile()
        let displayDate = calculateDisplayDate(for: Date(), context: context, customOffset: 0)
        let calendarData = WidgetDataHelper.getCalendarData(for: displayDate, today: Date(), firstDayInWeek: shared.firstDayInWeek)
        return MacCalendarWidgetEntry(
            date: Date(),
            configuration: configuration,
            calendarData: calendarData,
            showWeekNumber: shared.showWeekNumber,
            firstDayInWeek: shared.firstDayInWeek
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<MacCalendarWidgetEntry> {
        let shared = SettingsManager.readFromSharedFile()
        
        var entries: [MacCalendarWidgetEntry] = []

        let currentDate = Date()
        let calendar = Calendar.current
        
        let viewingWindowMinutes: TimeInterval = 5 * 60
        let lastActionTime = shared.widgetLastUserActionTime
        let isWindowActive = lastActionTime > 0 && (currentDate.timeIntervalSince1970 - lastActionTime) < viewingWindowMinutes
        let viewingWindowEndDate = Date(timeIntervalSince1970: lastActionTime + viewingWindowMinutes)
        
        let currentOffset = shared.widgetMonthOffset
        
        if isWindowActive {
            let displayDate1 = calculateDisplayDate(for: currentDate, context: context, customOffset: currentOffset)
            let calendarData1 = WidgetDataHelper.getCalendarData(for: displayDate1, today: currentDate, firstDayInWeek: shared.firstDayInWeek)
            entries.append(MacCalendarWidgetEntry(
                date: currentDate,
                configuration: configuration,
                calendarData: calendarData1,
                showWeekNumber: shared.showWeekNumber,
                firstDayInWeek: shared.firstDayInWeek
            ))
            
            let displayDate2 = calculateDisplayDate(for: viewingWindowEndDate, context: context, customOffset: 0)
            let calendarData2 = WidgetDataHelper.getCalendarData(for: displayDate2, today: viewingWindowEndDate, firstDayInWeek: shared.firstDayInWeek)
            entries.append(MacCalendarWidgetEntry(
                date: viewingWindowEndDate,
                configuration: configuration,
                calendarData: calendarData2,
                showWeekNumber: shared.showWeekNumber,
                firstDayInWeek: shared.firstDayInWeek
            ))
            
            return Timeline(entries: entries, policy: .after(viewingWindowEndDate))
        } else {
            var updated = shared
            updated.widgetLastUserActionTime = 0
            updated.widgetMonthOffset = 0
            SettingsManager.writeToSharedFile(updated)
            
            for hourOffset in 0 ..< 24 {
                let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let displayDate = calculateDisplayDate(for: entryDate, context: context, customOffset: 0)
                let calendarData = WidgetDataHelper.getCalendarData(for: displayDate, today: entryDate, firstDayInWeek: shared.firstDayInWeek)
                entries.append(MacCalendarWidgetEntry(
                    date: entryDate,
                    configuration: configuration,
                    calendarData: calendarData,
                    showWeekNumber: shared.showWeekNumber,
                    firstDayInWeek: shared.firstDayInWeek
                ))
            }
            
            return Timeline(entries: entries, policy: .atEnd)
        }
    }
    
    private func calculateDisplayDate(for referenceDate: Date = Date(), context: Context, customOffset: Int? = nil, monthOffset: Int = 0) -> Date {
        if context.family == .systemSmall || context.family == .systemMedium {
            return referenceDate
        }
        
        let offset = customOffset ?? monthOffset
        if offset == 0 {
            return referenceDate
        }
        return Calendar.current.date(byAdding: .month, value: offset, to: referenceDate) ?? referenceDate
    }
}

struct MacCalendarWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let calendarData: WidgetCalendarData
    let showWeekNumber: Bool
    let firstDayInWeek: FirstDayInWeek
}

struct MacCalendarWidgetContentView : View {
    var entry: MacCalendarWidgetProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            MacCalendarSmallWidgetView(calendarData: entry.calendarData, firstDayInWeek: entry.firstDayInWeek)
        case .systemMedium:
            MacCalendarMediumWidgetView(calendarData: entry.calendarData, firstDayInWeek: entry.firstDayInWeek)
        case .systemLarge:
            MacCalendarLargeWidgetView(calendarData: entry.calendarData, showWeekNumber: entry.showWeekNumber, firstDayInWeek: entry.firstDayInWeek)
        default:
            MacCalendarSmallWidgetView(calendarData: entry.calendarData, firstDayInWeek: entry.firstDayInWeek)
        }
    }
}

struct MacCalendarSmallWidgetView: View {
    let calendarData: WidgetCalendarData
    let firstDayInWeek: FirstDayInWeek
    var today: WidgetCalendarDay? { calendarData.days.first(where: { $0.isToday }) }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                if let today = today {
                    Text("星期\(weekdayChar(weekday: today.weekDay))")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            if let today = today {
                Text("\(today.dayOfMonth)")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if let today = today {
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(format: "%d年%d月(第%d周)", calendarData.year, calendarData.month, WidgetDataHelper.getWeekNumber(for: today.date, firstDayInWeek: firstDayInWeek)))
                        .font(.system(size: 13))
                        .foregroundColor(.primary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    
                    Text("\(LunarDateHelper.getGanzhiYear(for: today.date))(\(LunarDateHelper.getZodiac(for: today.date)))\(LunarDateHelper.getLunarMonth(for: today.date))\(LunarDateHelper.getLunarDay(for: today.date))")
                        .font(.system(size: 13))
                        .foregroundColor(.primary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(0)
    }
    
    private func weekdayChar(weekday: Int) -> String {
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        return weekdays[weekday - 1]
    }
}

struct MacCalendarMediumWidgetView: View {
    let calendarData: WidgetCalendarData
    let firstDayInWeek: FirstDayInWeek
    
    var currentWeekDays: [WidgetCalendarDay] {
        guard let todayIndex = calendarData.days.firstIndex(where: { $0.isToday }) else { return [] }
        let startOfWeek = todayIndex - (todayIndex % 7)
        let endOfWeek = min(startOfWeek + 7, calendarData.days.count)
        return Array(calendarData.days[startOfWeek..<endOfWeek])
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                Text(verbatim: "\(calendarData.year)年\(calendarData.month)月")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
            }
            .frame(height: 35)
            
            Spacer()
            
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    ForEach(calendarData.weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                    ForEach(currentWeekDays, id: \.date) { day in
                        MacCalendarDayCellView(day: day)
                    }
                }
            }
            
            Spacer()
            
            if let today = calendarData.days.first(where: { $0.isToday }) {
                HStack(spacing: 5) {
                    Capsule()
                        .fill(Color.red)
                        .frame(width: 3, height: 12)
                    
                    Text(verbatim: String(format: "%d年%d月%d日（第%d周）%@（%@）%@%@", calendarData.year, calendarData.month, today.dayOfMonth, WidgetDataHelper.getWeekNumber(for: today.date, firstDayInWeek: firstDayInWeek), LunarDateHelper.getGanzhiYear(for: today.date), LunarDateHelper.getZodiac(for: today.date), LunarDateHelper.getLunarMonth(for: today.date), LunarDateHelper.getLunarDay(for: today.date)))
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.6))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct MacCalendarLargeWidgetView: View {
    let calendarData: WidgetCalendarData
    let showWeekNumber: Bool
    let firstDayInWeek: FirstDayInWeek
    
    var columns: [GridItem] {
        let count = showWeekNumber ? 8 : 7
        return Array(repeating: GridItem(.flexible()), count: count)
    }
    
    var weekGroups: [[WidgetCalendarDay]] {
        stride(from: 0, to: calendarData.days.count, by: 7).map {
            Array(calendarData.days[$0..<min($0 + 7, calendarData.days.count)])
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(intent: ChangeMonthIntent(offset: -1)) {
                    Image(systemName: "chevron.compact.backward")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                
                Button(intent: ResetMonthIntent()) {
                    Text(verbatim: "\(calendarData.year)年\(calendarData.month)月")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                
                Button(intent: ChangeMonthIntent(offset: 1)) {
                    Image(systemName: "chevron.compact.forward")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 8)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 35)
            
            Spacer()
            
            HStack(spacing: 0) {
                if showWeekNumber {
                    Text("")
                        .frame(width: 30)
                }
                ForEach(calendarData.weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, minHeight: 35)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekGroups.indices, id: \.self) { index in
                    let group = weekGroups[index]
                    let weekNum = WidgetDataHelper.getWeekNumber(for: group.first?.date ?? Date(), firstDayInWeek: firstDayInWeek)
                    
                    if showWeekNumber {
                        Text("\(weekNum)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.5))
                            .frame(width: 30, height: 35)
                    }
                    
                    ForEach(group, id: \.date) { day in
                        MacCalendarDayCellView(day: day)
                    }
                }
            }
            .frame(minHeight: 6 * 35, alignment: .top)
            
            Spacer()
            
            let today = Date()
            let todayYear = Calendar.current.component(.year, from: today)
            let todayMonth = Calendar.current.component(.month, from: today)
            let todayDay = Calendar.current.component(.day, from: today)
            
            HStack(spacing: 5) {
                Capsule()
                    .fill(Color.red)
                    .frame(width: 3, height: 12)
                
                Text(verbatim: String(format: "%d年%d月%d日（第%d周）%@（%@）%@%@", todayYear, todayMonth, todayDay, WidgetDataHelper.getWeekNumber(for: today, firstDayInWeek: firstDayInWeek), LunarDateHelper.getGanzhiYear(for: today), LunarDateHelper.getZodiac(for: today), LunarDateHelper.getLunarMonth(for: today), LunarDateHelper.getLunarDay(for: today)))
                    .font(.system(size: 12))
                    .foregroundColor(.primary.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MacCalendarDayCellView: View {
    let day: WidgetCalendarDay
    
    var body: some View {
        ZStack(alignment: .center) {
            if day.isToday {
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 33, height: 33)
            }
            
            if let offday = day.offday {
                Text(offday ? "休" : "班")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .frame(width: 14, height: 14)
                    .background(offday ? .red : .gray)
                    .cornerRadius(3)
                    .offset(x: 12, y: -12)
            }
            
            VStack(spacing: -2) {
                Text("\(day.dayOfMonth)")
                    .font(.system(size: 12, weight: day.isToday ? .medium : .regular))
                    .foregroundColor(day.isToday ? .white : (day.isCurrentMonth ? .primary : .gray.opacity(0.5)))
                
                Text(!day.holidays.isEmpty ? day.holidays[0] : (day.solarTerm ?? day.shortLunar))
                    .font(.system(size: 8))
                    .foregroundColor(day.isToday ? .white : (day.isCurrentMonth ? .primary : .gray.opacity(0.5)))
                    .lineLimit(1)
            }
            .frame(height: 35)
        }
        .frame(width: 35, height: 35, alignment: .center)
    }
}

struct MacCalendarWidget: Widget {
    let kind: String = "MacCalendarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: MacCalendarWidgetProvider()) { entry in
            MacCalendarWidgetContentView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("MacCalendar")
        .description("将农历和节假日添加到桌面。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}