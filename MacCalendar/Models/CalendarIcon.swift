//
//  CalendarIcon.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI
import Combine
import AppKit

class CalendarIcon: ObservableObject {
    @Published var displayOutput: String = ""
    
    private var timer: Timer?
    private let dateFormatter = DateFormatter()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshTimer()
            }
            .store(in: &cancellables)
        
        // 监听系统时间改变（手动修改时间）
        NotificationCenter.default
            .publisher(for: NSNotification.Name.NSSystemClockDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshTimer()
            }
            .store(in: &cancellables)
        
        // 监听系统唤醒
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshTimer()
            }
            .store(in: &cancellables)
        
        refreshTimer()
    }
    
    deinit {
        stopTimer()
    }
    
    private func refreshTimer() {
        stopTimer()
        updateDisplayOutput()
        scheduleNextTick()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func scheduleNextTick() {
        let (interval, component) = getUpdateInterval()
        
        // 如果是 .icon 模式直接返回
        guard interval > 0, component != .nanosecond else { return }
        
        let now = Date()
        let calendar = Calendar.current
        var timeUntilNextTick: TimeInterval = 0
        
        switch component {
        case .second:
            // 对齐到下一秒
            let nanoseconds = calendar.component(.nanosecond, from: now)
            timeUntilNextTick = (1_000_000_000.0 - Double(nanoseconds)) / 1_000_000_000.0
            
        case .minute:
            // 对齐到下一分
            let components = calendar.dateComponents([.second, .nanosecond], from: now)
            let seconds = Double(components.second ?? 0)
            let nanoseconds = Double(components.nanosecond ?? 0) / 1_000_000_000.0
            timeUntilNextTick = 60.0 - (seconds + nanoseconds)
            
        case .day:
            // 对齐下一天
            let startOfToday = calendar.startOfDay(for: now)
            if let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) {
                timeUntilNextTick = startOfTomorrow.timeIntervalSince(now)
            } else {
                timeUntilNextTick = 86400
            }
            
        default:
            // 为了防止死锁，默认按秒更新
            timeUntilNextTick = 1.0
        }
        
        // 强制增加一点延迟，防止 Timer 狂转
        if timeUntilNextTick < 0.05 {
            timeUntilNextTick += 0.1
        }
        
        self.timer = Timer(timeInterval: timeUntilNextTick, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateDisplayOutput()
                self?.scheduleNextTick()
            }
        }
        
        // 加入 RunLoop，防止菜单滚动时计时器暂停
        if let timer = self.timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func getUpdateInterval() -> (interval: TimeInterval, component: Calendar.Component) {
        switch SettingsManager.displayMode {
        case .icon:
            return (0, .nanosecond) // 不更新
            
        case .time:
            return (1.0, .second) // 秒级更新
            
        case .date:
            return (86400, .day) // 天级更新
            
        case .custom:
            let format = SettingsManager.customFormatString
            
            // 如果包含 s S，按秒更新
            if format.contains("s") || format.contains("S") {
                return (1.0, .second)
            }
            // 如果包含 m H h，按分钟更新
            else if format.contains("m") || format.contains("h") || format.contains("H") || format.contains("a") {
                return (60.0, .minute)
            }
            // 按天更新
            else {
                return (86400, .day)
            }
        }
    }
    
    private func updateDisplayOutput() {
        dateFormatter.calendar = Calendar.autoupdatingCurrent
        dateFormatter.locale = Locale.autoupdatingCurrent
        
        switch SettingsManager.displayMode {
        case .icon:
            displayOutput = ""
        case .date:
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMd", options: 0, locale: Locale.current)
            displayOutput = dateFormatter.string(from: Date())
        case .time:
            dateFormatter.dateFormat = "HH:mm:ss"
            displayOutput = dateFormatter.string(from: Date())
        case .custom:
            dateFormatter.dateFormat = SettingsManager.customFormatString
            
            if SettingsManager.customFormatString.contains("w") {
                var calendar = Calendar(identifier: .iso8601)
                // ISO 8601 标准：周一为第一天，第一周至少4天
                calendar.firstWeekday = 2 // 2 代表周一
                calendar.minimumDaysInFirstWeek = 4
                dateFormatter.calendar = calendar
            }
            
            displayOutput = dateFormatter.string(from: Date())
        }
    }
}
