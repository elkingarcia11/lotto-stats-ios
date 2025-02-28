import SwiftUI

struct FrequencyChartsView: View {
    let type: LotteryType
    let numberPercentages: [NumberPercentage]
    let positionPercentages: [PositionPercentages]
    let specialBallPercentages: [NumberPercentage]
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("Chart Type", selection: $selectedTab) {
                Text("General").tag(0)
                Text("By Position").tag(1)
                Text(type.specialBallName).tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            TabView(selection: $selectedTab) {
                // General Frequencies
                ScrollView {
                    PercentageChart(
                        title: "Number Frequencies",
                        percentages: numberPercentages
                    )
                    .padding()
                }
                .tag(0)
                
                // Position Frequencies
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(positionPercentages) { position in
                            PercentageChart(
                                title: "Position \(position.position)",
                                percentages: position.percentages
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .tag(1)
                
                // Special Ball Frequencies
                ScrollView {
                    PercentageChart(
                        title: "\(type.specialBallName) Frequencies",
                        percentages: specialBallPercentages
                    )
                    .padding()
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Frequency Analysis")
    }
}

#Preview {
    NavigationView {
        FrequencyChartsView(
            type: .megaMillions,
            numberPercentages: [
                NumberPercentage(number: 1, percentage: 5.0),
                NumberPercentage(number: 2, percentage: 7.5),
                NumberPercentage(number: 3, percentage: 4.0)
            ],
            positionPercentages: [
                PositionPercentages(
                    position: 1,
                    percentages: [
                        NumberPercentage(number: 1, percentage: 3.0),
                        NumberPercentage(number: 2, percentage: 4.0)
                    ]
                )
            ],
            specialBallPercentages: [
                NumberPercentage(number: 1, percentage: 6.0),
                NumberPercentage(number: 2, percentage: 8.0)
            ]
        )
    }
} 
