//
//  CalendarIcon.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import Foundation
import Combine

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
                self?.manageTimer()
            }
            .store(in: &cancellables)
        
        manageTimer()
    }

    deinit {
        stopTimer()
    }

    private func manageTimer() {
        stopTimer()
        
        let (interval, component) = getUpdateInterval()
        
        // 如果是 .icon 模式 (interval == 0)，停止并立即更新
        guard interval > 0, component != .nanosecond else {
            updateDisplayOutput()
            return
        }
        
        // 计算第一次 Tick的时间
        let now = Date()
        let calendar = Calendar.current
        var timeUntilNextTick: TimeInterval

        switch component {
        case .second:
            // 计算到下一个整秒还差多少纳秒
            let nanoseconds = calendar.component(.nanosecond, from: now)
            timeUntilNextTick = (1_000_000_000.0 - Double(nanoseconds)) / 1_000_000_000.0
            
        case .minute:
            // 计算到下一个整分钟还差多少秒
            let components = calendar.dateComponents([.second, .nanosecond], from: now)
            let seconds = Double(components.second ?? 0)
            let nanoseconds = Double(components.nanosecond ?? 0) / 1_000_000_000.0
            timeUntilNextTick = 60.0 - (seconds + nanoseconds)

        case .day:
            // 计算到明天 00:00 还差多少秒
            let startOfToday = calendar.startOfDay(for: now)
            let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            timeUntilNextTick = startOfTomorrow.timeIntervalSince(now)
            
        default:
            return
        }
        
        // 避免 timeUntilNextTick 几乎为 0 导致重复触发
        if timeUntilNextTick < 0.001 {
            timeUntilNextTick += interval
        }
        
        updateDisplayOutput()

        self.timer = Timer(timeInterval: timeUntilNextTick, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateDisplayOutput()
                self?.scheduleRepeatingTimer(interval: interval)
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func scheduleRepeatingTimer(interval: TimeInterval) {
        stopTimer()
        
        self.timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateDisplayOutput()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func getUpdateInterval() -> (interval: TimeInterval, component: Calendar.Component) {
        switch SettingsManager.displayMode {
        case .icon:
            return (0, .nanosecond)
            
        case .time:
            return (1.0, .second)
            
        case .date:
            return (60 * 60 * 24, .day)
            
        case .custom:
            let format = SettingsManager.customFormatString
            if format.contains("s") {
                return (1.0, .second)
            } else if format.contains("m") || format.contains("h") || format.contains("H") || format.contains("a") {
                return (60.0, .minute)
            } else {
                return (60 * 60 * 24, .day)
            }
        }
    }

    private func updateDisplayOutput() {
        dateFormatter.locale = Locale.current
        
        switch SettingsManager.displayMode {
        case .icon:
            displayOutput = ""
        case .date:
            dateFormatter.dateFormat = "yy年MM月dd日"
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
