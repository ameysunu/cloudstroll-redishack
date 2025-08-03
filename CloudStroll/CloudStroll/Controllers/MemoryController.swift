//
//  MemoryController.swift
//  CloudStroll
//
//  Created by Amey Sunu on 02/08/2025.
//

import Foundation

class MemoryController: MemoryProtocol {
    
    var location: String
    var latitude: String
    var longitude: String
    var entry: String
    var mood: Mood
    var weather: Weather
    var timestamp: Date
    
    init(location: String, latitude: String, longitude: String, entry: String, mood: Mood, weather: Weather, timestamp: Date) {
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.entry = entry
        self.mood = mood
        self.weather = weather
        self.timestamp = timestamp
    }
     
    func prepareMemoryData(uid: String) -> Memory? {
        
        guard let lat = Double(latitude), let lon = Double(longitude) else {
            print("Error: Invalid latitude or longitude format.")
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
           formatter.formatOptions = [.withInternetDateTime]
           let timestampString = formatter.string(from: timestamp)
        
        return Memory(
            location: location,
            latitude: lat,
            longitude: lon,
            entry: entry,
            mood: mood.rawValue,
            weather: weather.rawValue,
            uid: uid,
            embedding: [0],
            timestamp: timestampString
        )
        
    }
    
}

extension String {
    func toFormattedDateString() -> String? {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: self) else {
            return nil
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "'dd' MMMM yyyy, HH:mm"
        let formattedString = outputFormatter.string(from: date)
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let daySuffix = getDaySuffix(for: day)
        
        let finalString = formattedString.replacingOccurrences(of: "dd", with: "\(day)\(daySuffix)")
        
        return finalString
    }
    
    private func getDaySuffix(for day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}
