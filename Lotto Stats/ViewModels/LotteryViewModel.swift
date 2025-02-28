import Foundation
import SwiftUI

@MainActor
class LotteryViewModel: ObservableObject {
    // MARK: - Types
    enum ViewState: Equatable {
        case idle
        case loading
        case error(String)
        case loaded
        
        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.loading, .loading),
                 (.loaded, .loaded):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    struct FrequencyState {
        var numberPercentages: [NumberPercentage] = []
        var positionPercentages: [PositionPercentages] = []
        var specialBallPercentages: [NumberPercentage] = []
    }
    
    struct SelectionState {
        var selectedNumbers: Set<Int> = []
        var selectedSpecialBall: Int?
        var winningDates: [String]?
        var frequency: Int?
        
        var canCheckCombination: Bool {
            selectedNumbers.count == 5 && selectedSpecialBall != nil
        }
    }
    
    // MARK: - Properties
    let type: LotteryType
    private let networkService: NetworkServiceProtocol
    
    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var frequencyState = FrequencyState()
    @Published var selectionState = SelectionState()
    @Published var latestResults: [DrawResult] = []
    
    var error: String? {
        if case .error(let message) = viewState {
            return message
        }
        return nil
    }
    
    var isLoading: Bool {
        viewState == .loading
    }
    
    // MARK: - Initialization
    init(type: LotteryType, networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.type = type
        self.networkService = networkService
    }
    
    // MARK: - Public Methods
    func loadAllData() async {
        viewState = .loading
        
        do {
            async let latestNumbersTask = networkService.fetchLatestNumbers(for: type, limit: nil)
            async let frequencyTask = networkService.fetchFrequencies(for: type)
            async let positionFrequencyTask = networkService.fetchPositionFrequencies(for: type)
            async let specialBallFrequencyTask = networkService.fetchSpecialBallFrequencies(for: type)
            
            let (latestNumbersResponse, frequencyResponse, positionFrequencyResponse, specialBallFrequencyResponse) = 
                try await (latestNumbersTask, frequencyTask, positionFrequencyTask, specialBallFrequencyTask)
            
            latestResults = latestNumbersResponse.data.latestNumbers
            frequencyState.numberPercentages = parsePercentages(frequencyResponse.data.frequencies)
            frequencyState.positionPercentages = parsePositionPercentages(positionFrequencyResponse.data.positionFrequencies)
            
            // Handle special ball frequencies based on lottery type
            let specialBallFreqs = type == .megaMillions ? 
                specialBallFrequencyResponse.data.megaBallFrequencies :
                specialBallFrequencyResponse.data.powerballFrequencies
            frequencyState.specialBallPercentages = parsePercentages(specialBallFreqs)
            
            viewState = .loaded
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
    
    func checkCombination() async {
        guard selectionState.canCheckCombination else { return }
        
        viewState = .loading
        selectionState.winningDates = nil
        selectionState.frequency = nil
        
        do {
            let response = try await networkService.checkCombination(
                numbers: Array(selectionState.selectedNumbers).sorted(),
                specialBall: selectionState.selectedSpecialBall!,
                type: type
            )
            
            selectionState.winningDates = response.data.dates
            selectionState.frequency = response.data.frequency
            viewState = .loaded
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
    
    func generateCombination() async {
        viewState = .loading
        
        do {
            let response = try await networkService.generateCombination(for: type)
            selectionState.selectedNumbers = Set(response.data.mainNumbers)
            selectionState.selectedSpecialBall = response.data.specialBall
            viewState = .loaded
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
    
    func toggleNumber(_ number: Int) {
        if selectionState.selectedNumbers.contains(number) {
            selectionState.selectedNumbers.remove(number)
        } else if selectionState.selectedNumbers.count < 5 {
            selectionState.selectedNumbers.insert(number)
        }
        resetResults()
    }
    
    func selectSpecialBall(_ number: Int) {
        if selectionState.selectedSpecialBall == number {
            selectionState.selectedSpecialBall = nil
        } else {
            selectionState.selectedSpecialBall = number
        }
        resetResults()
    }
    
    // MARK: - Private Methods
    private func resetResults() {
        selectionState.winningDates = nil
        selectionState.frequency = nil
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