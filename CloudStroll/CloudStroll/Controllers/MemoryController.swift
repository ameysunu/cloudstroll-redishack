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
        
        return Memory(
            location: location,
            latitude: lat,
            longitude: lon,
            entry: entry,
            mood: mood.rawValue,
            weather: weather.rawValue,
            uid: uid,
            date: timestamp
        )
        
    }
    
}
