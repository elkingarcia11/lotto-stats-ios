import SwiftUI

struct LotteryView: View {
    @StateObject private var viewModel: LotteryViewModel
    @State private var showingResults = false
    @State private var showingError = false
    @State private var selectedTab = 0
    
    init(type: LotteryType) {
        _viewModel = StateObject(wrappedValue: LotteryViewModel(type: type))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Pick Numbers Tab
            pickNumbersView
                .tabItem {
                    Label("Pick Numbers", systemImage: "number.circle")
                }
                .tag(0)
            
            // Latest Results Tab
            LatestNumbersView(type: viewModel.type, results: viewModel.latestResults)
                .tabItem {
                    Label("Latest Results", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Frequency Analysis Tab
            FrequencyChartsView(
                type: viewModel.type,
                numberPercentages: viewModel.frequencyState.numberPercentages,
                positionPercentages: viewModel.frequencyState.positionPercentages,
                specialBallPercentages: viewModel.frequencyState.specialBallPercentages
            )
            .tabItem {
                Label("Analysis", systemImage: "chart.bar")
            }
            .tag(2)
        }
        .task {
            await viewModel.loadAllData()
        }
    }
    
    private var pickNumbersView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Main Numbers (select 5)")
                    .font(.headline)
                
                NumberGrid(
                    range: viewModel.type.mainNumberRange,
                    selectedNumbers: viewModel.selectionState.selectedNumbers,
                    maxSelections: 5,
                    onNumberTapped: viewModel.toggleNumber
                )
                
                Text("\(viewModel.type.specialBallName) (select 1)")
                    .font(.headline)
                
                NumberGrid(
                    range: viewModel.type.specialBallRange,
                    selectedNumbers: viewModel.selectionState.selectedSpecialBall.map { [$0] } ?? [],
                    maxSelections: 1,
                    onNumberTapped: viewModel.selectSpecialBall
                )
                
                if viewModel.selectionState.canCheckCombination {
                    Button {
                        Task {
                            await viewModel.checkCombination()
                            showingResults = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Check Numbers")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(viewModel.type == .megaMillions ? "MegaMillions" : "Powerball")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                    .foregroundColor(viewModel.type == .megaMillions ? .green : .red)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .onChange(of: viewModel.error) { error in
            showingError = error != nil
        }
        .navigationDestination(isPresented: $showingResults) {
            if let specialBall = viewModel.selectionState.selectedSpecialBall {
                LotteryResultView(
                    type: viewModel.type,
                    numbers: Array(viewModel.selectionState.selectedNumbers).sorted(),
                    specialBall: specialBall,
                    winningDates: viewModel.selectionState.winningDates,
                    frequency: viewModel.selectionState.frequency
                )
            }
        }
    }
}

struct DrawResultRow: View {
    let result: DrawResult
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(result.drawDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                ForEach(result.mainNumbers, id: \.self) { number in
                    NumberBubble(number: number)
                }
                NumberBubble(number: result.specialBall, isSpecial: true)
                Text("x\(result.multiplier)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct NumberBubble: View {
    let number: Int
    var isSpecial: Bool = false
    
    var body: some View {
        Text("\(number)")
            .font(.system(.body, design: .rounded))
            .frame(width: 32, height: 32)
            .background(isSpecial ? Color.yellow.opacity(0.2) : Color.blue.opacity(0.2))
            .clipShape(Circle())
    }
}

struct LotteryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LotteryView(type: .megaMillions)
        }
    }
} 
