//
//  HeaderView.swift
//  UMSS
//
//  Created by GitHub Copilot
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("UMSS Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 400) // Adjust as needed
        }
        .padding(.top, 0)
    }
}

#Preview {
    HeaderView()
}
