import Foundation

// MARK: - API Responses
struct FrequencyResponse: Codable {
    let success: Bool
    let data: FrequencyData
    let message: String
}

struct FrequencyData: Codable {
    let frequencies: [String: Double]?
    let positionFrequencies: [String: [String: Double]]?
    
    enum CodingKeys: String, CodingKey {
        case frequencies
        case positionFrequencies = "position_frequencies"
    }
}

// MARK: - Combination Response
struct CombinationResponse: Codable {
    let success: Bool
    let data: CombinationData
    let message: String
}

struct CombinationData: Codable {
    let exists: Bool?
    let mainNumbers: [Int]?
    let specialBall: Int?
    
    enum CodingKeys: String, CodingKey {
        case exists
        case mainNumbers = "main_numbers"
        case specialBall = "powerball"
    }
}

// MARK: - View Models
struct NumberPercentage: Identifiable, Equatable {
    let id = UUID()
    let number: Int
    let percentage: Double
    
    static func == (lhs: NumberPercentage, rhs: NumberPercentage) -> Bool {
        lhs.number == rhs.number
    }
}

struct PositionPercentages: Identifiable {
    let id = UUID()
    let position: Int
    let percentages: [NumberPercentage]
}

enum LotteryType {
    case megaMillions
    case powerball
    
    var baseURL: String {
        switch self {
        case .megaMillions:
            return "/mega-millions"
        case .powerball:
            return "/powerball"
        }
    }
    
    var specialBallName: String {
        switch self {
        case .megaMillions:
            return "Mega Ball"
        case .powerball:
            return "Powerball"
        }
    }
    
    var mainNumberRange: ClosedRange<Int> {
        switch self {
        case .megaMillions:
            return 1...70
        case .powerball:
            return 1...69
        }
    }
    
    var specialBallRange: ClosedRange<Int> {
        switch self {
        case .megaMillions:
            return 1...25
        case .powerball:
            return 1...26
        }
    }
} 