import XCTest
@testable import Cheq

final class ModelsTests: XCTestCase {
    func testModels() async throws {
        let foo = Foo()
        let models = try Models(foo)
        XCTAssertEqual(models.getAll().count, 4, "invalid model count")
        let fooModel = models.get(Foo.self)
        XCTAssertTrue(foo === fooModel!, "invalid instance of model")
        XCTAssertNil(models.get(Model.self))
    }
    
    func testCollect() async throws {
        let models = try Models(Foo())
        await SST.configure(SSTConfig(client: "ModelsTest"))
        let result = await models.collect(event: TrackEvent(name: "test"), sst: SST.getInstance())
        XCTAssertNotNil(result["foo"])
        XCTAssertNotNil(result["app"])
        XCTAssertNotNil(result["device"])
        if let foo = result["foo"] as? [String: Any] {
            XCTAssertNotNil(foo["date"])
            XCTAssertNotNil(foo["int"])
        } else {
            XCTFail("invalid result for model foo")
        }
    }
    
    func testDuplicateModelError() {
        do {
            let _ = try Models(Foo(), Foo())
            XCTFail("exception not thrown")
        } catch(SSTError.duplicateModelKey(let message)) {
            XCTAssertEqual(message, "Model Foo already exists with key foo.", "invalid exception message")
        } catch {
            XCTFail("invalid exception")
        }
    }
    
    func testDuplicateModelDifferentKeys() {
        do {
            let _ = try Models(SubModel(key: "sub"), SubModel(key: "sub2"))
            XCTFail("exception not thrown")
        } catch(SSTError.duplicateModelKey(let message)) {
            XCTAssertEqual(message, "Model SubModel already exists. Cannot add duplicate model class.")
        } catch {
            XCTFail("invalid exception")
        }
    }
    
    class Foo: Model {
        override var key: String { "foo" }
        override func get(event: TrackEvent, sst: SST) async -> Any {
            return ["date": Date(), "int": Int.random(in: 1...100)]
        }
    }
    
    class SubModel: Model {
        private var _key: String
        
        init(key: String) {
            self._key = key
            super.init()
        }
        
        override var key: String {
            get {
                return _key
            }
            set {
                _key = newValue
            }
        }
    }
}
