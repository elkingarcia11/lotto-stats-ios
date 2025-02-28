import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse(Int)
    case decodingError(String)
    case serverError(String)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse(let statusCode):
            return "Invalid response from server (Status: \(statusCode))"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .noData:
            return "No data received from server"
        }
    }
}

struct NetworkConfiguration {
    let baseURL: String
    let debug: Bool
    
    static let development = NetworkConfiguration(
        baseURL: "http://192.168.1.242:8000",
        debug: true
    )
    
    static let production = NetworkConfiguration(
        baseURL: "http://192.168.1.242:8000", // Replace with production URL
        debug: false
    )
}

protocol NetworkServiceProtocol {
    func performRequest<T: Decodable>(endpoint: String, method: String, body: [String: Any]?) async throws -> T
    func checkCombination(numbers: [Int], specialBall: Int, type: LotteryType) async throws -> CombinationResponse
    func fetchLatestNumbers(for type: LotteryType, limit: Int?) async throws -> LatestNumbersResponse
    func fetchFrequencies(for type: LotteryType) async throws -> FrequencyResponse
    func fetchPositionFrequencies(for type: LotteryType) async throws -> FrequencyResponse
    func fetchSpecialBallFrequencies(for type: LotteryType) async throws -> FrequencyResponse
    func generateCombination(for type: LotteryType) async throws -> CombinationResponse
}

class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService(configuration: .development)
    
    private let configuration: NetworkConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(configuration: NetworkConfiguration, 
         session: URLSession = .shared, 
         decoder: JSONDecoder = JSONDecoder()) {
        self.configuration = configuration
        self.session = session
        self.decoder = decoder
    }
    
    func performRequest<T: Decodable>(endpoint: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: "\(configuration.baseURL)/\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await session.data(for: request)
        
        if configuration.debug {
            debugPrint(request: request, data: data)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(-1)
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message ?? "Unknown server error")
            }
            throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            let context = decodingErrorContext(error)
            throw NetworkError.decodingError(context)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
    
    private func debugPrint(request: URLRequest, data: Data) {
        print("Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Request Body: \(bodyString)")
        }
        
        print("Raw Response Data:")
        if let responseString = String(data: data, encoding: .utf8) {
            print(responseString)
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("\nFormatted JSON Response:")
                print(prettyString)
            }
        }
    }
    
    private func decodingErrorContext(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' - path: \(context.codingPath.map { $0.stringValue })"
        case .valueNotFound(let type, let context):
            return "Missing value of type '\(type)' - path: \(context.codingPath.map { $0.stringValue })"
        case .typeMismatch(let type, let context):
            return "Type mismatch for type '\(type)' - path: \(context.codingPath.map { $0.stringValue })"
        case .dataCorrupted(let context):
            return context.debugDescription
        @unknown default:
            return error.localizedDescription
        }
    }
    
    func checkCombination(numbers: [Int], specialBall: Int, type: LotteryType) async throws -> CombinationResponse {
        let body: [String: Any] = [
            "numbers": numbers,
            "special_ball": specialBall
        ]
        
        return try await performRequest(
            endpoint: "\(type.rawValue)/check",
            method: "POST",
            body: body
        )
    }
    
    func fetchLatestNumbers(for type: LotteryType, limit: Int? = nil) async throws -> LatestNumbersResponse {
        var endpoint = "\(type.rawValue)/latest"
        if let limit = limit {
            endpoint += "?limit=\(limit)"
        }
        return try await performRequest(endpoint: endpoint)
    }
    
    func fetchFrequencies(for type: LotteryType) async throws -> FrequencyResponse {
        return try await performRequest(endpoint: "\(type.rawValue)/frequencies")
    }
    
    func fetchPositionFrequencies(for type: LotteryType) async throws -> FrequencyResponse {
        return try await performRequest(endpoint: "\(type.rawValue)/position-frequencies")
    }
    
    func fetchSpecialBallFrequencies(for type: LotteryType) async throws -> FrequencyResponse {
        let endpoint = type == .megaMillions ? "mega-millions/megaball-frequencies" : "powerball/powerball-frequencies"
        return try await performRequest(endpoint: endpoint)
    }
    
    func generateCombination(for type: LotteryType) async throws -> CombinationResponse {
        return try await performRequest(endpoint: "\(type.rawValue)/generate-combination")
    }
} 
