import Foundation
import SwiftUI

@MainActor
class LotteryViewModel: ObservableObject {
    private let networkService = NetworkService.shared
    let type: LotteryType
    
    @Published var numberPercentages: [NumberPercentage] = []
    @Published var positionPercentages: [PositionPercentages] = []
    @Published var specialBallPercentages: [NumberPercentage] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedNumbers: Set<Int> = []
    @Published var selectedSpecialBall: Int?
    @Published var generatedCombination: CombinationData?
    @Published var combinationExists: Bool?
    
    init(type: LotteryType) {
        self.type = type
    }
    
    func loadAllData() async {
        isLoading = true
        error = nil
        
        do {
            async let frequenciesTask = networkService.fetchFrequencies(for: type)
            async let positionFrequenciesTask = networkService.fetchPositionFrequencies(for: type)
            async let specialBallFrequenciesTask = networkService.fetchSpecialBallFrequencies(for: type)
            
            let (frequencies, positionFrequencies, specialBallFrequencies) = try await (frequenciesTask, positionFrequenciesTask, specialBallFrequenciesTask)
            
            self.numberPercentages = parsePercentages(frequencies.data.frequencies)
            self.positionPercentages = parsePositionPercentages(positionFrequencies.data.positionFrequencies)
            self.specialBallPercentages = parsePercentages(specialBallFrequencies.data.frequencies)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func checkCombination() async {
        guard selectedNumbers.count == 5, let specialBall = selectedSpecialBall else {
            error = "Please select 5 numbers and a special ball"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await networkService.checkCombination(
                type: type,
                numbers: Array(selectedNumbers).sorted(),
                specialBall: specialBall
            )
            combinationExists = response.data.exists
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func generateCombination() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await networkService.generateCombination(for: type)
            generatedCombination = response.data
            
            if let numbers = response.data.mainNumbers {
                selectedNumbers = Set(numbers)
            }
            selectedSpecialBall = response.data.specialBall
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleNumber(_ number: Int) {
        if selectedNumbers.contains(number) {
            selectedNumbers.remove(number)
        } else if selectedNumbers.count < 5 {
            selectedNumbers.insert(number)
        }
    }
    
    func selectSpecialBall(_ number: Int) {
        selectedSpecialBall = number
    }
    
    private func parsePercentages(_ frequencies: [String: Double]?) -> [NumberPercentage] {
        guard let frequencies = frequencies else { return [] }
        
        return frequencies
            .compactMap { key, value in
                guard let number = Int(key) else { return nil }
                return NumberPercentage(number: number, percentage: value)
            }
            .sorted { $0.number < $1.number }
    }
    
    private func parsePositionPercentages(_ positionFrequencies: [String: [String: Double]]?) -> [PositionPercentages] {
        guard let positionFrequencies = positionFrequencies else { return [] }
        return positionFrequencies
            .compactMap { key, value in
                guard let position = key.components(separatedBy: "_").last,
                      let positionNumber = Int(position) else { return nil }
                
                let percentages = parsePercentages(value)
                return PositionPercentages(position: positionNumber, percentages: percentages)
            }
            .sorted { $0.position < $1.position }
    }
} 