//
//  EventEditView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/8.
//

import SwiftUI

extension Notification.Name {
    static let closeEventEditWindow = Notification.Name("closeEventEditWindow")
}

struct EventEditView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @AppStorage("appearanceMode", store: SettingsManager.sharedDefaults) private var appearanceMode: AppearanceMode = SettingsManager.appearanceMode
    
    let event: CalendarEvent
    
    @State private var editedEvent: CalendarEvent
    @State private var alertInfo: AlertInfo?
    @State private var showingResetConfirmation = false
    
    private static let cardBackground = Color(nsColor: .underPageBackgroundColor)
    // 浅色下 12% 黑几乎不可见，需比深色更高对比，否则各行糊成一片
    private static let rowSeparator = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(white: 1, alpha: 0.12)
            : NSColor(white: 0, alpha: 0.18)
    })
    
    init(event: CalendarEvent) {
        self.event = event
        self._editedEvent = State(initialValue: event)
    }
    
    private func bindingFor(optionalString: Binding<String?>) -> Binding<String> {
        return Binding<String>(
            get: { optionalString.wrappedValue ?? "" },
            set: { optionalString.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
    
    private func bindingFor(optionalURL: Binding<URL?>) -> Binding<String> {
        return Binding<String>(
            get: { optionalURL.wrappedValue?.absoluteString ?? "" },
            set: { optionalURL.wrappedValue = URL(string: $0) }
        )
    }
    
    var body: some View {
        let manager = calendarManager
        return VStack(spacing: 0) {
            if editedEvent.allowsModify == false {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                    Text("此日程来自只读日历，不能修改")
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.12))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                formRow(icon: "t.square") {
                    TextField("标题", text: $editedEvent.title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                }
                
                formDivider()
                
                formRow(icon: "location") {
                    TextField("地点", text: bindingFor(optionalString: $editedEvent.location))
                        .textFieldStyle(.plain)
                }
                
                formDivider()
                
                formRow(icon: "hourglass") {
                    Toggle("全天", isOn: $editedEvent.isAllDay.animation())
                }
                
                formDivider()
                
                formRow(icon: "clock") {
                    HStack(spacing: 6) {
                        DatePicker("", selection: $editedEvent.startDate, displayedComponents: editedEvent.isAllDay ? .date : [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.stepperField)
                            .fixedSize()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $editedEvent.endDate, in: editedEvent.startDate..., displayedComponents: editedEvent.isAllDay ? .date : [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.stepperField)
                            .fixedSize()
                        Spacer(minLength: 0)
                    }
                }
                .onChange(of: editedEvent.startDate) { _, newStartDate in
                    if newStartDate > editedEvent.endDate {
                        editedEvent.endDate = newStartDate
                    }
                }
                
                formDivider()
                
                formRow(icon: "link") {
                    TextField("URL", text: bindingFor(optionalURL: $editedEvent.url))
                        .textFieldStyle(.plain)
                }
                
                formDivider()
                
                formRow(icon: "doc.text", topAligned: true) {
                    // HStack 内 axis: .vertical 字段会被按半行高裁切文字，必须用 frame 钉住高度
                    TextField("备注", text: bindingFor(optionalString: $editedEvent.notes), axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(nil)
                        .frame(height: 86, alignment: .topLeading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Self.cardBackground)
            .cornerRadius(10)
            .padding([.horizontal, .top])
            
            Spacer(minLength: 16)
            
            HStack(spacing: 12) {
                Button("重置"){
                    showingResetConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
                .cornerRadius(10)
                
                Button("保存") {
                    if editedEvent.allowsModify == false {
                        self.alertInfo = AlertInfo(
                            title: "无法保存",
                            message: "此日程来自只读日历，不能修改。",
                            onDismiss: nil
                        )
                        return
                    }
                    Task {
                        do {
                            try await manager.updateEvent(event: editedEvent)
                            self.alertInfo = AlertInfo(
                                title: "保存成功",
                                message: "修改已成功保存。",
                                onDismiss: {
                                    NotificationCenter.default.post(name: .closeEventEditWindow, object: nil)
                                }
                            )
                            
                        } catch {
                            self.alertInfo = AlertInfo(
                                title: "保存失败",
                                message: error.localizedDescription,
                                onDismiss: nil
                            )
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .cornerRadius(10)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(minWidth: 460, idealWidth: 460, maxWidth: 460, minHeight: 395)
        .navigationTitle("编辑日程")
        .alert("放弃修改", isPresented: $showingResetConfirmation) {
            Button("放弃", role: .destructive) {
                editedEvent = event
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要放弃修改吗？此操作无法撤销。")
        }
        .alert(item: $alertInfo) { info in
            if let onDismissAction = info.onDismiss {
                return Alert(
                    title: Text(info.title),
                    message: Text(info.message),
                    dismissButton: .default(Text("确定"), action: {
                        onDismissAction()
                    })
                )
            } else {
                return Alert(
                    title: Text(info.title),
                    message: Text(info.message),
                    dismissButton: .cancel(Text("好的"))
                )
            }
        }
    }
    
    @ViewBuilder
    private func formDivider() -> some View {
        Divider()
            .foregroundStyle(Self.rowSeparator)
            .padding(.leading, 34)
    }
    
    @ViewBuilder
    private func formRow<Content: View>(
        icon: String,
        topAligned: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: topAligned ? .top : .center, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 24)
            content()
                .frame(maxWidth: .infinity, alignment: topAligned ? .topLeading : .leading)
                .frame(height: topAligned ? nil : 24)
        }
        .padding(.vertical, 8)
    }
}
