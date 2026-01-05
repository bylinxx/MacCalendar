import Foundation
import SwiftUI
import Combine

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var todosByDay: [String: [TodoItem]] = [:]

    private let storageKey = "todosByDay"
    private let calendar = Calendar.Based

    init() {
        load()
    }

    func todos(for date: Date) -> [TodoItem] {
        todosByDay[dayKey(for: date)] ?? []
    }

    func add(title: String, for date: Date) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = dayKey(for: date)
        var list = todosByDay[key] ?? []
        list.append(TodoItem(title: trimmed))
        todosByDay[key] = list
        persist()
    }

    func toggleCompleted(id: UUID, for date: Date) {
        let key = dayKey(for: date)
        guard var list = todosByDay[key], let idx = list.firstIndex(where: { $0.id == id }) else { return }
        list[idx].isCompleted.toggle()
        todosByDay[key] = list
        persist()
    }

    func delete(id: UUID, for date: Date) {
        let key = dayKey(for: date)
        guard var list = todosByDay[key] else { return }
        list.removeAll { $0.id == id }
        if list.isEmpty {
            todosByDay.removeValue(forKey: key)
        } else {
            todosByDay[key] = list
        }
        persist()
    }

    private func dayKey(for date: Date) -> String {
        let day = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: day)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            todosByDay = try JSONDecoder().decode([String: [TodoItem]].self, from: data)
        } catch {
            todosByDay = [:]
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(todosByDay)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
        }
    }
}
