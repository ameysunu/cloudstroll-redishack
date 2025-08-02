//
//  MemoryProtocol.swift
//  CloudStroll
//
//  Created by Amey Sunu on 02/08/2025.
//

import Foundation


enum Mood: String, CaseIterable, Identifiable {
    case happy, neutral, sad, angry
    var id: Self { self }
}

enum Weather: String, CaseIterable, Identifiable {
    case sunny, cloudy, rainy, windy, snowy
    var id: Self { self }
}

protocol MemoryProtocol {
    
    var location: String { get set }
    var latitude: String { get set }
    var longitude: String { get set }
    var entry: String { get set }
    var mood: Mood { get set }
    var weather: Weather { get set }
    var timestamp: Date { get set }
    
    func prepareMemoryData(uid: String) -> Memory?
    
}
