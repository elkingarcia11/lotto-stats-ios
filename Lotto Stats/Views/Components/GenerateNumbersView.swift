import SwiftUI

struct GenerateNumbersView: View {
    let type: LotteryType
    @State private var generatedCombination: LotteryGenerationResponse?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Generated Numbers Display
                if let combination = generatedCombination {
                    GeneratedCombinationCard(combination: combination)
                } else if !isLoading {
                    EmptyGenerationState()
                }
                
                // Disclaimer
                LotteryDisclaimerText()
                
                // Generate Buttons
                GenerationControls { isOptimized in
                    Task {
                        await generateNumbers(optimized: isOptimized)
                    }
                }
            }
            .padding()
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
        .alert("Error", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = error {
                Text(error)
            }
        }
    }
    
    private func generateNumbers(optimized: Bool) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let urlString = "http://localhost:8000/\(type.rawValue)/generate-\(optimized ? "optimized" : "random")"
            guard let url = URL(string: urlString) else {
                error = "Invalid URL"
                return
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            generatedCombination = try JSONDecoder().decode(LotteryGenerationResponse.self, from: data)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Subviews

/// Displays a card containing the generated lottery numbers and analysis
private struct GeneratedCombinationCard: View {
    let combination: LotteryGenerationResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generated Numbers")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(combination.main_numbers.sorted(), id: \.self) { number in
                    NumberBubble(number: number)
                }
                NumberBubble(number: combination.special_ball, isSpecial: true)
            }
            
            if let percentages = combination.position_percentages, !percentages.isEmpty {
                PositionPercentagesView(percentages: percentages)
                OptimizedGenerationNote()
            } else {
                RandomGenerationNote()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Displays position-based percentage analysis for optimized number combinations
private struct PositionPercentagesView: View {
    let percentages: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Position Percentages")
                .font(.headline)
            
            ForEach(percentages.sorted(by: { $0.key < $1.key }), id: \.key) { position, percentage in
                HStack {
                    Text("Position \(position):")
                    Text(String(format: "%.2f%%", percentage))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/// Displays a disclaimer note for optimized number generation
private struct OptimizedGenerationNote: View {
    var body: some View {
        Text("Note: This is a unique combination optimized based on historical data. While it has never won before, past performance does not guarantee future results.")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)
    }
}

/// Displays a disclaimer note for random number generation
private struct RandomGenerationNote: View {
    var body: some View {
        Text("Note: This is a completely random unique combination that has never won before. It is not optimized based on historical data.")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)
    }
}

/// Displays a placeholder state when no numbers have been generated
private struct EmptyGenerationState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "ticket")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No numbers generated yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Use the buttons below to generate numbers")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Displays the gambling disclaimer and responsible gaming message
private struct LotteryDisclaimerText: View {
    var body: some View {
        Text("Gambling Disclaimer: Playing the lottery involves risk and should be done responsibly. These generated numbers are for entertainment purposes only and do not guarantee any winnings.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

/// Control panel for generating lottery numbers
/// - Note: Provides buttons for both optimized and random number generation
private struct GenerationControls: View {
    let onGenerate: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button {
                onGenerate(true)
            } label: {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Generate Optimized Numbers")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button {
                onGenerate(false)
            } label: {
                HStack {
                    Image(systemName: "dice")
                    Text("Generate Random Numbers")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray4))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
        }
    }
}

/// Overlay view displayed during number generation
private struct LoadingOverlay: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
    }
}

#Preview {
    GenerateNumbersView(type: .megaMillions)
        .padding()
}
