import Foundation

struct LotteryGenerationResponse: Codable, Equatable {
    let main_numbers: [Int]
    let special_ball: Int
    let position_percentages: [String: Double]?
    let is_unique: Bool
    
    // Custom Equatable implementation since Dictionary is not automatically Equatable
    static func == (lhs: LotteryGenerationResponse, rhs: LotteryGenerationResponse) -> Bool {
        lhs.main_numbers == rhs.main_numbers &&
        lhs.special_ball == rhs.special_ball &&
        lhs.is_unique == rhs.is_unique &&
        lhs.position_percentages?.keys.sorted() == rhs.position_percentages?.keys.sorted() &&
        (lhs.position_percentages == nil && rhs.position_percentages == nil ||
         lhs.position_percentages?.values.sorted() == rhs.position_percentages?.values.sorted())
    }
} 