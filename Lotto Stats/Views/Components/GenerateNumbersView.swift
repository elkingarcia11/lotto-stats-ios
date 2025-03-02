import SwiftUI

struct GeneratedNumbers: Codable {
    let main_numbers: [Int]
    let special_ball: Int
    let position_percentages: [String: Double]?
    let is_unique: Bool
}

struct GenerateNumbersView: View {
    let type: LotteryType
    @State private var generatedNumbers: GeneratedNumbers?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Generated Numbers Display
                if let numbers = generatedNumbers {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Generated Numbers")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(numbers.main_numbers.sorted(), id: \.self) { number in
                                NumberBubble(number: number)
                            }
                            NumberBubble(number: numbers.special_ball, isSpecial: true)
                        }
                        
                        if let percentages = numbers.position_percentages, !percentages.isEmpty {
                            Text("Position Percentages")
                                .font(.headline)
                            
                            ForEach(percentages.sorted(by: { $0.key < $1.key }), id: \.key) { position, percentage in
                                HStack {
                                    Text("Position \(position):")
                                    Text(String(format: "%.2f%%", percentage))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text("Note: This is a unique combination optimized based on historical data. While it has never won before, past performance does not guarantee future results.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        } else {
                            Text("Note: This is a completely random unique combination that has never won before. It is not optimized based on historical data.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else if !isLoading {
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
                
                // Disclaimer
                Text("Gambling Disclaimer: Playing the lottery involves risk and should be done responsibly. These generated numbers are for entertainment purposes only and do not guarantee any winnings.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Generate Buttons
                VStack(spacing: 16) {
                    Button {
                        Task {
                            await generateNumbers(optimized: true)
                        }
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
                        Task {
                            await generateNumbers(optimized: false)
                        }
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
            .padding()
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
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
            generatedNumbers = try JSONDecoder().decode(GeneratedNumbers.self, from: data)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    GenerateNumbersView(type: .megaMillions)
        .padding()
}
