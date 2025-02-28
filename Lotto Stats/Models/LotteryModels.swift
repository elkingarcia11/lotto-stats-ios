import Foundation

// MARK: - Protocols
protocol LotteryGame {
    var mainNumberRange: ClosedRange<Int> { get }
    var specialBallRange: ClosedRange<Int> { get }
    var specialBallName: String { get }
    var apiEndpoint: String { get }
    var specialBallKey: String { get }
}

// MARK: - Enums
enum LotteryType: String {
    case megaMillions = "mega-millions"
    case powerball = "powerball"
}

extension LotteryType: LotteryGame {
    var mainNumberRange: ClosedRange<Int> {
        switch self {
        case .megaMillions: return 1...70
        case .powerball: return 1...69
        }
    }
    
    var specialBallRange: ClosedRange<Int> {
        switch self {
        case .megaMillions: return 1...25
        case .powerball: return 1...26
        }
    }
    
    var specialBallName: String {
        switch self {
        case .megaMillions: return "Mega Ball"
        case .powerball: return "Powerball"
        }
    }
    
    var apiEndpoint: String {
        rawValue
    }
    
    var specialBallKey: String {
        switch self {
        case .megaMillions: return "mega_ball"
        case .powerball: return "powerball"
        }
    }
}

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
    let message: String?
}

typealias FrequencyResponse = APIResponse<FrequencyData>
typealias CombinationResponse = APIResponse<CombinationData>
typealias LatestNumbersResponse = APIResponse<LatestNumbersData>

struct FrequencyData: Codable {
    let frequencies: [String: Double]?
    let positionFrequencies: [String: [String: Double]]?
    let megaBallFrequencies: [String: Double]?
    let powerballFrequencies: [String: Double]?
    
    enum CodingKeys: String, CodingKey {
        case frequencies
        case positionFrequencies = "position_frequencies"
        case megaBallFrequencies = "megaball_frequencies"
        case powerballFrequencies = "powerball_frequencies"
    }
}

struct CombinationData: Codable {
    let exists: Bool
    let frequency: Int?
    let dates: [String]?
    let mainNumbers: [Int]
    let specialBall: Int
    let attemptsNeeded: Int?
    
    enum CodingKeys: String, CodingKey {
        case exists
        case frequency
        case dates
        case mainNumbers = "main_numbers"
        case megaBall = "mega_ball"
        case powerball
        case attemptsNeeded = "attempts_needed"
    }
    
    init(exists: Bool, frequency: Int?, dates: [String]?, mainNumbers: [Int], specialBall: Int, attemptsNeeded: Int? = nil) {
        self.exists = exists
        self.frequency = frequency
        self.dates = dates
        self.mainNumbers = mainNumbers
        self.specialBall = specialBall
        self.attemptsNeeded = attemptsNeeded
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exists = try container.decodeIfPresent(Bool.self, forKey: .exists) ?? false
        frequency = try container.decodeIfPresent(Int.self, forKey: .frequency)
        dates = try container.decodeIfPresent([String].self, forKey: .dates)
        mainNumbers = try container.decode([Int].self, forKey: .mainNumbers)
        attemptsNeeded = try container.decodeIfPresent(Int.self, forKey: .attemptsNeeded)
        
        // Try to decode either mega_ball or powerball
        if let megaBall = try? container.decode(Int.self, forKey: .megaBall) {
            specialBall = megaBall
        } else if let powerball = try? container.decode(Int.self, forKey: .powerball) {
            specialBall = powerball
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .megaBall,
                in: container,
                debugDescription: "Neither mega_ball nor powerball found"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exists, forKey: .exists)
        try container.encodeIfPresent(frequency, forKey: .frequency)
        try container.encodeIfPresent(dates, forKey: .dates)
        try container.encode(mainNumbers, forKey: .mainNumbers)
        try container.encodeIfPresent(attemptsNeeded, forKey: .attemptsNeeded)
        // Encode based on the type
        try container.encode(specialBall, forKey: .megaBall)
    }
}

struct LatestNumbersData: Codable {
    let latestNumbers: [DrawResult]
    
    enum CodingKeys: String, CodingKey {
        case latestNumbers = "latest_numbers"
    }
}

struct DrawResult: Codable, Identifiable {
    let id: String
    let drawDate: String
    let mainNumbers: [Int]
    let specialBall: Int
    let multiplier: Int
    
    enum CodingKeys: String, CodingKey {
        case drawDate = "draw_date"
        case mainNumbers = "main_numbers"
        case megaBall = "mega_ball"
        case powerball
        case multiplier
    }
    
    init(drawDate: String, mainNumbers: [Int], specialBall: Int, multiplier: Int) {
        self.drawDate = drawDate
        self.mainNumbers = mainNumbers
        self.specialBall = specialBall
        self.multiplier = multiplier
        self.id = drawDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        drawDate = try container.decode(String.self, forKey: .drawDate)
        mainNumbers = try container.decode([Int].self, forKey: .mainNumbers)
        
        // Handle multiplier as Double and convert to Int
        let multiplierDouble = try container.decode(Double.self, forKey: .multiplier)
        multiplier = Int(multiplierDouble)
        
        // Try to decode either mega_ball or powerball
        if let megaBall = try? container.decode(Int.self, forKey: .megaBall) {
            specialBall = megaBall
        } else if let powerball = try? container.decode(Int.self, forKey: .powerball) {
            specialBall = powerball
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .megaBall,
                in: container,
                debugDescription: "Neither mega_ball nor powerball found"
            )
        }
        
        id = drawDate
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(drawDate, forKey: .drawDate)
        try container.encode(mainNumbers, forKey: .mainNumbers)
        try container.encode(Double(multiplier), forKey: .multiplier)
        // Always encode as mega_ball for consistency
        try container.encode(specialBall, forKey: .megaBall)
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

// MARK: - Error Models
struct ErrorResponse: Codable {
    let success: Bool
    let message: String?
} 
