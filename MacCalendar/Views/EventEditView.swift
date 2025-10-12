//
//  EventEditView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/8.
//

import SwiftUI

struct EventEditView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    let event: CalendarEvent
    
    @State private var editedEvent: CalendarEvent
    @State private var alertInfo: AlertInfo?
    @State private var showingResetConfirmation = false
    
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
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack{
                    Image(systemName: "t.square").font(.title3).frame(width: 35)
                        .foregroundColor(.secondary)
                    TextField("标题", text: $editedEvent.title,axis: .vertical)
                        .textFieldStyle(.plain)
                }
                
                Divider()
                    .foregroundStyle(Color(hex: "cccccc"))
                
                rowItem("location", placeholder: "地点", content:
                            TextField("地点", text: bindingFor(optionalString: $editedEvent.location),axis: .vertical)
                )
                
                Divider()
                    .foregroundStyle(Color(hex: "cccccc"))
                
                HStack {
                    Image(systemName: "hourglass").font(.title3).frame(width: 35).foregroundColor(.secondary)
                    Toggle("全天", isOn: $editedEvent.isAllDay.animation())
                }
                
                Divider()
                    .foregroundStyle(Color(hex: "cccccc"))
                
                HStack {
                    Image(systemName: "clock").font(.title3).frame(width: 35).foregroundColor(.secondary)
                    DatePicker("", selection: $editedEvent.startDate, displayedComponents: editedEvent.isAllDay ? .date : [.date, .hourAndMinute])
                        .labelsHidden()
                    Image(systemName: "arrow.right").foregroundColor(.secondary)
                    DatePicker("", selection: $editedEvent.endDate, in: editedEvent.startDate..., displayedComponents: editedEvent.isAllDay ? .date : [.date, .hourAndMinute])
                        .labelsHidden()
                }
                .onChange(of: editedEvent.startDate) { _, newStartDate in
                    if newStartDate > editedEvent.endDate {
                        editedEvent.endDate = newStartDate
                    }
                }
                
                Divider()
                    .foregroundStyle(Color(hex: "cccccc"))
                
                rowItem("link", placeholder: "URL", content:
                            TextField("URL", text: bindingFor(optionalURL: $editedEvent.url))
                )
                
                Divider()
                    .foregroundStyle(Color(hex: "cccccc"))
                
                rowItem("doc.text", placeholder: "备注", content:
                            TextField("备注", text: bindingFor(optionalString: $editedEvent.notes), axis: .vertical)
                )
            }
            .padding(10)
            .background(Color(hex: "#ccc").opacity(0.1))
            .cornerRadius(8)
            .padding()
            
            Spacer()
            
            VStack(spacing: 12) {
                HStack{
                    Button("重置"){
                        showingResetConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                    .cornerRadius(10)
                    
                    Button("保存") {
                        Task {
                            do {
                                try await calendarManager.updateEvent(event: editedEvent)
                                self.alertInfo = AlertInfo(
                                    title: "保存成功",
                                    message: "修改已成功保存。",
                                    onDismiss: {
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
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 480, height: 450)
        .navigationTitle("编辑日程")
        .disabled(editedEvent.allowsModify == false)
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
    private func rowItem<Content: View>(_ iconName: String, placeholder: String, content: Content) -> some View {
        HStack {
            Image(systemName: iconName).font(.title3).frame(width: 35).foregroundColor(.secondary)
            content.textFieldStyle(.plain)
        }
    }
}
