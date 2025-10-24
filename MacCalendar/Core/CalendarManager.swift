//
//  CalendarManager.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import Combine
import SwiftUI
import EventKit

@MainActor
class CalendarManager: ObservableObject {
    @Published var calendarDays: [CalendarDay] = []
    @Published var calendarInfos: [CalendarInfo] = []
    @Published var selectedMonth: Date = Date()
    @Published var selectedDay: Date = Date()
    @Published var selectedDayLunar:String = ""
    @Published var selectedDayEvents: [CalendarEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var weekdays:[String] = []
    
    private let calendar = Calendar.Based
    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await loadCalendarDays(date: selectedMonth)
            
            getSelectedDayEvents(date: Date())
            
            await loadCalendarInfo()
        }
        // 订阅日历数据库变化的通知
        subscribeToCalendarChanges()
        
        $calendarInfos
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.setFilterCalendarIds()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateWeekdays()
            }
            .store(in: &cancellables)
    }
    private func updateWeekdays() {
        let newFirstDay = SettingsManager.firstDayInWeek
        let currentFirstDay: FirstDayInWeek = (weekdays.first == "周一") ? .monday : .sunday
        if newFirstDay == currentFirstDay && !weekdays.isEmpty {
            return
        }
        
        if newFirstDay == .monday {
            weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        }
        else {
            weekdays = ["周日","周一", "周二", "周三", "周四", "周五", "周六"]
        }
        
        goToCurrentMonth()
    }
    func resetToToday() {
        if !calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) {
            goToCurrentMonth()
        }
        getSelectedDayEvents(date: Date())
    }
    
    func goToCurrentMonth(){
        selectedMonth = Date()
        Task { await loadCalendarDays(date: selectedMonth) }
    }
    
    func goToNextMonth() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = nextMonth
            Task { await loadCalendarDays(date: selectedMonth) }
        }
    }
    
    func goToPreviousMonth() {
        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = prevMonth
            Task { await loadCalendarDays(date: selectedMonth) }
        }
    }
    
    func getSelectedDayEvents(date: Date) {
        selectedDay = date
        if let day = calendarDays.first(where: { Calendar.Based.isDate($0.date, inSameDayAs: date) }) {
            selectedDayLunar = day.full_lunar ?? ""
        } else {
            selectedDayLunar = ""
        }
        
        if let day = calendarDays.first(where: { Calendar.Based.isDate($0.date, inSameDayAs: date) }) {
            selectedDayEvents = day.events
        } else {
            selectedDayEvents = []
        }
    }
    
    func refreshEvents() {
        Task {
            await loadCalendarDays(date: selectedMonth)
            getSelectedDayEvents(date: selectedDay)
        }
    }
    
    func loadCalendarDays(date: Date) async {
        await requestAccess()
        
        guard authorizationStatus == .fullAccess else {
            print("日历权限未授予，仅显示日期。")
            generateCalendarGrid(for: date, events: [:])
            return
        }
        
        guard let gridDates = generateDateGrid(for: date),
              let firstDate = gridDates.first,
              let lastDate = gridDates.last else {
            return
        }
        
        let events = await getEventsByDate(from: firstDate, to: lastDate)
        
        let groupedEvents = groupEventsByDay(events: events)
        
        generateCalendarGrid(for: date, events: groupedEvents)
    }
    
    func loadCalendarInfo() async {
        if authorizationStatus == .notDetermined { await requestAccess() }
        guard authorizationStatus == .fullAccess else { return }
        
        let allEKCalendars = eventStore.calendars(for: .event)
        
        let effectiveIDs = getFilterCalendarIds() ?? Set(allEKCalendars.map { $0.calendarIdentifier })
        
        let calendarInfos = allEKCalendars.map { calendar in
            CalendarInfo(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: Color(calendar.cgColor),
                isSelected: effectiveIDs.contains(calendar.calendarIdentifier)
            )
        }
        
        self.calendarInfos = calendarInfos.sorted { $0.title < $1.title }
    }
    
    func updateEvent(event: CalendarEvent) async throws {
        guard authorizationStatus == .fullAccess else {
            throw CalendarError.noPermission
        }
        
        guard let ekEvent = eventStore.event(withIdentifier: event.id) else {
            throw CalendarError.eventNotFound
        }
        
        guard ekEvent.calendar.allowsContentModifications else {
            throw CalendarError.calendarNotModifiable
        }
        
        ekEvent.title = event.title
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay
        ekEvent.location = event.location
        ekEvent.notes = event.notes
        ekEvent.url = event.url
        
        do {
            try eventStore.save(ekEvent, span: .thisEvent, commit: true)
            refreshEvents()
        } catch {
            throw CalendarError.catchError(error)
        }
    }
    
    func deleteEvent(withId eventId: String) async throws {
        guard authorizationStatus == .fullAccess else {
            throw CalendarError.noPermission
        }
        
        guard let ekEvent = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }
        
        guard ekEvent.calendar.allowsContentModifications else {
            throw CalendarError.calendarNotModifiable
        }
        
        do {
            try eventStore.remove(ekEvent, span: .thisEvent, commit: true)
            refreshEvents()
        } catch {
            throw CalendarError.catchError(error)
        }
    }
    
    // MARK: 私有辅助类
    
    private func subscribeToCalendarChanges() {
        NotificationCenter.default
            .publisher(for: .EKEventStoreChanged, object: eventStore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.refreshEvents()
            }
            .store(in: &cancellables)
    }
    
    private func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationStatus = granted ? .fullAccess : .denied
        } catch {
            authorizationStatus = .denied
            print("请求日历访问权限时出错: \(error.localizedDescription)")
        }
        
        if authorizationStatus == .notDetermined {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }
    
    private func getEventsByDate(from startDate: Date, to endDate: Date) async -> [CalendarEvent] {
        var calendarsToFetch: [EKCalendar]? = nil
        
        if let ids = getFilterCalendarIds() {
            let allCalendars = eventStore.calendars(for: .event)
            calendarsToFetch = allCalendars.filter { ids.contains($0.calendarIdentifier) }
        }
        if calendarsToFetch == nil || calendarsToFetch!.isEmpty{
            return []
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendarsToFetch)
        let ekEvents = eventStore.events(matching: predicate)
        
        return ekEvents.map { ekEvent in
            CalendarEvent(
                id: ekEvent.eventIdentifier,
                calendar_title: ekEvent.calendar.title,
                allowsModify: ekEvent.calendar.allowsContentModifications,
                title: ekEvent.title,
                location:ekEvent.location,
                isAllDay: ekEvent.isAllDay,
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                color: CodableColor(color: Color(nsColor: ekEvent.calendar.color)),
                notes: ekEvent.notes,
                url: ekEvent.url
            )
        }
    }
    
    private func setFilterCalendarIds() {
        let selectedIDs = calendarInfos.filter { $0.isSelected }.map { $0.id }
        
        if let data = try? JSONEncoder().encode(selectedIDs) {
            SettingsManager.filterCalendar = data
        }
        
        refreshEvents()
    }
    
    private func getFilterCalendarIds() -> Set<String>? {
        if let decodedIDs = try? JSONDecoder().decode([String].self, from: SettingsManager.filterCalendar) {
            if SettingsManager.filterCalendar.isEmpty {
                return nil
            }
            return Set(decodedIDs)
        }
        return nil
    }
    
    private func groupEventsByDay(events: [CalendarEvent]) -> [Date: [CalendarEvent]] {
        var groupedEvents = [Date: [CalendarEvent]]()
        for event in events {
            let dayOfEvent = calendar.startOfDay(for: event.startDate)
            groupedEvents[dayOfEvent, default: []].append(event)
        }
        return groupedEvents
    }
    
    private func generateDateGrid(for date: Date) -> [Date]? {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return nil }
        
        var gridDates: [Date] = []
        let firstDayOfMonth = monthInterval.start
        let range = calendar.range(of: .day, in: .month, for: date)!
        
        // 上个月补齐
        let firstWeekday = SettingsManager.firstDayInWeek == FirstDayInWeek.monday ? 2 : 1
        let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetToMonday = (weekdayOfFirst - firstWeekday + 7) % 7
        if offsetToMonday > 0 {
            for i in stride(from: offsetToMonday, to: 0, by: -1) {
                if let prevDay = calendar.date(byAdding: .day, value: -i, to: firstDayOfMonth) {
                    gridDates.append(prevDay)
                }
            }
        }
        
        for i in 0..<range.count {
            if let day = calendar.date(byAdding: .day, value: i, to: firstDayOfMonth) {
                gridDates.append(day)
            }
        }
        
        // 下个月补齐
        let totalDays = gridDates.count
        let remaining = totalDays % 7
        if remaining > 0 {
            let lastDay = gridDates.last!
            for i in 1...(7 - remaining) {
                if let nextDay = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    gridDates.append(nextDay)
                }
            }
        }
        
        return gridDates
    }
    
    private func generateCalendarGrid(for date: Date, events: [Date: [CalendarEvent]]) {
        let lunarCalendar = Calendar(identifier: .chinese)
        let lunarMonthSymbols = ["正月","二月","三月","四月","五月","六月","七月","八月","九月","十月","冬月","腊月"]
        let lunarDaySymbols = ["初一","初二","初三","初四","初五","初六","初七","初八","初九","初十", "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十", "廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"]
        
        guard let gridDates = generateDateGrid(for: date) else { return }
        
        var newDays: [CalendarDay] = []
        
        for day in gridDates {
            let lunarYear = lunarCalendar.component(.year, from: day)
            let lunarMonth = lunarCalendar.component(.month, from: day)
            let lunarDay = lunarCalendar.component(.day, from: day)
            var daysInLunarMonth = 0
            if let range = lunarCalendar.range(of: .day, in: .month, for: day) {
                daysInLunarMonth = range.count
            }
            
            let ganzhiYear = LunarDateHelper.getGanzhiYear(for: day)
            let zodiac = LunarDateHelper.getZodiac(for: day)
            let short_lunar = (lunarDay == 1) ? lunarMonthSymbols[lunarMonth - 1] : lunarDaySymbols[lunarDay - 1]
            let full_lunar = "\(ganzhiYear)年 (\(zodiac)) \(lunarMonthSymbols[lunarMonth - 1])\(lunarDaySymbols[lunarDay - 1])"
            
            let dayStart = calendar.startOfDay(for: day)
            let dayEvents = events[dayStart] ?? []
            
            let solar_term = SolarTermHelper.getSolarTerm(for: day)
            
            let holidays = HolidayHelper.getHolidays(date: day, lunarMonth: lunarMonth, lunarDay: lunarDay, daysInLunarMonth: daysInLunarMonth)
            
            newDays.append(CalendarDay(date: day, short_lunar: short_lunar,full_lunar: full_lunar,holidays: holidays,solar_term: solar_term , events: dayEvents))
        }
        
        self.calendarDays = newDays
    }
}
