//
//  EventEditView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/8.
//

import SwiftUI

struct EventEditView: View {
    let event:CalendarEvent
    @State private var editedEvent:CalendarEvent
    
    init(event:CalendarEvent){
        self.event = event
        self._editedEvent = State(initialValue: event)
    }
    
    var body: some View {
        VStack(alignment:.leading){
            Text("标题")
            TextField("标题",text: $editedEvent.title,axis: .vertical)
                .lineLimit(nil)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Divider()
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500,maxWidth: 500,minHeight: 500,maxHeight: .infinity)
    }
}
