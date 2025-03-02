import SwiftUI

struct GenerateNumbersView: View {
    let type: LotteryType
    @State private var generatedCombination: LotteryGenerationResponse?
    @State private var isLoading = false
    @State private var error: String?
    @State private var animationId = UUID()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Generated Numbers Display
                if let combination = generatedCombination {
                    GeneratedCombinationCard(combination: combination)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else if !isLoading {
                    EmptyGenerationState()
                        .transition(.opacity)
                }
                
                // Generate Buttons
                GenerationControls { isOptimized in
                    Task {
                        await generateNumbers(optimized: isOptimized)
                    }
                }
                
                // Disclaimer moved to bottom
                LotteryDisclaimerText()
            }
            .padding()
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animationId)
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: isLoading)
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
            animationId = UUID()
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
            Text("Your Numbers")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(combination.main_numbers.sorted(), id: \.self) { number in
                    NumberBubble(number: number)
                }
                NumberBubble(number: combination.special_ball, isSpecial: true)
            }
            .padding(.vertical, 8)
            
            if let percentages = combination.position_percentages, !percentages.isEmpty {
                Divider()
                PositionPercentagesView(percentages: percentages)
                OptimizedGenerationNote()
            } else {
                Divider()
                RandomGenerationNote()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
        )
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
        VStack(spacing: 16) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                                 startPoint: .top,
                                 endPoint: .bottom)
                )
            
            Text("Ready to Try Your Luck?")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text("Generate your numbers below")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
        )
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
            .padding(.top, 8)
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
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.blue, .blue.opacity(0.8)],
                                 startPoint: .top,
                                 endPoint: .bottom)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            
            Button {
                onGenerate(false)
            } label: {
                HStack {
                    Image(systemName: "dice")
                    Text("Generate Random Numbers")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
}

/// Overlay view displayed during number generation
private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .frame(width: 120, height: 120)
                .overlay {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .shadow(color: .black.opacity(0.1), radius: 10)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GenerateNumbersView(type: .megaMillions)
        .padding()
}
