//
//  AppDelegate.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject,NSApplicationDelegate, NSWindowDelegate {
    static var shared:AppDelegate?
    
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var settingsWindow: NSWindow?
    var eventEditWindow:NSWindow?
    var hostingController: NSHostingController<AnyView>?
    lazy var calendarManager: CalendarManager = CalendarManager()
    
    private var resizeWorkItem:DispatchWorkItem?
    private var calendarIcon = CalendarIcon()
    private var cancellables = Set<AnyCancellable>()
    private var isPopoverAnimating = false
    
    private var appearanceObserver: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        _ = calendarManager
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked)
            button.target = self
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            button.isHidden = false
            // 初始显示图标：根据当前日期显示对应日期的符号
            let day = Calendar.current.component(.day, from: Date())
            let symbolName = "\(day).calendar"
            let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Calendar")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            } else if let image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            }
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command) && event.characters == "," {
                self?.showSettingsWindow()
                return nil
            }
            return event
        }
        
        calendarIcon.$displayOutput
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                guard let self = self, let button = self.statusItem.button else { return }
                
                // 移除之前添加的自定义子视图
                button.subviews.forEach { subview in
                    if subview is DoubleLineStatusView {
                        subview.removeFromSuperview()
                    }
                }
                
                if output == "" {
                    // 图标模式：根据当前日期显示对应日期的符号
                    button.title = ""
                    button.attributedTitle = NSAttributedString(string: "")
                    
                    let day = Calendar.current.component(.day, from: Date())
                    let symbolName = "\(day).calendar"
                    let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
                    
                    if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Calendar")?.withSymbolConfiguration(config) {
                        image.isTemplate = true
                        button.image = image
                    } else {
                        // 如果没有对应日期的图标，回退到默认日历图标
                        if let image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")?.withSymbolConfiguration(config) {
                            image.isTemplate = true
                            button.image = image
                        }
                    }
                    self.statusItem.length = NSStatusItem.squareLength
                } else if output.contains("\n") {
                    // 双行显示，使用自定义视图添加到按钮上（按钮本身处理点击）
                    let lines = output.components(separatedBy: "\n")
                    let topText = lines.count > 0 ? lines[0] : ""
                    let bottomText = lines.count > 1 ? lines[1] : ""
                    
                    // 创建双行视图（不处理点击，由按钮本身处理）
                    let doubleLineView = DoubleLineStatusView(topText: topText, bottomText: bottomText)
                    
                    // 清空按钮内容
                    button.image = nil
                    button.title = ""
                    button.attributedTitle = NSAttributedString(string: "")
                    
                    // 设置按钮尺寸
                    self.statusItem.length = doubleLineView.frame.width
                    
                    // 设置视图位置，两行居中显示（两行边界在中间）
                    let centerY = (button.bounds.height - doubleLineView.frame.height) / 2
                    doubleLineView.frame.origin = NSPoint(
                        x: (button.bounds.width - doubleLineView.frame.width) / 2,
                        y: centerY
                    )
                    
                    // 添加到按钮（按钮本身处理点击）
                    button.addSubview(doubleLineView)
                    
                } else {
                    // 单行显示
                    button.image = nil
                    button.attributedTitle = NSAttributedString(string: "")
                    button.title = output
                    self.statusItem.length = NSStatusItem.variableLength
                }
                
                button.sizeToFit()
            }
            .store(in: &cancellables)
        
        // 立即更新显示
        calendarIcon.updateDisplayOutput()
        
        popover = NSPopover()
        popover.behavior = .transient
        
        let contentView = ContentView(calendarManager: self.calendarManager)
            .onPreferenceChange(SizeKey.self){ size in
                guard size != .zero else { return }
                
                self.resizeWorkItem?.cancel()
                
                let workItem = DispatchWorkItem{
                    guard self.popover.isShown else { return }
                    self.popover.contentSize = size
                }
                
                self.resizeWorkItem = workItem
                // 延迟80ms执行
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)
            }
        hostingController = NSHostingController(rootView: AnyView(contentView))
        popover.contentViewController = hostingController
        
        updateAppearance()
        
        // 监听外观设置变化
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAppearance()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(closePopover), name: NSApplication.didResignActiveNotification, object: nil)
    }
    
    private func updateAppearance() {
        let mode = SettingsManager.appearanceMode
        popover.appearance = mode.nsAppearance
        settingsWindow?.appearance = mode.nsAppearance
        eventEditWindow?.appearance = mode.nsAppearance
    }
    
    @objc func statusItemClicked(sender: NSStatusBarButton) {
        handleStatusItemClick()
    }
    
    @objc func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            let settingsItem = NSMenuItem(title: "偏好设置...", action: #selector(showSettingsWindow), keyEquivalent: ",")
            settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
            menu.addItem(settingsItem)
            menu.addItem(NSMenuItem.separator())
            let openCalendarItem = NSMenuItem(title: "系统日历", action: #selector(openSystemCalendar(_:)), keyEquivalent: "o")
            openCalendarItem.image = NSImage(systemSymbolName: "calendar.badge.plus", accessibilityDescription: nil)
            openCalendarItem.target = self
            menu.addItem(openCalendarItem)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePopover()
        }
    }
    
    @objc func openSystemCalendar(_ sender: NSMenuItem) {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if isPopoverAnimating {
            return
        }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            isPopoverAnimating = true
            
            calendarManager.resetToToday()
            
            NSApp.activate(ignoringOtherApps: true)
            
            DispatchQueue.main.async {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isPopoverAnimating = false
                }
            }
        }
    }
    
    @objc func closePopover() {
        popover.performClose(nil)
    }
    
    @objc func showSettingsWindow() {
        if settingsWindow == nil {
            let settingsView = SettingsView(calendarManager: self.calendarManager)
                .environmentObject(self.calendarManager)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 450),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "偏好设置"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: settingsView)
            settingsWindow = window
        }
        
        updateAppearance()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.orderFrontRegardless()
    }
    
    func openEventEditWindow(event: CalendarEvent) {
        if let existingWindow = eventEditWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = EventEditView(event: event).environmentObject(calendarManager)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.delegate = self
        window.title = "编辑事件"
        window.center()
        window.isReleasedWhenClosed = false
        
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        
        self.eventEditWindow = window
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window == settingsWindow {
                settingsWindow = nil
            }
            if window == eventEditWindow {
                eventEditWindow = nil
            }
        }
    }
}

