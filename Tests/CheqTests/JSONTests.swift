import XCTest
@testable import Cheq

final class JSONTests: XCTestCase {
    func testconvertToJSONString() throws {
        
        let model = Model(empty_dict: [:],
                          empty_array: [],
                          str: "test",
                          int: 1337,
                          float: 1.337,
                          dict: [
                              "dict_str": "hello",
                              "dict_dict": ["a":"b", "c": 4]
                          ],
                          nillable: nil,
                          nsnull: NSNull(),
                          date: Date(timeIntervalSince1970: 1337.123));
        let data: [String: Any] = ["hello":"world", "model": model]
        let result = try JSON.convertToJSONString(data)
        checkJSON(result)
        
        if let jsonData = result.data(using: .utf8) {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    let result2 = try JSON.convertToJSONString(jsonObject)
                    checkJSON(result2)
                }
            } catch {
                XCTFail("Failed to decode JSON: \(error.localizedDescription)")
            }
        }
    }
    
    func checkJSON(_ result: String) {
        XCTAssert(result.contains("\"hello\":\"world\""), "invalid hello")
        XCTAssert(result.contains("\"empty_dict\":{}"), "invalid empty_dict")
        XCTAssert(result.contains("\"empty_array\":[]"), "invalid empty_array")
        XCTAssert(result.contains("\"str\":\"test\""), "invalid str")
        XCTAssert(result.contains("\"int\":1337"), "invalid int")
        XCTAssert(result.contains("\"float\":1.33"), "invalid float")
        XCTAssert(result.contains("\"nillable\":null"), "invalid nillable")
        XCTAssert(result.contains("\"nsnull\":null"), "invalid nsnull")
        XCTAssert(result.contains("\"date\":\"1970-01-01T00:22:17.123Z\""), "invalid date")
        XCTAssert(result.contains("\"dict_str\":\"hello\""), "invalid dict_str")
        XCTAssert(result.contains("\"dict_dict\":{"), "invalid dict_dict")
        XCTAssert(result.contains("\"a\":\"b\""), "invalid dict_dict_a")
        XCTAssert(result.contains("\"c\":4"), "invalid dict_dict_c")
    }
    
    struct Model {
        let empty_dict: [String: Any]
        let empty_array: [Any]
        let str: String
        let int: Int
        let float: Float
        let dict: [String: Any]
        let nillable: Any?
        let nsnull: NSNull
        let date: Date
    }
}
