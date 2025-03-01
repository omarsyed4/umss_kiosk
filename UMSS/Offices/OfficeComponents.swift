//
//  OfficeComponents.swift
//  UMSS
//
//  Created by Omar Syed
//

import SwiftUI

// Office Display Row (non-interactive)
struct OfficeDisplayRow: View {
    let office: Office
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(office.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(office.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
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
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
    }
}
