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
                        Image("MegaMillions")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                            .foregroundColor(.green)
                    }
                }
                
                NavigationLink {
                    LotteryView(type: .powerball)
                } label: {
                    HStack {
                        Image("Powerball")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Lotto Stats")
        }
    }
}

#Preview {
    ContentView()
}
