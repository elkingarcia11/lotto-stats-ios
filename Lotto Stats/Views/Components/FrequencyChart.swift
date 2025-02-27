import SwiftUI

struct PercentageChart: View {
    let title: String
    let percentages: [NumberPercentage]
    @State private var searchText: String = ""
    
    init(title: String, percentages: [NumberPercentage]) {
        self.title = title
        self.percentages = percentages.sorted { $0.number < $1.number }
    }
    
    var filteredPercentages: [NumberPercentage] {
        if searchText.isEmpty {
            return percentages
        }
        return percentages.filter { String($0.number).contains(searchText) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding()
            
            if percentages.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
            } else {
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search number", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    .padding(.horizontal)
                    
                    // Numbers List
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 8) {
                            ForEach(filteredPercentages) { item in
                                HStack {
                                    Text("Number \(item.number)")
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                    Text(String(format: "%.1f%%", item.percentage))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    .frame(height: 200)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PercentageChart_Previews: PreviewProvider {
    static var previews: some View {
        PercentageChart(
            title: "Number Percentages",
            percentages: [
                NumberPercentage(number: 1, percentage: 5.0),
                NumberPercentage(number: 2, percentage: 7.5),
                NumberPercentage(number: 3, percentage: 4.0)
            ]
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
