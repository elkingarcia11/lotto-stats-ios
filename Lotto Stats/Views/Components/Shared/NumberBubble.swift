import SwiftUI

/// A view that displays a lottery number in a circular bubble
/// - Note: Used across different lottery views to maintain consistent number display
struct NumberBubble: View {
    let number: Int
    var isSpecial: Bool = false
    
    var body: some View {
        Text("\(number)")
            .font(.system(.body, design: .rounded, weight: .bold))
            .frame(width: 36, height: 36)
            .background(isSpecial ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .clipShape(Circle())
    }
}

#Preview {
    HStack {
        NumberBubble(number: 42)
        NumberBubble(number: 7, isSpecial: true)
    }
    .padding()
} 
