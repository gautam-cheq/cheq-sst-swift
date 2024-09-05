import XCTest
@testable import Cheq

final class DataLayerTests: XCTestCase {
    
    override class func setUp() {
        DataLayer.clear()
    }
    
    func testAdd() {
        DataLayer.add(key: "hello", value: "world")
        XCTAssertEqual("world", DataLayer.get("hello") as! String)
    }
    
    func testAll() {
        DataLayer.add(key: "a", value: "1")
        DataLayer.add(key: "b", value: "2")
        DataLayer.add(key: "c", value: "3")
        let data = DataLayer.all()
        XCTAssertEqual("1", data["a"] as! String)
        XCTAssertEqual("2", data["b"] as! String)
        XCTAssertEqual("3", data["c"] as! String)
    }
    
    func testClear() {
        DataLayer.add(key: "hello", value: "world")
        XCTAssertEqual("world", DataLayer.get("hello") as! String)
        DataLayer.add(key: "foo", value: "bar")
        XCTAssertEqual("bar", DataLayer.get("foo") as! String)
        DataLayer.clear()
        XCTAssertFalse(DataLayer.contains("hello"))
        XCTAssertFalse(DataLayer.contains("foo"))
    }
    
    func testGet() {
        DataLayer.add(key: "rect", value: Rectangle(size: Float.infinity, color: Color.green, solid: true))
        DataLayer.add(key: "rect2", value: Rectangle(size: 100, color: Color.blue, solid: false))
        let rect = DataLayer.get("rect") as! [String: Any]
        let rectColor = rect["color"] as! [String: Any]
        XCTAssertTrue(rectColor.keys.contains("green"))
        XCTAssertEqual("Infinity", rect["size"] as! String)
        XCTAssertTrue(rect["solid"] as! Bool)
        let rect2 = DataLayer.get("rect2") as! [String: Any]
        let rect2Color = rect2["color"] as! [String: Any]
        XCTAssertTrue(rect2Color.keys.contains("blue"))
        XCTAssertEqual(100, rect2["size"] as! Int)
        XCTAssertFalse(rect2["solid"] as! Bool)
    }
    
    func testRemove() {
        DataLayer.add(key: "a", value: "b")
        XCTAssertTrue(DataLayer.contains("a"))
        XCTAssertTrue(DataLayer.remove("a"))
        XCTAssertFalse(DataLayer.contains("a"))
        XCTAssertFalse(DataLayer.remove("a"))
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
