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
    var embedding: [Float]
    
    var timestamp: String
    
    var iconName: String {
        let text = entry.lowercased()
        for mapping in iconMappings {
            for kw in mapping.keywords {
                if text.contains(kw) {
                    return mapping.symbol
                }
            }
        }
        return "figure.walk"
    }
}
