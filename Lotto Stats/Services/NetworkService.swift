import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(String)
}

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://192.168.1.242:8000" // Replace with your actual API base URL
    
    private init() {}
    
    func fetchFrequencies(for type: LotteryType) async throws -> FrequencyResponse {
        let url = baseURL + type.baseURL + "/frequencies"
        return try await performRequest(url: url)
    }
    
    func fetchPositionFrequencies(for type: LotteryType) async throws -> FrequencyResponse {
        let url = baseURL + type.baseURL + "/position-frequencies"
        return try await performRequest(url: url)
    }
    
    func fetchSpecialBallFrequencies(for type: LotteryType) async throws -> FrequencyResponse {
        let endpoint = type == .megaMillions ? "/megaball-frequencies" : "/powerball-frequencies"
        let url = baseURL + type.baseURL + endpoint
        return try await performRequest(url: url)
    }
    
    func checkCombination(type: LotteryType, numbers: [Int], specialBall: Int) async throws -> CombinationResponse {
        let url = baseURL + type.baseURL + "/check-combination"
        
        let body = [
            "main_numbers": numbers,
            type == .megaMillions ? "megaball" : "powerball": specialBall
        ] as [String : Any]
        
        return try await performRequest(url: url, method: "POST", body: body)
    }
    
    func generateCombination(for type: LotteryType) async throws -> CombinationResponse {
        let url = baseURL + type.baseURL + "/generate-combination"
        return try await performRequest(url: url)
    }
    
    private func performRequest<T: Codable>(url urlString: String,
                                          method: String = "GET",
                                          body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
} 