//
//  SettingsAbout.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/6.
//

import SwiftUI

struct SettingsAboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // 应用名称和描述
                VStack(alignment: .center, spacing: 8) {
                    Text("MacCalendar")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("完全免费且开源的macOS小而美菜单栏日历")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)

                // 应用信息
                VStack(alignment: .center, spacing: 12) {
                    // 版本信息
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("版本 \(Bundle.main.appVersion ?? "1.0.0")")
                            .font(.body)
                    }

                    // GitHub链接
                    Link(destination: URL(string:"https://github.com/bylinxx/MacCalendar")!) {
                        HStack(alignment: .center, spacing: 8) {
                            Image("github-logo")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.primary)
                            Text("GitHub 仓库")
                                .font(.body)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

                // 功能特点
                VStack(alignment: .center, spacing: 12) {
                    Text("功能特点")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            FeatureItem(symbol: "calendar", title: "日历视图")
                            FeatureItem(symbol: "list.bullet.clipboard", title: "日程管理")
                            FeatureItem(symbol: "moon.stars", title: "农历支持")
                            FeatureItem(symbol: "sun.max", title: "24节气")
                        }
                        HStack(spacing: 20) {
                            FeatureItem(symbol: "paintbrush", title: "个性化配置")
                            FeatureItem(symbol: "flag", title: "中国假期")
                            FeatureItem(symbol: "star", title: "开源免费")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)

                // 版权信息
                VStack(alignment: .center, spacing: 4) {
                    Text("© 2026 MacCalendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 功能特点项组件
struct FeatureItem: View {
    let symbol: String
    let title: String

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// 设置卡片组件
struct SettingsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .padding(16)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview {
    SettingsAboutView()
}
