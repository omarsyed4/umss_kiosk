//
//  SectionCard.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI

public struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            VStack {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct SectionCard_Previews: PreviewProvider {
    static var previews: some View {
        SectionCard(title: "Example Section") {
            Text("Content goes here")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
