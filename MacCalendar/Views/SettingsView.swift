//
//  SettingsView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

struct SettingsView: View {
    @State private var selection:SettingsType? = .customized
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("应用设置")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                
                ForEach(SettingsType.allCases) { setting in
                    Button(action: {
                        selection = setting
                    }) {
                        Text(setting.rawValue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(selection == setting ? Color.blue.opacity(0.8) : Color.clear)
                            .foregroundColor(selection == setting ? .white : .primary)
                            .contentShape(Rectangle())
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(10)
            .frame(width: 120)
            
            Divider()
            
            ZStack {
                selection?.view
            }
            .padding()
        }
        .frame(width: 500, height: 350, alignment: .leading)
    }
}
