//
//  AISearch.swift
//  CloudStroll
//
//  Created by Amey Sunu on 06/08/2025.
//

import SwiftUI

struct AISearchRow: View {
    
    let memory: Memory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundColor(.pink)
                
                Text(memory.location)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                
                Spacer()
            }
            
            Text(memory.entry)
                .font(.body)
                .lineSpacing(4)
            
            HStack(spacing: 20) {
                Text(memory.timestamp.toFormattedDateString()!)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: memory.iconName)
                
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
