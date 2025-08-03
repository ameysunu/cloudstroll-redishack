//
//  Home.swift
//  CloudStroll
//
//  Created by Amey Sunu on 01/08/2025.
//
import SwiftUI

struct HomeView: View {
    @ObservedObject var loginCtrl: LoginController
    
    @State private var memories: [Memory] = []
    
    @State private var showingAddMemorySheet = false
    @State private var isLoading = true
    
    private let apiCtrl = ApiController()
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading Memories...")
                } else if memories.isEmpty {
                    emptyStateView
                } else {
                    memoryListView
                }
            }
            .navigationTitle("Your Memories")
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }

            .onAppear {
                fetchMemories()
            }
            .sheet(isPresented: $showingAddMemorySheet) {
                fetchMemories()
            } content: {
                MemoryAdd(loginCtrl: loginCtrl)
            }
        }
    }
    
    private func fetchMemories() {
        guard let uid = loginCtrl.userIdentifier else {
            print("Error: Cannot fetch memories, user ID is nil.")
            isLoading = false
            return
        }
        
        isLoading = true
        apiCtrl.fetchMemories(for: uid) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedMemories):
                    self.memories = fetchedMemories
                case .failure(let error):
                    print("Error fetching memories: \(error.localizedDescription)")
                    // Optionally, show an error alert to the user
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Memories Yet",
            systemImage: "figure.walk.motion",
            description: Text("Tap the '+' button to add your first memory.")
        )
    }
    
    private var memoryListView: some View {
        List {
            ForEach(memories) { memory in
                NavigationLink(destination: MemoryView(memory: memory)) {
                    MemoryRowView(memory: memory)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .onDelete { offset in
                memories.remove(atOffsets: offset)
                //TO-DO: Implement Go Api to delete memory from Redis
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Allow pull-to-refresh
            fetchMemories()
        }
    }
    
    // MARK: - Toolbar Items
    
    private var leadingToolbarItem: ToolbarItem<(), some View> {
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
    }
    
    private var trailingToolbarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                showingAddMemorySheet.toggle()
            }) {
                Image(systemName: "plus")
            }
        }
    }
}
