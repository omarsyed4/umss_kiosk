import SwiftUI

struct ActionButton: View {
    let title: String
    let iconName: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .font(.headline)
                Text(title)
                    .fontWeight(.medium)
                    .font(.headline)
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
        }
    }
}
