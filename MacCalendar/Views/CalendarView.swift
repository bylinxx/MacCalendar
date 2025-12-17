//
//  CalendarView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var calendarManager:CalendarManager
    @AppStorage("weekNumberDisplayMode") private var weekNumberDisplayMode: WeekNumberDisplayMode = SettingsManager.weekNumberDisplayMode
    
    @FocusState private var focusedField: DateField?

    enum DateField {
        case year
        case month
    }
    
    // 原有的 LazyVGrid columns 不再使用，因为改为 VStack/HStack 布局以支持插入周数
    // let columns = Array(repeating: GridItem(.flexible()), count: 7)
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
                // 新增：周数列的表头，根据设置显示
                if weekNumberDisplayMode == .show {
                    Text("周")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 30)
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
            
            // 使用 VStack + HStack 手动构建网格，以便在每行前插入周数
            let days = calendarManager.calendarDays
            let rowCount = (days.count + 6) / 7 // 向上取整计算行数
            
            VStack(spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        // 新增：周数显示列，根据设置显示
                        if weekNumberDisplayMode == .show {
                            if let firstDayOfRow = days.indices.contains(rowIndex * 7) ? days[rowIndex * 7] : nil {
                                let weekNum = calendar.component(.weekOfYear, from: firstDayOfRow.date)
                                Text("\(weekNum)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .frame(width: 30) // 固定宽度与表头一致
                            } else {
                                Spacer().frame(width: 30)
                            }
                        }
                        
                        // 渲染该行的 7 天
                        ForEach(0..<7, id: \.self) { colIndex in
                            let index = rowIndex * 7 + colIndex
                            if index < days.count {
                                let day = days[index]
                                let isCurrentMonth = calendar.isDate(day.date, equalTo: calendarManager.selectedMonth, toGranularity: .month)
                                let isToday = calendar.isDateInToday(day.date)
                                
                                ZStack{
                                    if isToday{
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 35, height: 35, alignment: .center)
                                    }
                                    if calendar.isDate(day.date, equalTo: calendarManager.selectedDay, toGranularity: .day){
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
                                            Text("\(calendar.component(.day, from: day.date))")
                                                .font(.system(size: 12))
                                                .foregroundColor(isToday ? .white : (isCurrentMonth ? .primary : .gray.opacity(0.5)))
                                            
                                            Text(!day.holidays.isEmpty ? day.holidays[0] : day.solar_term ?? day.short_lunar ?? "")
                                                .font(.system(size: 8))
                                                .foregroundColor(isToday ? .white : (isCurrentMonth ? .primary : .gray.opacity(0.5)))
                                        }
                                        .frame(height:35)
                                        .cornerRadius(6)
                                        .contentShape(Rectangle())
                                    if !day.events.isEmpty {
                                        Circle()
                                            .fill(day.events.first!.color.color)
                                            .frame(width: 5, height: 5)
                                            .offset(y:15)
                                    }
                                }
                                .frame(width: 35, height: 35, alignment: .center)
                                .contentShape(Circle())
                                .onTapGesture {
                                    calendarManager.getSelectedDayEvents(date: day.date)
                                }
                                .frame(maxWidth: .infinity) // 确保在 HStack 中占据等宽空间
                            } else {
                                // 补齐最后一行的空白
                                Spacer().frame(maxWidth: .infinity)
                            }
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
