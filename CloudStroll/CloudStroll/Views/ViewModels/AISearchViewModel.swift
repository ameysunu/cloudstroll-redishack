//
//  AISearchViewModel.swift
//  CloudStroll
//
//  Created by Amey Sunu on 06/08/2025.
//
import SwiftUI
import Foundation


class AISearchViewModel: ObservableObject {
    
  @Published var memories: [Memory] = []
  @Published var searchText = ""
  @Published var isLoading = false
  @Published var hasSearched = false

  private var searchTask: Task<Void, Never>?
  private let apiCtrl = ApiController()

  func searchForMemories() {
    searchTask?.cancel()

    let query = searchText.trimmingCharacters(in: .whitespaces)
    guard !query.isEmpty else { return }

    hasSearched = true
    isLoading = true

    searchTask = Task { [weak self] in
      guard let self = self else { return }
      do {
        let fetched = try await apiCtrl.semanticSearchMemories(for: query)
        guard !Task.isCancelled else { return }
        await MainActor.run {
          self.memories = fetched
          self.isLoading = false
        }
      } catch {
        guard !Task.isCancelled else { return }
        await MainActor.run {
          self.memories = []
          self.isLoading = false
        }
      }
    }
  }
}
