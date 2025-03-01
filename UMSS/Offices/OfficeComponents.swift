//
//  OfficeComponents.swift
//  UMSS
//
//  Created by Omar Syed
//

import SwiftUI

// Office Selection Row
struct OfficeSelectionRow: View {
    let office: Office
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(office.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(office.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(office.phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OfficeInfoView: View {
    let office: Office
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(office.name)
                .font(.title3)
                .fontWeight(.bold)
            Text(office.address)
                .font(.subheadline)
            Text(office.phone)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
    }
}
