import SwiftUI

struct LotteryView: View {
    @StateObject private var viewModel: LotteryViewModel
    @State private var selectedTab = 0
    
    init(type: LotteryType) {
        _viewModel = StateObject(wrappedValue: LotteryViewModel(type: type))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TabView(selection: $selectedTab) {
                    statisticsView
                        .tag(0)
                    
                    combinationView
                        .tag(1)
                }
                .frame(height: UIScreen.main.bounds.height * 0.8)
                .tabViewStyle(.page)
            }
            .padding()
        }
        .navigationTitle(viewModel.type == .megaMillions ? "Mega Millions" : "Powerball")
        .task {
            await viewModel.loadAllData()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
    
    private var statisticsView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 20) {
                // Overall number percentages first
                PercentageChart(
                    title: "Overall Number Percentages",
                    percentages: viewModel.numberPercentages
                )
                .padding(.top)
                
                // Special ball percentages second
                PercentageChart(
                    title: "\(viewModel.type.specialBallName) Percentages",
                    percentages: viewModel.specialBallPercentages
                )
                
                // Position-based percentages last
                ForEach(viewModel.positionPercentages) { position in
                    PercentageChart(
                        title: "Position \(position.position) Percentages",
                        percentages: position.percentages
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var combinationView: some View {
        VStack(spacing: 20) {
            Text("Select Your Numbers")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Main Numbers (select 5)")
                    .font(.headline)
                
                NumberGrid(
                    range: viewModel.type.mainNumberRange,
                    selectedNumbers: viewModel.selectedNumbers,
                    maxSelections: 5,
                    onNumberTapped: viewModel.toggleNumber
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(viewModel.type.specialBallName) (select 1)")
                    .font(.headline)
                
                NumberGrid(
                    range: viewModel.type.specialBallRange,
                    selectedNumbers: viewModel.selectedSpecialBall.map { [$0] } ?? [],
                    maxSelections: 1,
                    onNumberTapped: viewModel.selectSpecialBall
                )
            }
            
            HStack(spacing: 20) {
                Button {
                    Task {
                        await viewModel.checkCombination()
                    }
                } label: {
                    Text("Check Combination")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedNumbers.count != 5 || viewModel.selectedSpecialBall == nil)
                
                Button {
                    Task {
                        await viewModel.generateCombination()
                    }
                } label: {
                    Text("Generate Combination")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            
            if let exists = viewModel.combinationExists {
                Text(exists ? "This combination has been drawn before!" : "This is a unique combination.")
                    .foregroundColor(exists ? .red : .green)
                    .font(.headline)
                    .padding(.top)
            }
        }
    }
}

struct LotteryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LotteryView(type: .megaMillions)
        }
    }
} 
