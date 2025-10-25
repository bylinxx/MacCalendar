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
        timer?.invalidate()
    }

    private func manageTimer() {
        let mode = SettingsManager.displayMode
        
        if mode == .icon {
            if timer != nil {
                stopTimer()
            }
        } else {
            if timer == nil {
                startTimer()
            }
        }
        
        updateDisplayOutput()
    }
    
    private func startTimer() {
        guard timer == nil else { return }
        
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDisplayOutput()
        }
        
        updateDisplayOutput()
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateDisplayOutput() {
        dateFormatter.locale = Locale.current
        
        switch SettingsManager.displayMode {
        case .icon:
            displayOutput = ""
        case .date:
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            displayOutput = dateFormatter.string(from: Date())
        case .time:
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .medium
            displayOutput = dateFormatter.string(from: Date())
        case .custom:
            dateFormatter.dateFormat = SettingsManager.customFormatString
            displayOutput = dateFormatter.string(from: Date())
        }
    }
}
