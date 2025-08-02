//
//  MemoryAdd.swift
//  CloudStroll
//
//  Created by Amey Sunu on 02/08/2025.
//

import SwiftUI

struct MemoryAdd: View {
    
    @State private var location: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var entry: String = ""
    @State private var mood: Mood = .happy
    @State private var weather: Weather = .sunny
    @State private var timestamp: Date = .now
    
    
    enum Mood: String, CaseIterable, Identifiable {
        case happy, neutral, sad, angry
        var id: Self { self }
    }
    
    enum Weather: String, CaseIterable, Identifiable {
        case sunny, cloudy, rainy, windy, snowy
        var id: Self { self }
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
          NavigationView {
              ScrollView {
                  VStack(alignment: .leading, spacing: 16) {
                        
                      TextField("Location", text: $location)
                          .modifier(FormFieldStyle())
                      
                      HStack(spacing: 16) {
                          TextField("Latitude", text: $latitude)
                              .keyboardType(.decimalPad)
                              .modifier(FormFieldStyle())
                         
                          TextField("Longitude", text: $longitude)
                              .keyboardType(.decimalPad)
                              .modifier(FormFieldStyle())
                      }
                      
                      ZStack(alignment: .topLeading) {
                          TextEditor(text: $entry)
                              .frame(minHeight: 150)
                              .scrollContentBackground(.hidden)
                              .modifier(FormFieldStyle())
                         
                          if entry.isEmpty {
                              Text("Entry")
                                  .foregroundColor(Color(.placeholderText))
                                  .padding()
                                  .padding(.top, 8)
                                  .allowsHitTesting(false)
                          }
                      }
                      
                      CustomPicker(selection: $mood)
                      CustomPicker(selection: $weather)
                      
                      DatePicker(
                          "Timestamp",
                          selection: $timestamp,
                          displayedComponents: [.date, .hourAndMinute]
                      )
                      .modifier(FormFieldStyle())
                      
                      Spacer()
                  }
                  .padding()
              }
              .navigationTitle("New Memory")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .navigationBarLeading) {
                      Button("Cancel") { dismiss() }
                  }
                  ToolbarItem(placement: .navigationBarTrailing) {
                      Button("Save") {
                          dismiss()
                      }
                      .fontWeight(.bold)
                  }
              }
          }
    }
}

#Preview {
    MemoryAdd()
        .preferredColorScheme(.dark)
}

