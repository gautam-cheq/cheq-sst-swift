import XCTest
@testable import Cheq

final class DataLayerTests: XCTestCase {
    let standardFooValue = "{\"value\":\"bar\"}"
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.register(defaults: ["foo" : standardFooValue])
        Sst.configure(Config("DataLayerTests"))
        Sst.dataLayer.clear()
    }
    
    func testContains() {
        XCTAssertFalse(Sst.dataLayer.contains("foo"))
    }
    
    func testAdd() {
        Sst.dataLayer.add(key: "foo", value: "bar2")
        XCTAssertEqual("bar2", Sst.dataLayer.get("foo") as! String)
        XCTAssertEqual(standardFooValue, UserDefaults.standard.string(forKey: "foo")!)
    }
    
    func testAll() {
        Sst.dataLayer.add(key: "a", value: "1")
        Sst.dataLayer.add(key: "b", value: "2")
        Sst.dataLayer.add(key: "c", value: "3")
        let data = Sst.dataLayer.all()
        XCTAssertEqual(3, data.count)
        XCTAssertEqual("1", data["a"] as! String)
        XCTAssertEqual("2", data["b"] as! String)
        XCTAssertEqual("3", data["c"] as! String)
    }
    
    func testClear() {
        Sst.dataLayer.add(key: "hello", value: "world")
        XCTAssertEqual("world", Sst.dataLayer.get("hello") as! String)
        Sst.dataLayer.add(key: "foo", value: "bar")
        XCTAssertEqual("bar", Sst.dataLayer.get("foo") as! String)
        Sst.dataLayer.clear()
        XCTAssertEqual(0, Sst.dataLayer.all().count)
        XCTAssertFalse(Sst.dataLayer.contains("hello"))
        XCTAssertFalse(Sst.dataLayer.contains("foo"))
        XCTAssertEqual(standardFooValue, UserDefaults.standard.string(forKey: "foo")!)
    }
    
    func testGet() {
        XCTAssertNil(Sst.dataLayer.get("foo"))
        Sst.dataLayer.add(key: "rect", value: Rectangle(size: Float.infinity, color: Color.green, solid: true))
        Sst.dataLayer.add(key: "rect2", value: Rectangle(size: 100, color: Color.blue, solid: false))
        let rect = Sst.dataLayer.get("rect") as! [String: Any]
        let rectColor = rect["color"] as! [String: Any]
        XCTAssertTrue(rectColor.keys.contains("green"))
        XCTAssertEqual("Infinity", rect["size"] as! String)
        XCTAssertTrue(rect["solid"] as! Bool)
        let rect2 = Sst.dataLayer.get("rect2") as! [String: Any]
        let rect2Color = rect2["color"] as! [String: Any]
        XCTAssertTrue(rect2Color.keys.contains("blue"))
        XCTAssertEqual(100, rect2["size"] as! Int)
        XCTAssertFalse(rect2["solid"] as! Bool)
    }
    
    func testRemove() {
        Sst.dataLayer.add(key: "a", value: "b")
        XCTAssertTrue(Sst.dataLayer.contains("a"))
        XCTAssertTrue(Sst.dataLayer.remove("a"))
        XCTAssertFalse(Sst.dataLayer.contains("a"))
        XCTAssertFalse(Sst.dataLayer.remove("a"))
    }
    
    func testAddError() {
        Sst.dataLayer.add(key: "invalid", value: InvalidJSON())
        XCTAssertFalse(Sst.dataLayer.contains("invalid"))
    }
    
    struct Rectangle: Codable {
        let size: Float
        let color: Color
        let solid: Bool
    }
    
    enum Color: Codable {
        case blue, green, red
    }
    
    struct InvalidJSON: Encodable {
        func encode(to encoder: Encoder) throws {
        }
    }
}
