//
//  ChoiceComponents.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI

public struct ChoicePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .foregroundColor(isSelected ? .white : .primary)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color(.systemGray3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

public struct ChoiceRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ChoiceComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ChoicePill(title: "Option 1", isSelected: true) {}
            ChoicePill(title: "Option 2", isSelected: false) {}
            
            ChoiceRow(title: "Selection 1", isSelected: true) {}
            ChoiceRow(title: "Selection 2", isSelected: false) {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
