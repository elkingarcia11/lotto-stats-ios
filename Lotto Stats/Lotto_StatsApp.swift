import SwiftUI

@main
struct Lotto_StatsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    LotteryView(type: .megaMillions)
                } label: {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        Text("Mega Millions")
                    }
                }
                
                NavigationLink {
                    LotteryView(type: .powerball)
                } label: {
                    HStack {
                        Image(systemName: "powerplug.fill")
                            .foregroundColor(.red)
                        Text("Powerball")
                    }
                }
            }
            .navigationTitle("Lotto Stats")
        }
    }
}
