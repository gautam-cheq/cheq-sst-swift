import XCTest
@testable import Cheq

final class DataLayerTests: XCTestCase {
    
    func testAdd() {
        let dataLayer = DataLayer()
        dataLayer.add(key: "hello", value: "world")
        XCTAssertEqual("world", dataLayer.get("hello") as! String)
    }
    
    func testAll() {
        let dataLayer = DataLayer()
        dataLayer.add(key: "a", value: "1")
        dataLayer.add(key: "b", value: "2")
        dataLayer.add(key: "c", value: "3")
        let data = dataLayer.all()
        XCTAssertEqual("1", data["a"] as! String)
        XCTAssertEqual("2", data["b"] as! String)
        XCTAssertEqual("3", data["c"] as! String)
    }
    
    func testClear() {
        let dataLayer = DataLayer()
        dataLayer.add(key: "hello", value: "world")
        XCTAssertEqual("world", dataLayer.get("hello") as! String)
        dataLayer.add(key: "foo", value: "bar")
        XCTAssertEqual("bar", dataLayer.get("foo") as! String)
        dataLayer.clear()
        XCTAssertFalse(dataLayer.contains("hello"))
        XCTAssertFalse(dataLayer.contains("foo"))
    }
    
    func testGet() {
        let dataLayer = DataLayer()
        dataLayer.add(key: "rect", value: Rectangle(size: Float.infinity, color: Color.green, solid: true))
        dataLayer.add(key: "rect2", value: Rectangle(size: 100, color: Color.blue, solid: false))
        let rect = dataLayer.get("rect") as! [String: Any]
        let rectColor = rect["color"] as! [String: Any]
        XCTAssertTrue(rectColor.keys.contains("green"))
        XCTAssertEqual("Infinity", rect["size"] as! String)
        XCTAssertTrue(rect["solid"] as! Bool)
        let rect2 = dataLayer.get("rect2") as! [String: Any]
        let rect2Color = rect2["color"] as! [String: Any]
        XCTAssertTrue(rect2Color.keys.contains("blue"))
        XCTAssertEqual(100, rect2["size"] as! Int)
        XCTAssertFalse(rect2["solid"] as! Bool)
    }
    
    func testRemove() {
        let dataLayer = DataLayer()
        dataLayer.add(key: "a", value: "b")
        XCTAssertTrue(dataLayer.contains("a"))
        XCTAssertTrue(dataLayer.remove("a"))
        XCTAssertFalse(dataLayer.contains("a"))
        XCTAssertFalse(dataLayer.remove("a"))
    }
    
    struct Rectangle: Codable {
        let size: Float
        let color: Color
        let solid: Bool
    }

    enum Color: Codable {
        case blue, green, red
    }
}
