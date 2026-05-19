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
    @AppStorage("firstDayInWeek") private var firstDayInWeek:FirstDayInWeek = SettingsManager.firstDayInWeek
    @AppStorage("showWeekNumber") private var showWeekNumber: Bool = SettingsManager.showWeekNumber
    @AppStorage("showDaysIndicator") private var showDaysIndicator: Bool = SettingsManager.showDaysIndicator
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = SettingsManager.appearanceMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "paintbrush")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("个性化设置")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("自定义应用的显示方式和行为")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 外观模式设置
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundColor(.secondary)
                            Text("外观模式")
                                .font(.headline)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                HStack {
                                    RadioButton(selected: appearanceMode == mode)
                                    Text(mode.rawValue)
                                        .font(.body)
                                    Spacer()
                                }
                                .onTapGesture {
                                    appearanceMode = mode
                                }
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 显示类型设置
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "menubar.rectangle")
                                .foregroundColor(.secondary)
                            Text("菜单栏显示")
                                .font(.headline)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                HStack {
                                    RadioButton(selected: displayMode == mode)
                                    Text(mode.rawValue)
                                        .font(.body)
                                    Spacer()
                                }
                                .onTapGesture {
                                    displayMode = mode
                                }
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 自定义格式设置
                if displayMode == .custom {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 8) {
                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                    .foregroundColor(.secondary)
                                Text("自定义格式")
                                    .font(.headline)
                            }
                            
                            // 双行显示开关
                            HStack {
                                Image(systemName: "equal.square")
                                    .foregroundColor(.secondary)
                                Text("双行显示")
                                    .font(.body)
                                Spacer()
                                Toggle("", isOn: $enableDoubleLine)
                                    .toggleStyle(.switch)
                            }
                            
                            // 单行格式输入
                            if !enableDoubleLine {
                                TextField("输入自定义格式", text: $customFormatString)
                                    .textFieldStyle(.roundedBorder)
                                    .animation(.spring(), value: customFormatString)
                            }
                            
                            // 双行格式输入
                            if enableDoubleLine {
                                VStack(spacing: 8) {
                                    TextField("上行格式", text: $doubleLineTopFormat)
                                        .textFieldStyle(.roundedBorder)
                                    TextField("下行格式", text: $doubleLineBottomFormat)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            
                            Text("格式化代码参考: yyyy(年)，MM(月)，d(日)，E(星期)，HH(24时)，h(12时)，m(分), s(秒)，a(上午/下午)，w(周数)，gy(干支年)，gm(干支月)，lm(农历月)，ld(农历日)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.spring(), value: displayMode)
                }
                
                // 周起始日设置
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text("周起始日")
                                .font(.headline)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(FirstDayInWeek.allCases, id: \.self) { day in
                                HStack {
                                    RadioButton(selected: firstDayInWeek == day)
                                    Text(day.rawValue)
                                        .font(.body)
                                    Spacer()
                                }
                                .onTapGesture {
                                    firstDayInWeek = day
                                }
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 周数显示设置
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "list.number")
                                .foregroundColor(.secondary)
                            Text("显示周数")
                                .font(.headline)
                        }
                        HStack {
                            Text("在日历中显示周数")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("", isOn: $showWeekNumber)
                                .toggleStyle(.switch)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 天数指示器设置
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("显示天数指示器")
                                .font(.headline)
                        }
                        HStack {
                            Text("在日历中显示当天距离今天的天数")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("", isOn: $showDaysIndicator)
                                .toggleStyle(.switch)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
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
