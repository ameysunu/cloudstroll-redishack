//
//  MemoryAdd.swift
//  CloudStroll
//
//  Created by Amey Sunu on 02/08/2025.
//

import SwiftUI

struct MemoryAdd: View {
    
    @ObservedObject var loginCtrl: LoginController
    
    @State private var location: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var entry: String = ""
    @State private var mood: Mood = .happy
    @State private var weather: Weather = .sunny
    @State private var timestamp: Date = .now
    
    @State private var errorMessage: String?
    @State private var isShowingErrorAlert = false
    
    private let apiCtrl = ApiController()
    
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
                          saveMemory()
                      }
                      .fontWeight(.bold)
                  }
              }
              .alert("Error", isPresented: $isShowingErrorAlert) {
                  Button("OK") {}
              } message: {
                  Text(errorMessage ?? "An unknown error occurred.")
              }
          }
    }
    
    
    private func saveMemory() {
        guard let uid = loginCtrl.userIdentifier else {
            showError(message: "Cannot save memory. User is not signed in.")
            return
        }
        
        let memoryCtrl = MemoryController(
            location: location,
            latitude: latitude,
            longitude: longitude,
            entry: entry,
            mood: mood,
            weather: weather,
            timestamp: timestamp
        )
        
        guard let payload = memoryCtrl.prepareMemoryData(uid: uid) else {
            showError(message: "Invalid data. Please check that latitude and longitude are valid numbers.")
            return
        }
        
        apiCtrl.sendMemoryToApi(memory: payload) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let responseString):
                    print("Success: \(responseString)")
                    dismiss()
                    
                case .failure(let error):
                    print("Failed: \(error.localizedDescription)")
                    showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showError(message: String) {
        self.errorMessage = message
        self.isShowingErrorAlert = true
    }
}
