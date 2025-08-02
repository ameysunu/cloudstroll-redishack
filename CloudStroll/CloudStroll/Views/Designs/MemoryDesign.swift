//
//  MemoryDesign.swift
//  CloudStroll
//
//  Created by Amey Sunu on 02/08/2025.
//
import SwiftUI
import Foundation

struct CustomPicker<T: RawRepresentable & CaseIterable & Hashable & Identifiable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection, T.ID == T {
    @Binding var selection: T

    var body: some View {
        Menu {
            ForEach(T.allCases) { item in
                Button(action: {
                    self.selection = item
                }) {
                    Text(item.rawValue.capitalized)
                }
            }
        } label: {
            HStack {
                Text(selection.rawValue.capitalized)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.secondary)
            }
        }
        .modifier(FormFieldStyle())
    }
}


struct FormFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
    }
}
