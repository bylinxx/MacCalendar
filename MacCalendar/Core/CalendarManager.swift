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
    
    // 日历数据缓存，键为月份的开始日期
    private var calendarDataCache: [Date: [CalendarDay]] = [:]
    // 事件缓存，键为日期范围的开始和结束日期的字符串表示
    private var eventsCache: [String: [CalendarEvent]] = [:]
    
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
        if SettingsManager.firstDayInWeek == .monday {
            weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        }
        else {
            weekdays = ["周日","周一", "周二", "周三", "周四", "周五", "周六"]
        }
        
        if SettingsManager.showWeekNumber {
            weekdays.insert("", at: 0)
        }
        Task{
            await goToCurrentMonth()
        }
    }
    func resetToToday() {
        Task {
            calendarDataCache.removeAll()
            await goToCurrentMonth()
            getSelectedDayEvents(date: Date())
        }
    }
    
    func goToCurrentMonth() async {
        selectedMonth = Date()
        await loadCalendarDays(date: selectedMonth)
    }
    
    func goToCustomizeMonth(year: Int, month: Int) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        if let targetDate = Calendar.current.date(from: components) {
            
            selectedMonth = targetDate
            Task {
                await loadCalendarDays(date: targetDate)
            }
        }
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
        let _calendarDays = calendarDays.filter { $0.is_weekNumber == false }
        if let day = _calendarDays.first(where: { Calendar.Based.isDate($0.date!, inSameDayAs: date) }) {
            selectedDayLunar = day.full_lunar ?? ""
        } else {
            selectedDayLunar = ""
        }
        
        var events: [CalendarEvent] = []
        if let day = _calendarDays.first(where: { Calendar.Based.isDate($0.date!, inSameDayAs: date) }) {
            events = day.events
        }
        
        if SettingsManager.showDaysIndicator {
            let dayIndicatorEvent = createDaysIndicatorEvent(date: date)
            selectedDayEvents = [dayIndicatorEvent] + events
        } else {
            selectedDayEvents = events
        }
    }
    
    private func createDaysIndicatorEvent(date: Date) -> CalendarEvent {
        let greenColor = Color(red: 0.2, green: 0.7, blue: 0.3)
        return CalendarEvent(
            id: "days-indicator-\(date.timeIntervalSince1970)",
            calendar_title: nil,
            allowsModify: false,
            title: DateHelper.daysFromToday(to: date),
            location: nil,
            isAllDay: true,
            startDate: date,
            endDate: date,
            color: CodableColor(color: greenColor),
            notes: nil,
            url: nil,
            organizer: nil,
            attendees: nil
        )
    }
    
    func refreshEvents() {
        // 清除缓存，确保获取最新数据
        calendarDataCache.removeAll()
        eventsCache.removeAll()
        
        Task {
            await loadCalendarDays(date: selectedMonth)
            getSelectedDayEvents(date: selectedDay)
        }
    }
    
    func loadCalendarDays(date: Date) async {
        await requestAccessIfNeeded()
        
        // 获取月份的开始日期作为缓存键
        guard let monthStart = calendar.dateInterval(of: .month, for: date)?.start else {
            return
        }
        
        // 检查缓存中是否存在该月份的数据
        if let cachedDays = calendarDataCache[monthStart] {
            self.calendarDays = cachedDays
            return
        }
        
        guard authorizationStatus == .fullAccess else {
            let days = await generateCalendarGrid(for: date, events: [:])
            // 缓存无事件的日历数据
            calendarDataCache[monthStart] = days
            self.calendarDays = days
            return
        }
        
        let firstDayInWeek = SettingsManager.firstDayInWeek == .monday ? 2 : 1
        guard let gridDates = CalendarGridHelper.generateDateGrid(for: date, firstDayInWeek: firstDayInWeek),
              let firstDate = gridDates.first,
              let lastDate = gridDates.last else {
            return
        }
        
        let events = await getEventsByDate(from: firstDate, to: lastDate)
        
        let groupedEvents = groupEventsByDay(events: events)
        
        let days = await generateCalendarGrid(for: date, events: groupedEvents)
        // 缓存日历数据
        calendarDataCache[monthStart] = days
        self.calendarDays = days
    }
    
    func loadCalendarInfo() async {
        await requestAccessIfNeeded()
        guard authorizationStatus == .fullAccess else { return }
        
        let allEKCalendars = eventStore.calendars(for: .event)
        
        let savedIDs = getFilterCalendarIds()
        
        var effectiveIDs = Set<String>()
        if let savedIDs = savedIDs {
            effectiveIDs = savedIDs
            for calendar in allEKCalendars {
                effectiveIDs.insert(calendar.calendarIdentifier)
            }
        } else {
            effectiveIDs = Set(allEKCalendars.map { $0.calendarIdentifier })
        }
        
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
                Task {
                    await self?.loadCalendarInfo()
                    self?.refreshEvents()
                }
            }
            .store(in: &cancellables)
    }
    
    func requestAccessIfNeeded() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        authorizationStatus = status
        
        guard status == .notDetermined else { return }
        
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationStatus = granted ? .fullAccess : .denied
        } catch {
            authorizationStatus = .denied
        }
    }
    func getDisplayName(participant: EKParticipant) -> String {
        let rawName = participant.name ?? ""
        if rawName.contains("@") {
            let components = rawName.components(separatedBy: "@")
            if let firstPart = components.first, !firstPart.isEmpty {
                return firstPart
            }
        }
        return rawName
    }
    private func getEventsByDate(from startDate: Date, to endDate: Date) async -> [CalendarEvent] {
        // 检查缓存中是否存在该日期范围的事件
        let cacheKey = "\(startDate.timeIntervalSince1970)-\(endDate.timeIntervalSince1970)"
        if let cachedEvents = eventsCache[cacheKey] {
            return cachedEvents
        }
        
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
        
        let events = ekEvents.map { ekEvent in
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
                url: ekEvent.url,
                organizer: ekEvent.organizer.map { CalendarEventPerson(name: $0.name, url: $0.url) },
                attendees: ekEvent.attendees?
                    .map { participant in
                        let prettyName = getDisplayName(participant: participant)
                        return CalendarEventPerson(name: prettyName, url: participant.url)
                    }
                    .sorted { person1, person2 in
                        let name1 = person1.name ?? ""
                        let name2 = person2.name ?? ""
                        return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
                    }
                ?? []
            )
        }
        
        // 缓存事件数据
        eventsCache[cacheKey] = events
        return events
    }
    
    private func setFilterCalendarIds() {
        let selectedIDs = calendarInfos.filter { $0.isSelected }.map { $0.id }
        
        if let data = try? JSONEncoder().encode(selectedIDs) {
            SettingsManager.filterCalendar = data
        }
        
        refreshEvents()
    }
    
    private func getFilterCalendarIds() -> Set<String>? {
        if let decodedIDs = try? JSONDecoder().decode([String].self, from: SettingsManager.filterCalendar), !decodedIDs.isEmpty {
            return Set(decodedIDs)
        }
        return nil
    }
    
    private func groupEventsByDay(events: [CalendarEvent]) -> [Date: [CalendarEvent]] {
        var groupedEvents = [Date: [CalendarEvent]]()
        
        for event in events {
            var currentDay = calendar.startOfDay(for: event.startDate)
            while event.endDate > currentDay {
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                    break
                }
                if event.startDate < nextDay {
                    groupedEvents[currentDay, default: []].append(event)
                }
                currentDay = nextDay
            }
        }
        return groupedEvents
    }
    

    private func generateCalendarGrid(for date: Date, events: [Date: [CalendarEvent]]) async -> [CalendarDay] {
        let firstDayInWeek = SettingsManager.firstDayInWeek == .monday ? 2 : 1
        
        let basicDays = CalendarGridHelper.generateBasicCalendarData(for: date, firstDayInWeek: firstDayInWeek, today: Date())
        
        var newDays: [CalendarDay] = []
        
        for day in basicDays {
            let dayStart = Calendar.Based.startOfDay(for: day.date)
            let dayEvents = events[dayStart] ?? []
            
            newDays.append(CalendarDay(
                is_today: day.isToday,
                is_currentMonth: day.isCurrentMonth,
                date: day.date,
                short_lunar: day.shortLunar,
                full_lunar: day.fullLunar,
                holidays: day.holidays,
                solar_term: day.solarTerm,
                offday: day.offday,
                events: dayEvents
            ))
        }
        
        var _newDays: [CalendarDay] = []
        if SettingsManager.showWeekNumber {
            let day_groups = stride(from: 0, to: newDays.count, by: 7).map {
                Array(newDays[$0..<min($0 + 7, newDays.count)])
            }
            
            for group in day_groups {
                let firstDayInWeek = SettingsManager.firstDayInWeek == .monday ? 2 : 1
                let weekNum = CalendarGridHelper.calculateWeekOfYear(for: group.first?.date, firstDayInWeek: firstDayInWeek)
                
                let weekItem = CalendarDay(is_weekNumber: true, weekNumber: weekNum)
                
                _newDays.append(weekItem)
                _newDays.append(contentsOf: group)
            }
        } else {
            _newDays = newDays
        }
        
        return _newDays
    }
}
