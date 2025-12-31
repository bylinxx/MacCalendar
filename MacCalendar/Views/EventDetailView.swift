//
//  EventDetailCard.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    let event:CalendarEvent
    
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.headline)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            HStack{
                Image(systemName: "clock")
                    .frame(width:20)
                    .scaledToFit()
                Text(DateHelper.formatDate(date: event.startDate, format: "yyyy/MM/dd"))
                if event.isAllDay {
                    Text("全天")
                }
                else{
                    HStack(spacing:0){
                        Text(DateHelper.formatDate(date: event.startDate, format: "HH:mm"))
                        Text("-")
                        Text(DateHelper.formatDate(date: event.endDate, format: "HH:mm"))
                        if let timespan = DateHelper.formattedDuration(from: event.startDate, to: event.endDate){
                            Text("（\(timespan)）")
                        }
                    }
                }
                
                Spacer()
                
                Button(action:{
                    AppDelegate.shared?.openEventEditWindow(event:  event)
                }){
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(.blue)
                }
                
                Button(action:{
                    showingDeleteConfirmation = true
                }){
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if let location = event.location {
                HStack{
                    Image(systemName: "location")
                        .frame(width:20)
                        .scaledToFit()
                    Text(location.replacingOccurrences(of: "\n", with: " "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let organizer = event.organizer {
                let name = organizer.name ?? ""
                
                let url: String = {
                    guard let url = organizer.url, let scheme = url.scheme else { return "" }
                    return String(url.absoluteString.dropFirst(scheme.count + 1))
                }()
                
                HStack {
                    Image(systemName: "person")
                        .frame(width:20)
                        .scaledToFit()
                    Text(url.isEmpty ? name : "\(name) (\(url))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            if let attendees = event.attendees, !attendees.isEmpty {
                let attendeesText = attendees.map { participant -> String in
                    let name = participant.name ?? ""
                    
                    let urlString: String
                    if let url = participant.url, let scheme = url.scheme {
                         urlString = String(url.absoluteString.dropFirst(scheme.count + 1))
                    } else {
                        urlString = ""
                    }
                    
                    return "\(name)\(!urlString.isEmpty ? "(\(urlString))" : "")"
                }.joined(separator: ", ")

                HStack(alignment: .top) {
                    Image(systemName: "person.2")
                        .frame(width:20)
                        .scaledToFit()
                    Text(attendeesText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
//                        .lineLimit(2)
                }
            }
            
            Divider()
            
            ScrollView{
                Text(event.notes ?? "")
                    .font(.body)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight:50,alignment: .topLeading)
            }
            .frame(maxHeight: 500)
            
            if let event_url = event.url{
                let url = UrlHelper.normalizeURL(from: event_url)
                HStack{
                    Image(systemName: "link")
                    Link(url.absoluteString,destination: url)
                }
            }
        }
        .padding()
        .frame(width:350)
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                Task {
                    do {
                        try await calendarManager.deleteEvent(withId: event.id)
                    } catch {
                        deleteErrorMessage = error.localizedDescription
                        showingDeleteError = true
                    }
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除事件“\(event.title)”吗？此操作无法撤销。")
        }
        .alert("删除失败", isPresented: $showingDeleteError) {
                    Button("好的", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
    }
}
