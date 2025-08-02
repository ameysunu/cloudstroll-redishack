//
//  MemoryRowView.swift
//  CloudStroll
//
//  Created by Amey Sunu on 01/08/2025.
//

import SwiftUI

struct MemoryRowView: View {
    let memory: Memory
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: memory.iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(memory.location)
                    .lineLimit(1)
                
                Text(memory.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}
