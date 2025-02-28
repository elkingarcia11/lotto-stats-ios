import SwiftUI

struct LatestNumbersView: View {
    let type: LotteryType
    let results: [DrawResult]
    @State private var searchText = ""
    @State private var selectedNumber: Int?
    
    var filteredResults: [DrawResult] {
        if searchText.isEmpty && selectedNumber == nil {
            return results
        }
        
        return results.filter { result in
            let matchesSearch = searchText.isEmpty ||
                result.drawDate.contains(searchText)
            
            let matchesNumber = selectedNumber == nil ||
                result.mainNumbers.contains(selectedNumber!) ||
                result.specialBall == selectedNumber
            
            return matchesSearch && matchesNumber
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search by date (YYYY-MM-DD)", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Number filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: { selectedNumber = nil }) {
                        Text("All")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedNumber == nil ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedNumber == nil ? .white : .primary)
                            .cornerRadius(8)
                    }
                    
                    ForEach(1...type.mainNumberRange.upperBound, id: \.self) { number in
                        Button(action: { selectedNumber = number }) {
                            Text("\(number)")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedNumber == number ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedNumber == number ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Results list
            List(filteredResults) { result in
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.drawDate)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(result.mainNumbers, id: \.self) { number in
                            NumberBall(
                                number: number,
                                color: selectedNumber == number ? .green : .blue
                            )
                            .frame(width: 32, height: 32)
                        }
                        
                        NumberBall(
                            number: result.specialBall,
                            color: .clear,
                            background: type == .megaMillions ?
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 32, height: 32)
                        
                        Spacer()
                        
                        Text("×\(result.multiplier)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Latest Results")
    }
}

#Preview {
    NavigationView {
        LatestNumbersView(
            type: .megaMillions,
            results: [
                DrawResult(
                    drawDate: "2024-03-15",
                    mainNumbers: [1, 2, 3, 4, 5],
                    specialBall: 6,
                    multiplier: 3
                ),
                DrawResult(
                    drawDate: "2024-03-12",
                    mainNumbers: [10, 20, 30, 40, 50],
                    specialBall: 15,
                    multiplier: 2
                )
            ]
        )
    }
}
