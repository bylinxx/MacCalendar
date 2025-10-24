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
    @AppStorage("firstDayInWeek") private var firstDayInWeek:FirstDayInWeek = SettingsManager.firstDayInWeek
    
    var body: some View {
        VStack(alignment: .leading,spacing:10) {
            Picker("显示类型:", selection: $displayMode) {
                ForEach(DisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            
            if displayMode == .custom {
                Section {
                    HStack{
                        Text("显示格式:")
                        TextField("自定义格式:", text: $customFormatString)
                    }
                    Text("格式化代码参考: yyyy(年), MM(月), d(日), E(星期), HH(24时), h(12时), m(分), s(秒), a(上午/下午)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            Picker("星期起始:", selection: $firstDayInWeek) {
                ForEach(FirstDayInWeek.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsIconView()
}
