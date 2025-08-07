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
        let vm = viewModel
        
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
                        
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding(.top, 50)
                        } else if !vm.hasSearched {
                            InitialStateView()
                        } else if vm.memories.isEmpty {
                            NoResultsView()
                        } else {
                            ForEach(vm.memories) { memory in
                                AISearchRow(memory: memory)
                                    .transition(.opacity.combined(with: .scale(0.8)))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search by location or keyword...")
        .submitLabel(.search)
        .onSubmit(of: [.search, .text]) {
            viewModel.searchForMemories()
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
