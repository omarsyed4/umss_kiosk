//
//  LoadingView.swift
//  UMSS
//
//  Created by Omar Syed
//

import SwiftUI

struct LoadingView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemGray6).opacity(0.95))
                    .shadow(radius: 10)
            )
        }
        .transition(.opacity)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String) -> some View {
        ZStack {
            self
            
            if isLoading {
                LoadingView(message: message)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: isLoading)
    }
}

#Preview {
    VStack {
        Text("Background Content")
            .font(.largeTitle)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
    .loadingOverlay(isLoading: true, message: "Loading patient data...\nPreparing your form...")
}
