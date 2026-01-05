//
//  EventListView.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/9/28.
//

import SwiftUI

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct EventListView: View {
    @ObservedObject var calendarManager: CalendarManager

    @State private var contentHeight: CGFloat = 0
    @State private var newTodoTitle: String = ""
    

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(DateHelper.formatDate(date: calendarManager.selectedDay, format: "yyyy年MM月dd日（第w周）"))")
                Spacer()
                Text(calendarManager.selectedDayLunar)
            }

            todoSection
        }
    }

    private var todoSection: some View {
        let todos = calendarManager.selectedDayTodos
        let events = calendarManager.selectedDayEvents

        return VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.top, 4)
            Text("Todo")
                .font(.system(size: 12, weight: .semibold))
      // 添加新 todo 输入框（放在 todo 列表上方）
            HStack(spacing: 8) {
                TextField("添加 todo", text: $newTodoTitle)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        // 不默认选中输入框
                        DispatchQueue.main.async {
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                    }
                Button("添加") {
                    let title = newTodoTitle
                    newTodoTitle = ""
                    Task {
                        await calendarManager.addTodo(title: title, for: calendarManager.selectedDay)
                    }
                }
                .disabled(newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // 显示日历事件
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(events, id: \.id) { event in
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundStyle(.blue)

                            if event.isAllDay {
                                Text("全天")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            } else {
                                HStack(spacing: 4) {
                                    Text(event.startDate, style: .time)
                                    Text("-")
                                    Text(event.endDate, style: .time)
                                }
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            }

                            Text(event.title)
                                .font(.system(size: 12))
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }
            }

      
            // 显示提醒事项
            if !todos.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(todos) { item in
                        HStack(spacing: 8) {
                            Button(action: {
                                Task {
                                    await calendarManager.toggleTodoCompleted(id: item.id, for: calendarManager.selectedDay)
                                }
                            }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            }
                            .buttonStyle(.plain)

                            Text(item.title)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .strikethrough(item.isCompleted)
                                .foregroundStyle(item.isCompleted ? .secondary : .primary)

                            Spacer()

                            Button(action: {
                                Task {
                                    await calendarManager.deleteTodo(id: item.id, for: calendarManager.selectedDay)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if events.isEmpty && todos.isEmpty {
                Text("暂无事项")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
