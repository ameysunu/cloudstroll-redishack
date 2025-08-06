//
//  AISearch.swift
//  CloudStroll
//
//  Created by Amey Sunu on 06/08/2025.
//

import SwiftUI

struct AISearchView: View {
    @StateObject private var viewModel = AISearchViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack {
                            Text("Travel Memories")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            Text("Search to recall your adventures")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.bottom, 10)
                        
                        mainContentView
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search by location or keyword...")
        .onSubmit(of: .search, viewModel.searchForMemories) // Triggers the search
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.filteredMemories.map(\.id))
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding(.top, 50)
        } else if !viewModel.hasSearched {
            InitialStateView()
        } else if viewModel.filteredMemories.isEmpty && viewModel.hasSearched {
            NoResultsView()
        } else {
            ForEach(viewModel.filteredMemories) { memory in
                AISearchRow(memory: memory)
                    .transition(.opacity.combined(with: .scale(0.8)))
            }
        }
    }
}

struct InitialStateView: View {
    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
                .padding()
            Text("Ready to Reminisce?")
                .font(.title2).bold()
                .foregroundColor(.white)
            Text("Type in the search bar above and press 'Search' to find your memories.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 50)
    }
}

struct NoResultsView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
                .padding()
            Text("No Memories Found")
                .font(.title2).bold()
                .foregroundColor(.white)
            Text("Try searching for something else, like 'Barcelona' or 'beach'.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 50)
    }
}
