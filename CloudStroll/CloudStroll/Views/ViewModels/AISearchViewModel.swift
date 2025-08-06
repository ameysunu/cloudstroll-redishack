//
//  AISearchViewModel.swift
//  CloudStroll
//
//  Created by Amey Sunu on 06/08/2025.
//

import SwiftUI
import Foundation

class AISearchViewModel : ObservableObject {
    
    @Published var memories: [Memory] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var hasSearched: Bool = false
    
    let apiCtrl = ApiController()
    
    var filteredMemories: [Memory] {
            guard !searchText.isEmpty else {
                return memories
            }
            return memories.filter { memory in
                memory.location.localizedCaseInsensitiveContains(searchText) ||
                memory.entry.localizedCaseInsensitiveContains(searchText)
            }
        }
    
    func searchForMemories() {
      hasSearched = true
      isLoading = true

      apiCtrl.semanticSearchMemories(for: searchText) { result in
        DispatchQueue.main.async {
          defer { self.isLoading = false }
          switch result {
          case .success(let memories):           
            self.memories = memories
          case .failure(let error):
            print("Error fetching memories: \(error)")
            self.memories = []
          }
        }
      }
    }
}
