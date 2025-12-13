//
//  OffdayHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/12/12.
//

import Foundation

public class OffdayHelper{
    public static func checkOffdayStatus(for date: Date) -> Bool? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let fileName = "\(year)"

        guard let fileURL = Bundle.main.url(forResource: fileName,
                                            withExtension: "json") else {
            print("找不到本地文件 \(fileName).json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            let decodedResponse = try JSONDecoder().decode(OffdayDataResponse.self, from: data)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let dateString = formatter.string(from: date)
            
            if let targetDay = decodedResponse.days.first(where: { $0.date == dateString }) {
                return targetDay.isOffDay
            }
            
            return nil
            
        } catch {
            print("读取或解析失败: \(error)")
            return nil
        }
    }
}
