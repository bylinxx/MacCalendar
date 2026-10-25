//
//  CalendarView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI

struct CalendarView: View {
    @StateObject var calendarManager:CalendarManager
        
    @FocusState private var focusedField: DateField?

    enum DateField {
        case year
        case month
    }
    
    var columns: [GridItem] {
        if SettingsManager.showWeekNumber {
            // 周数列固定窄宽，避免打开周数后日期列被拉宽
            return [GridItem(.fixed(26), spacing: 0)] + Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        }
        return Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    }
    let calendar = Calendar.Based

    var body: some View {
        VStack(spacing:0) {
            HStack(spacing:0){
                Image(systemName: "chevron.compact.backward")
                    .frame(width:80,alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        calendarManager.goToPreviousMonth()
                    }
                Spacer()
                HStack(){
                    EditableDateComponent(
                        date: $calendarManager.selectedMonth,
                        component: .year,
                        calendarManager: calendarManager, focusState: _focusedField,
                        equals: .year
                    )

                    EditableDateComponent(
                        date: $calendarManager.selectedMonth,
                        component: .month,
                        calendarManager: calendarManager, focusState: _focusedField,
                        equals: .month
                    )
                }
                Spacer()
                Image(systemName: "chevron.compact.forward")
                    .frame(width:80,alignment: .trailing)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        calendarManager.goToNextMonth()
                    }
            }
            
            HStack(spacing: 0) {
                // 周数列占位，与网格首列同宽
                if SettingsManager.showWeekNumber {
                    Color.clear
                        .frame(width: 26)
                }
                ForEach(calendarManager.weekdays, id: \.self) { day in
                        VStack(spacing: 4) {
                            Text(day)
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity, minHeight: 35)
                        .cornerRadius(6)
                    }
            }
            
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(calendarManager.calendarDays, id: \.self) { day in
                    if day.is_weekNumber == true {
                        Text("\(day.weekNumber ?? 0)")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    else if let date = day.date {
                        ZStack{
                            if day.is_today {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 35, height: 35, alignment: .center)
                            }
                            if calendar.isDate(date, equalTo: calendarManager.selectedDay, toGranularity: .day){
                                Circle()
                                    .fill(Color.red.opacity(0.3))
                                    .frame(width: 35, height: 35, alignment: .center)
                            }
                            if day.offday != nil {
                                Text(day.offday == true ? "休":"班")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white)
                                    .frame(width: 14,height: 14)
                                    .background(day.offday == true ? .red : .gray)
                                    .cornerRadius(3)
                                    .offset(x:12,y:-12)
                            }
                            VStack(spacing: -2) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 12))
                                    .foregroundColor(day.is_today ? .white : (day.is_currentMonth ? .primary : .gray.opacity(0.5)))
                                
                                Text(!day.holidays.isEmpty ? day.holidays[0] : day.solar_term ?? day.short_lunar ?? "")
                                    .font(.system(size: 8))
                                    .foregroundColor(day.is_today ? .white : (day.is_currentMonth ? .primary : .gray.opacity(0.5)))
                            }
                            .frame(height:35)
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                            if let firstEvent = day.events.first {
                                Circle()
                                    .fill(firstEvent.color.color)
                                    .frame(width: 5, height: 5)
                                    .offset(y:15)
                            }
                        }
                        .frame(width: 35, height: 35, alignment: .center)
                        .contentShape(Circle())
                        .onTapGesture {
                            calendarManager.getSelectedDayEvents(date: date)
                        }
                    }
                }
            }
        }
    }
}

struct EditableDateComponent: View {
    @Binding var date: Date
    let component: Calendar.Component
    
    var calendarManager: CalendarManager
    
    @FocusState var focusState: CalendarView.DateField?
    let equals: CalendarView.DateField
    
    @State private var isEditing: Bool = false
    @State private var temporaryText: String = ""

    var body: some View {
        Group {
            if isEditing {
                TextField("输入", text: $temporaryText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .focused($focusState, equals: equals)
                    .onSubmit {
                        commitChange()
                    }
                    .onChange(of: focusState) { oldValue,newValue in
                        if newValue != equals {
                            commitChange()
                        }
                    }
            } else {
                Text(date, format: component == .year ? .dateTime.year() : .dateTime.month())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startEditing()
                    }
            }
        }
    }
    
    private func startEditing() {
        let value = Calendar.current.component(component, from: date)
        temporaryText = String(value)
        isEditing = true
        focusState = equals
    }
    
    private func commitChange() {
        let cleanText = temporaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let newValue = Int(cleanText) else {
            isEditing = false
            return
        }

        if component == .month {
            if !(1...12).contains(newValue) {
                isEditing = false
                return
            }
        }

        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        if component == .year {
            components.year = newValue
        } else if component == .month {
            components.month = newValue
        }
        
        if let newDate = Calendar.current.date(from: components) {
            let year = Calendar.current.component(.year, from: newDate)
            let month = Calendar.current.component(.month, from: newDate)
            
            calendarManager.goToCustomizeMonth(year: year, month: month)
        }
        
        isEditing = false
    }
}
