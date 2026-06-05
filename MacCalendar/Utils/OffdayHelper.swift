//
//  OffdayHelper.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/12/12.
//

import Foundation

public class OffdayHelper {
    private static var cache: [Int: OffdayDataResponse] = [:]
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    public static func checkOffdayStatus(for date: Date) -> Bool? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        let response: OffdayDataResponse
        if let cached = cache[year] {
            response = cached
        } else {
            let fileName = "\(year)"
            
            // 优先尝试从 data 目录读取
            var targetURL: URL? = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "data")
            
            // 尝试从资源根目录读取
            if targetURL == nil {
                targetURL = Bundle.main.url(forResource: fileName, withExtension: "json")
            }
            
            guard let fileURL = targetURL,
                  let data = try? Data(contentsOf: fileURL),
                  let decoded = try? JSONDecoder().decode(OffdayDataResponse.self, from: data) else {
                return nil
            }
            cache[year] = decoded
            response = decoded
        }
        
        let dateString = formatter.string(from: date)
        return response.days.first(where: { $0.date == dateString })?.isOffDay
    }
}
