//
//  MemoryMapView.swift
//  CloudStroll
//
//  Created by Amey Sunu on 03/08/2025.
//
import SwiftUI
import MapKit
import SwiftUI
import MapKit

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct MemoryMapView: View {
    @StateObject private var vm = MemoryMapViewModel()
    @State private var hasDismissedBanner = false
    
    //Temporarily hardcoding lat long instead of getting current user location
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.3765, longitude: 2.1925),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map layer
                Map(
                    coordinateRegion: $region,
                    annotationItems: vm.memories
                ) { memory in
                    MapAnnotation(
                        coordinate: CLLocationCoordinate2D(
                            latitude: memory.latitude,
                            longitude: memory.longitude
                        )
                    ) {
                        NavigationLink(destination: MemoryView(memory: memory)) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Informational banner
                if !hasDismissedBanner {
                    VStack {
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "info.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Nearby Memories")
                                    .font(.headline)
                                Text("The map displays memories based on your visible location. Pan and zoom to discover more.")
                                    .font(.subheadline)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Button {
                                withAnimation(.spring()) {
                                    hasDismissedBanner = true
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.gray, .gray.opacity(0.2))
                            }
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            vm.loadNearby(center: region.center)
                        } label: {
                            Image(systemName: "location.fill")
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Map")
            .onAppear {
                vm.loadNearby(center: region.center)
            }
            .onChange(of: region.center) { newCenter in
                vm.loadNearby(center: newCenter)
            }
        }
    }
}

// MARK: - View Model

final class MemoryMapViewModel: ObservableObject {
    @Published var memories: [Memory] = []
    private let api = ApiController()
    
    func loadNearby(center: CLLocationCoordinate2D) {
        Task {
            do {
                let results = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Memory], Error>) in
                    api.fetchNearbyMemories(
                        lat: center.latitude,
                        long: center.longitude
                    ){ result in
                        
                        switch result{
                        case .success(let mems):
                            continuation.resume(returning: mems)
                            
                        case .failure(let err):
                            continuation.resume(throwing: err)
                            
                        }
                    }
                }
                await MainActor.run {
                    self.memories = results
                }
            } catch {
                print("Failed to load nearby memories:", error)
            }
        }
    }
}
