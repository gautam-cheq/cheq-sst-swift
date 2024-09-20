import XCTest
@testable import Cheq

final class JSONTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Sst.configure(Config("JSONTests"))
    }
    
    func testconvertToJSONString() throws {
        let model = Model(empty_dict: [:],
                          empty_array: [],
                          str: "test",
                          int: 1337,
                          bool: true,
                          float: 1.337,
                          arr: ["zero", 99],
                          dict: [
                            "dict_str": "hello",
                            "dict_dict": ["a":"b", "c": 4]
                          ],
                          nillable: nil,
                          nsnull: NSNull(),
                          date: Date(timeIntervalSince1970: 1337.123),
                          data: "foo".data(using: .utf8)!,
                          color: Color.green,
                          person: Person(name: "Test User", id: 1337),
                          beverages: [Beverage.coffee(size: "Large", vol: 12), Beverage.juice(flavor: "Orange", isFresh: false)]);
        var optDict: [String: Any?] = [:]
        optDict["testOpt"] = "value"
        optDict["testArr"] = ["zz", 99]
        optDict["numbers"] = ["nan": Float.nan, "infinity": Float.infinity, "negative_infinity": Double.infinity * -1]
        optDict["inheritance"] = SubClass()
        let data: [String: Any] = ["hello":"world", "model": model, "optDict": optDict, "shape": Shape.square(length: 3, color: "blue")]
        
        let expected = "{\"hello\":\"world\",\"model\":{\"arr\":[\"zero\",99],\"beverages\":[{\"coffee\":{\"size\":\"Large\",\"vol\":12}},{\"juice\":{\"flavor\":\"Orange\",\"isFresh\":false}}],\"bool\":true,\"color\":\"green\",\"data\":\"Zm9v\",\"date\":\"1970-01-01T00:22:17.123Z\",\"dict\":{\"dict_dict\":{\"a\":\"b\",\"c\":4},\"dict_str\":\"hello\"},\"empty_array\":[],\"empty_dict\":{},\"float\":1.3370000123977661,\"int\":1337,\"nillable\":null,\"nsnull\":null,\"person\":{\"id\":1337,\"name\":\"Test User\"},\"str\":\"test\"},\"optDict\":{\"inheritance\":{\"regularProperty\":\"Regular Property\",\"subClassProperty\":33},\"numbers\":{\"infinity\":\"Infinity\",\"nan\":\"NaN\",\"negative_infinity\":\"-Infinity\"},\"testArr\":[\"zz\",99],\"testOpt\":\"value\"},\"shape\":{\"square\":{\"color\":\"blue\",\"length\":3}}}"
        
        let result = try JSON.convertToJSONString(data)
        
        XCTAssertEqual(expected, result, "invalid json")
        if let jsonData = result.data(using: .utf8) {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    let result2 = try JSON.convertToJSONString(jsonObject)
                    XCTAssertEqual(expected, result2, "invalid json after deserialize and serialize")
                }
            } catch {
                XCTFail("Failed to decode JSON: \(error)")
            }
        } else {
            XCTFail("unexpected invalid encoding")
        }
    }
    
    func testBooleans() throws {
        let expected = "{\"false\":false,\"true\":true}"
        let result = try JSON.convertToJSONString(["true": true, "false": false])
        
        XCTAssertEqual(expected, result, "invalid json")
    }
    
    func testError() {
        let foo = InvalidJSON()
        XCTAssertThrowsError(try JSON.convertToJSONString(["foo": foo])) { error in
            if let encodingError = error as? EncodingError {
                switch encodingError {
                case .invalidValue(_, let context):
                    XCTAssertEqual(context.debugDescription, "Top-level InvalidJSON did not encode any values.")
                default:
                    XCTFail("Unexpected EncodingError: \(encodingError)")
                }
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    struct InvalidJSON: Encodable {
        func encode(to encoder: Encoder) throws {
        }
    }
    
    class SuperClass {
        var regularProperty: String = "Regular Property"
    }
    
    class SubClass: SuperClass {
        var subClassProperty: Int = 33
        
        var computed: String {
            return "NOT VISIBLE VIA REFLECTION"
        }
    }
    
    struct Model {
        let empty_dict: [String: Any]
        let empty_array: [Any]
        let str: String
        let int: Int
        let bool: Bool
        let float: Float
        let arr: [Any]
        let dict: [String: Any]
        let nillable: Any?
        let nsnull: NSNull
        let date: Date
        let data: Data
        let color: Color
        let person: Person
        let beverages: [Beverage]
    }
    
    struct Person: Codable {
        let name: String
        let id: Int
    }
    
    enum Color {
        case red, green, blue
    }
    
    enum Beverage {
        case coffee(size: String, vol: Int)
        case juice(flavor: String, isFresh: Bool)
    }
    
    enum Shape : Codable {
        case square(length: Int, color: String)
    }
}
