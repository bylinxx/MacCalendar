//
//  EventListItemView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI

struct EventListItemView: View {
    let event:CalendarEvent
    
    @State private var selectedEventId:String? = nil
    
    var body: some View {
        HStack {
            VStack(spacing:2){
                if event.isAllDay{
                    Text("全天")
                }
                else{
                    Text(event.startDate, style: .time)
                    Divider()
                        .frame(width:30)
                    Text(event.endDate, style: .time)
                }
            }
            .font(.system(size: 10))
            .frame(width:30)
            
            HStack(spacing:0){
                Rectangle()
                    .cornerRadius(3)
                    .frame(width: 3)
                    .foregroundStyle(event.color.color.opacity(0.5))
                VStack{
                    Text(event.title)
                        .font(.system(size: 12))
                        .frame(maxWidth:.infinity,alignment: .leading)
                        .lineLimit(1)
                    Text(event.notes ?? "")
                        .font(.caption2)
                        .frame(maxWidth:.infinity,alignment: .leading)
                        .lineLimit(1)
                }
                .frame(maxWidth:.infinity,alignment: .leading)
                .padding(.init(top: 5, leading: 5, bottom: 5, trailing: 5))
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [event.color.color.opacity(0.2),event.color.color.opacity(0.1)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .cornerRadius(5)
        }
        .padding([.top,.bottom],2)
        .onTapGesture {
            selectedEventId = event.id
        }
        .popover(
            isPresented: Binding(
                get: { selectedEventId == event.id },
                set: { isPresented in
                    if !isPresented {
                        selectedEventId = nil
                    }
                }
            ),
            attachmentAnchor: .rect(.rect(CGRect(x: -10, y: 20, width: 0, height: 0))),
            arrowEdge: .leading,
            content: {
                EventDetailView(event: event)
            }
        )
    }
}
