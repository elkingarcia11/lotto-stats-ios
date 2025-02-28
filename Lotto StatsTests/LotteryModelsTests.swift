import XCTest
@testable import Lotto_Stats

final class LotteryModelsTests: XCTestCase {
    
    func testMegaMillionsDecoding() throws {
        // Sample Mega Millions JSON response
        let jsonString = """
        {
            "success": true,
            "message": null,
            "data": {
                "latest_numbers": [
                    {
                        "draw_date": "2025-02-25",
                        "main_numbers": [4, 8, 11, 32, 52],
                        "mega_ball": 13,
                        "multiplier": 2.0
                    },
                    {
                        "draw_date": "2025-02-21",
                        "main_numbers": [1, 13, 28, 37, 46],
                        "mega_ball": 10,
                        "multiplier": 2.0
                    }
                ]
            }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        print("Raw JSON:", String(data: jsonData, encoding: .utf8) ?? "")
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(LatestNumbersResponse.self, from: jsonData)
            print("Successfully decoded response")
            
            XCTAssertTrue(response.success)
            XCTAssertEqual(response.data.latestNumbers.count, 2)
            
            let firstDraw = response.data.latestNumbers[0]
            XCTAssertEqual(firstDraw.drawDate, "2025-02-25")
            XCTAssertEqual(firstDraw.mainNumbers, [4, 8, 11, 32, 52])
            XCTAssertEqual(firstDraw.specialBall, 13)
            XCTAssertEqual(firstDraw.multiplier, 2)
        } catch let DecodingError.keyNotFound(key, context) {
            XCTFail("Missing key '\(key.stringValue)' - \(context.debugDescription)")
            print("Coding path:", context.codingPath.map { $0.stringValue })
        } catch let DecodingError.valueNotFound(type, context) {
            XCTFail("Missing value of type '\(type)' - \(context.debugDescription)")
            print("Coding path:", context.codingPath.map { $0.stringValue })
        } catch let DecodingError.typeMismatch(type, context) {
            XCTFail("Type mismatch for type '\(type)' - \(context.debugDescription)")
            print("Coding path:", context.codingPath.map { $0.stringValue })
        } catch {
            XCTFail("Decoding error: \(error)")
        }
    }
    
    func testPowerballDecoding() throws {
        // Sample Powerball JSON response
        let jsonString = """
        {
            "success": true,
            "message": null,
            "data": {
                "latest_numbers": [
                    {
                        "draw_date": "2025-02-26",
                        "main_numbers": [28, 48, 55, 60, 62],
                        "powerball": 20,
                        "multiplier": 2.0
                    },
                    {
                        "draw_date": "2025-02-24",
                        "main_numbers": [10, 11, 34, 59, 68],
                        "powerball": 14,
                        "multiplier": 3.0
                    }
                ]
            }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(LatestNumbersResponse.self, from: jsonData)
        
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.latestNumbers.count, 2)
        
        let firstDraw = response.data.latestNumbers[0]
        XCTAssertEqual(firstDraw.drawDate, "2025-02-26")
        XCTAssertEqual(firstDraw.mainNumbers, [28, 48, 55, 60, 62])
        XCTAssertEqual(firstDraw.specialBall, 20)
        XCTAssertEqual(firstDraw.multiplier, 2)
    }
    
    func testCombinationDataDecoding() throws {
        // Test Mega Millions combination
        let megaMillionsJSON = """
        {
            "exists": true,
            "frequency": 2,
            "dates": ["2025-01-01", "2024-12-25"],
            "main_numbers": [1, 2, 3, 4, 5],
            "mega_ball": 10
        }
        """
        
        let megaMillionsData = megaMillionsJSON.data(using: .utf8)!
        let megaMillionsCombination = try JSONDecoder().decode(CombinationData.self, from: megaMillionsData)
        
        XCTAssertTrue(megaMillionsCombination.exists)
        XCTAssertEqual(megaMillionsCombination.frequency, 2)
        XCTAssertEqual(megaMillionsCombination.dates, ["2025-01-01", "2024-12-25"])
        XCTAssertEqual(megaMillionsCombination.mainNumbers, [1, 2, 3, 4, 5])
        XCTAssertEqual(megaMillionsCombination.specialBall, 10)
        
        // Test Powerball combination
        let powerballJSON = """
        {
            "exists": true,
            "frequency": 1,
            "dates": ["2025-02-01"],
            "main_numbers": [10, 20, 30, 40, 50],
            "powerball": 15
        }
        """
        
        let powerballData = powerballJSON.data(using: .utf8)!
        let powerballCombination = try JSONDecoder().decode(CombinationData.self, from: powerballData)
        
        XCTAssertTrue(powerballCombination.exists)
        XCTAssertEqual(powerballCombination.frequency, 1)
        XCTAssertEqual(powerballCombination.dates, ["2025-02-01"])
        XCTAssertEqual(powerballCombination.mainNumbers, [10, 20, 30, 40, 50])
        XCTAssertEqual(powerballCombination.specialBall, 15)
    }
} 
