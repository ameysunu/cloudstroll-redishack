//
//  TrendsModel.swift
//  CloudStroll
//
//  Created by Amey Sunu on 04/08/2025.
//

import Foundation
import SwiftUI

struct TrendPoint: Codable {
    let timestamp: Int64
    let value: Double
}

struct TrendPointData: Identifiable {
    let id = UUID()
    let mood: String
    let date: Date
    let value: Double

    var color: Color {
        return Self.color(for: self.mood)
    }

    static func color(for mood: String) -> Color {
        switch mood.lowercased() {
        case "happy": return .green
        case "neutral": return .blue
        case "sad": return .indigo
        case "anxious": return .orange
        case "angry": return .red
        default: return .gray
        }
    }
}
