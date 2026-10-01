//
//  SettingsIconView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

struct SettingsIconView: View {
    @AppStorage("displayMode", store: SettingsManager.sharedDefaults) private var displayMode: DisplayMode = SettingsManager.displayMode
    @AppStorage("customIconOption", store: SettingsManager.sharedDefaults) private var customIconOption: IconDisplayOption = SettingsManager.customIconOption
    @AppStorage("customFormatString", store: SettingsManager.sharedDefaults) private var customFormatString: String = SettingsManager.customFormatString
    @AppStorage("enableDoubleLine", store: SettingsManager.sharedDefaults) private var enableDoubleLine: Bool = SettingsManager.enableDoubleLine
    @AppStorage("doubleLineTopFormat", store: SettingsManager.sharedDefaults) private var doubleLineTopFormat: String = SettingsManager.doubleLineTopFormat
    @AppStorage("doubleLineBottomFormat", store: SettingsManager.sharedDefaults) private var doubleLineBottomFormat: String = SettingsManager.doubleLineBottomFormat
    @AppStorage("firstDayInWeek", store: SettingsManager.sharedDefaults) private var firstDayInWeek: FirstDayInWeek = SettingsManager.firstDayInWeek
    @AppStorage("showWeekNumber", store: SettingsManager.sharedDefaults) private var showWeekNumber: Bool = SettingsManager.showWeekNumber
    @AppStorage("showDaysIndicator", store: SettingsManager.sharedDefaults) private var showDaysIndicator: Bool = SettingsManager.showDaysIndicator
    @AppStorage("appearanceMode", store: SettingsManager.sharedDefaults) private var appearanceMode: AppearanceMode = SettingsManager.appearanceMode

    private var isCustomMode: Bool {
        switch displayMode {
        case .icon, .dateIcon, .custom:
            return true
        default:
            return false
        }
    }

    private var menuBarDisplayModeBinding: Binding<DisplayMode> {
        Binding(
            get: {
                switch displayMode {
                case .date: return .date
                case .time: return .time
                default: return .custom
                }
            },
            set: { newValue in
                displayMode = newValue
            }
        )
    }

    private var doubleLineBinding: Binding<Bool> {
        Binding(
            get: { enableDoubleLine },
            set: { newValue in
                enableDoubleLine = newValue
                if newValue {
                    displayMode = .custom
                }
            }
        )
    }

    private var customIconOptionBinding: Binding<IconDisplayOption> {
        Binding(
            get: { customIconOption },
            set: { newValue in
                customIconOption = newValue
                displayMode = .custom
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("外观模式", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                Picker("菜单栏显示", selection: menuBarDisplayModeBinding) {
                    Text("日期").tag(DisplayMode.date)
                    Text("时间").tag(DisplayMode.time)
                    Text("自定义").tag(DisplayMode.custom)
                }
                .pickerStyle(.radioGroup)
            }

            if isCustomMode {
                Section {
                    Toggle("双行显示", isOn: doubleLineBinding)
                    
                    if enableDoubleLine {
                        TextField("上行格式", text: $doubleLineTopFormat)
                        TextField("下行格式", text: $doubleLineBottomFormat)
                        
                        Text("格式化代码参考: yyyy(年)，MM(月)，d(日)，E(星期)，HH(24时)，h(12时)，m(分), s(秒)，a(上午/下午)，w(周数)，gy(干支年)，gm(干支月)，lm(农历月)，ld(农历日)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    } else {
                        Picker("显示图标", selection: customIconOptionBinding) {
                            Text("默认图标").tag(IconDisplayOption.defaultIcon)
                            Text("动态图标").tag(IconDisplayOption.dynamicIcon)
                            Text("不显示").tag(IconDisplayOption.none)
                        }
                        .pickerStyle(.radioGroup)
                        
                        TextField("输入自定义格式", text: $customFormatString)
                        
                        Text("格式化代码参考: yyyy(年)，MM(月)，d(日)，E(星期)，HH(24时)，h(12时)，m(分), s(秒)，a(上午/下午)，w(周数)，gy(干支年)，gm(干支月)，lm(农历月)，ld(农历日)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
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
