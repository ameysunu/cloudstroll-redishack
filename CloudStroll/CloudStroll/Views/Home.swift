//
//  Home.swift
//  CloudStroll
//
//  Created by Amey Sunu on 01/08/2025.
//
import SwiftUI

struct HomeView: View {
    @ObservedObject var loginCtrl: LoginController
    
    // Dummy Data
    @State private var memories: [Memory] = [
        Memory(title: "Walk through Phoenix Park", date: .now, notes: "Saw some deer and got a coffee."),
        Memory(title: "Dublin City Centre", date: .now.addingTimeInterval(-86400), notes: "Visited Trinity College and walked along the Liffey."),
        Memory(title: "Hike at Howth", date: .now.addingTimeInterval(-172800), notes: "Beautiful cliff views.")
    ]
    
    @State private var showingAddMemorySheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if memories.isEmpty {
                    ContentUnavailableView(
                        "No Memories Yet",
                        systemImage: "figure.walk.motion",
                        description: Text("Tap the '+' button to add your first memory.")
                    )
                } else {
                    List {
                        ForEach(memories) { memory in
                            NavigationLink(destination: Text("Details for \(memory.title)")) {
                                MemoryRowView(memory: memory)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Your Memories")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Text(loginCtrl.userEmail ?? "No Email")
                        Button("Settings", systemImage: "gear", action: {})
                        Button("Sign Out", role: .destructive, action: loginCtrl.signOut)
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMemorySheet.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMemorySheet) {
                Text("Add New Memory Screen")
            }
        }
    }
}
