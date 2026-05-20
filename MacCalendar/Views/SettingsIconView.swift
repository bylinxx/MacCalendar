//
//  SettingsIconView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

struct SettingsIconView: View {
    @AppStorage("displayMode") private var displayMode: DisplayMode = SettingsManager.displayMode
    @AppStorage("customFormatString") private var customFormatString: String = SettingsManager.customFormatString
    @AppStorage("enableDoubleLine") private var enableDoubleLine: Bool = SettingsManager.enableDoubleLine
    @AppStorage("doubleLineTopFormat") private var doubleLineTopFormat: String = SettingsManager.doubleLineTopFormat
    @AppStorage("doubleLineBottomFormat") private var doubleLineBottomFormat: String = SettingsManager.doubleLineBottomFormat
    @AppStorage("firstDayInWeek") private var firstDayInWeek: FirstDayInWeek = SettingsManager.firstDayInWeek
    @AppStorage("showWeekNumber") private var showWeekNumber: Bool = SettingsManager.showWeekNumber
    @AppStorage("showDaysIndicator") private var showDaysIndicator: Bool = SettingsManager.showDaysIndicator
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = SettingsManager.appearanceMode
    
    var body: some View {
        Form {
            Section {
                Picker("外观模式", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Picker("菜单栏显示", selection: $displayMode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            
            if displayMode == .custom {
                Section {
                    Toggle("双行显示", isOn: $enableDoubleLine)
                    
                    if !enableDoubleLine {
                        TextField("输入自定义格式", text: $customFormatString)
                    }
                    
                    if enableDoubleLine {
                        TextField("上行格式", text: $doubleLineTopFormat)
                        TextField("下行格式", text: $doubleLineBottomFormat)
                    }
                    
                    Text("格式化代码参考: yyyy(年)，MM(月)，d(日)，E(星期)，HH(24时)，h(12时)，m(分), s(秒)，a(上午/下午)，w(周数)，gy(干支年)，gm(干支月)，lm(农历月)，ld(农历日)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
            }
            
            Section {
                Picker("周起始日", selection: $firstDayInWeek) {
                    ForEach(FirstDayInWeek.allCases) { day in
                        Text(day.rawValue).tag(day)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Toggle("显示周数", isOn: $showWeekNumber)
                Toggle("显示天数指示器", isOn: $showDaysIndicator)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 自定义单选按钮组件
struct RadioButton: View {
    let selected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(selected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 20, height: 20)
            if selected {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                    .animation(.spring(), value: selected)
            }
        }
        .contentShape(Circle())
    }
}
