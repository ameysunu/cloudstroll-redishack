//
//  TrendsViewModel.swift
//  CloudStroll
//
//  Created by Amey Sunu on 04/08/2025.
//

import Foundation
import SwiftUI

@MainActor
class TrendsViewModel: ObservableObject {
    @Published var points: [TrendPointData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = ApiController()

    func fetchTrends(from: Date, to: Date) {
        isLoading = true
        errorMessage = nil

        api.fetchTrends(from: from, to: to) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let rawDict):
                    var all: [TrendPointData] = []
                    for (mood, pts) in rawDict {
                        for pt in pts {
                            let date = Date(timeIntervalSince1970: Double(pt.timestamp)/1000)
                            all.append(
                              TrendPointData(mood: mood, date: date, value: pt.value)
                            )
                        }
                    }
                    self.points = all.sorted { $0.date < $1.date }

                case .failure(let afError):
                    self.errorMessage = afError.errorDescription ?? afError.localizedDescription
                    self.points = []
                }
            }
        }
    }
}