// 双行显示的自定义状态栏视图
class DoubleLineStatusView: NSView {
    
    init(topText: String, bottomText: String) {
        super.init(frame: .zero)
        
        wantsLayer = true
        
        // 上行标签
        let topLabel = NSTextField()
        topLabel.stringValue = topText
        topLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        topLabel.textColor = NSColor.controlTextColor
        topLabel.alignment = .center
        topLabel.isBordered = false
        topLabel.drawsBackground = false
        topLabel.sizeToFit()
        
        // 下行标签
        let bottomLabel = NSTextField()
        bottomLabel.stringValue = bottomText
        bottomLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        bottomLabel.textColor = NSColor.controlTextColor
        bottomLabel.alignment = .center
        bottomLabel.isBordered = false
        bottomLabel.drawsBackground = false
        bottomLabel.sizeToFit()
        
        // 计算尺寸（紧凑布局，根据内容动态调整）
        let width = max(topLabel.frame.width, bottomLabel.frame.width)
        let height = topLabel.frame.height + bottomLabel.frame.height
        
        self.frame = NSRect(x: 0, y: 0, width: width, height: height)
        
        // 布局标签（两行紧密排列，无间距）
        topLabel.frame = NSRect(
            x: (width - topLabel.frame.width) / 2,
            y: bottomLabel.frame.height - 2,  // 让上行底部稍微覆盖下行顶部
            width: topLabel.frame.width,
            height: topLabel.frame.height
        )
        
        bottomLabel.frame = NSRect(
            x: (width - bottomLabel.frame.width) / 2,
            y: 0,
            width: bottomLabel.frame.width,
            height: bottomLabel.frame.height
        )
        
        addSubview(topLabel)
        addSubview(bottomLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 让鼠标事件传递给父视图（按钮）
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}
