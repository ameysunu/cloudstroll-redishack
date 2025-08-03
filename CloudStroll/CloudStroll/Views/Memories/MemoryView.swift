//
//  MemoryView.swift
//  CloudStroll
//
//  Created by Amey Sunu on 03/08/2025.
//

import SwiftUI
import MapKit

struct MemoryView: View {
    
    let memory: Memory
    @State private var mapRegion: MKCoordinateRegion
    
    init(memory: Memory) {
        let latitude: CLLocationDegrees = memory.latitude
        let longitude: CLLocationDegrees = memory.longitude
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let mapSpan = MKCoordinateSpan(
            latitudeDelta: 0.01,
            longitudeDelta: 0.01
        )
        
        mapRegion = MKCoordinateRegion(
            center: centerCoordinate,
            span: mapSpan
        )
        
        self.memory = memory
        
    }
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                Map(coordinateRegion: $mapRegion)
                    .ignoresSafeArea(edges: .top)
                    .navigationTitle(memory.location)
                
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(memory.location)
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.rounded)
                    
                    // A nicely formatted date and time.
                    Text(memory.timestamp.toFormattedDateString()!)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 16) {
                    InfoTagView(
                        iconName: memory.iconName,
                        title: "Mood",
                        value: memory.mood.capitalized
                    )
                    InfoTagView(
                        iconName: memory.iconName == "☀️" ? "sun.max.fill" : "cloud.fill",
                        title: "Weather",
                        value: memory.weather.capitalized
                    )
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Memory")
                        .font(.title2.weight(.semibold))
                    Text(memory.entry)
                        .font(.body)
                        .lineSpacing(6)
                }
            }
            .padding()
        }
        .navigationTitle(memory.location)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground)) // Subtle background color
    }
    
}


struct InfoTagView: View {
    let iconName: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(width: 25)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
