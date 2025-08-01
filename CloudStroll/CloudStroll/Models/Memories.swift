//
//  Memories.swift
//  CloudStroll
//
//  Created by Amey Sunu on 01/08/2025.
//
import Foundation

struct Memory: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let notes: String
    
    var iconName: String {
        if title.lowercased().contains("hike") {
            return "mountain.2.fill"
        } else if title.lowercased().contains("city") {
            return "building.2.fill"
        }
        return "figure.walk"
    }
}
