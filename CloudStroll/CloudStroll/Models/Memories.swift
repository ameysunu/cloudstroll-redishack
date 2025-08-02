//
//  Memories.swift
//  CloudStroll
//
//  Created by Amey Sunu on 01/08/2025.
//
import Foundation

struct Memory: Identifiable, Codable {
    var id = UUID()
    var location: String
    var latitude: Double
    var longitude: Double
    var entry: String
    var mood: String
    var weather: String
    var uid: String
    
    var date: Date
    
    var iconName: String {
        if entry.lowercased().contains("hike") {
            return "mountain.2.fill"
        } else if entry.lowercased().contains("city") {
            return "building.2.fill"
        }
        return "figure.walk"
    }
}
