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
    var calendarManager = CalendarManager()
    
    private var calendarIcon = CalendarIcon()
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked)
            button.target = self
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
                guard let button = self?.statusItem.button else { return }
                
                if output == "" {
                    button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
                    button.title = ""
                } else {
                    button.title = output
                    button.image = nil
                }
            }
            .store(in: &cancellables)
        
        popover = NSPopover()
        popover.appearance = NSAppearance(named: .aqua)
        popover.behavior = .transient
        
        NotificationCenter.default.addObserver(self, selector: #selector(closePopover), name: NSApplication.didResignActiveNotification, object: nil)
    }
    
    @objc func statusItemClicked(sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "设置", action: #selector(showSettingsWindow), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePopover()
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                calendarManager.resetToToday()
                let hostingController = FocusableHostingController(rootView: ContentView().environmentObject(calendarManager))
                hostingController.sizingOptions = .intrinsicContentSize
                popover.contentViewController = hostingController
                
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    @objc func closePopover() {
        popover.performClose(nil)
    }
    
    @objc func showSettingsWindow() {
        if settingsWindow == nil {
            let settingsView = SettingsView().environmentObject(calendarManager)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: settingsView)
            settingsWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openEventEditWindow(with parameter: CalendarEvent) {
        if let existingWindow = eventEditWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = EventEditView(event: parameter).environmentObject(calendarManager)
        
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
