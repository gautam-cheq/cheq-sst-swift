import XCTest
@testable import Cheq

final class ModelsTests: XCTestCase {
    func testModels() async throws {
        let foo = Foo()
        let models = try Models.default().add(foo)
        XCTAssertEqual(models.getAll().count, 4, "invalid model count")
        let fooModel = models.get(Foo.self)
        XCTAssertTrue(foo === fooModel!, "invalid instance of model")
        XCTAssertNil(models.get(Model.self))
    }
    
    func testCollect() async throws {
        let models = try Models.default().add(Foo())
        Sst.configure(Config("ModelsTest"))
        let result = await models.collect(event: Event("test"), sst: Sst.getInstance())
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
        XCTAssertThrowsError(try Models.required().add(Foo(), Foo())) { error in
            let sstError = error as! SstError
            switch sstError {
            case .duplicateModelKey(let message):
                XCTAssertEqual(message, "A model with the key 'foo' or type 'Foo' already exists and cannot be overridden")
            default:
                XCTFail("Unexpected sstError: \(sstError)")
            }
        }
    }
    
    func testDuplicateModelDifferentKeys() {
        XCTAssertThrowsError(try Models.default().add(SubModel(key: "sub"), SubModel(key: "sub2"))) { error in
            let sstError = error as! SstError
            switch sstError {
            case .duplicateModelKey(let message):
                XCTAssertEqual(message, "A model with the key 'sub2' or type 'SubModel' already exists and cannot be overridden")
            default:
                XCTFail("Unexpected sstError: \(sstError)")
            }
        }
    }
    
    func testAddAndRemove() {
        var models = try! Models.default().add(SubModel(key: "sub"))
        XCTAssertThrowsError(try models += SubModel(key: "sub2")) { error in
            let sstError = error as! SstError
            switch sstError {
            case .duplicateModelKey(let message):
                XCTAssertEqual(message, "A model with the key 'sub2' or type 'SubModel' already exists and cannot be overridden")
            default:
                XCTFail("Unexpected sstError: \(sstError)")
            }
        }
        models -= SubModel.self
        XCTAssertNil(models.get(SubModel.self))
        
    }
    
    func testErrorInitializingModels() throws {
        XCTAssertThrowsError(try Models.default().add(SubModel(key: ""))) { error in
            let sstError = error as! SstError
            XCTAssertEqual(SstError.invalidModelKey, sstError)
        }
        
        XCTAssertThrowsError(try Models.required().add(SubModel(key: "library"))) { error in
            let sstError = error as! SstError
            switch sstError {
            case .duplicateModelKey(let message):
                XCTAssertEqual(message, "A model with the key 'library' or type 'SubModel' already exists and cannot be overridden")
            default:
                XCTFail("Unexpected sstError: \(sstError)")
            }
        }
    }
    
    func testDeviceModelIncluded() throws {
        let deviceModel = DeviceModel.custom().disableId().create()
        let models = try! Models.required().add(deviceModel)
        let info = models.info()
        XCTAssertEqual(info[deviceModel.key], deviceModel.version)
    }
    
    func testReplaceBaseModelErrors() throws {
        XCTAssertThrowsError(try Models.required().add(CustomDevice())) { error in
            let sstError = error as! SstError
            switch sstError {
            case .duplicateModelKey(let message):
                XCTAssertEqual(message, "A base model with the key 'device' cannot be overridden")
            default:
                XCTFail("Unexpected sstError: \(sstError)")
            }
        }
    }
    
    class Foo: Model {
        override var key: String { "foo" }
        override func get(event: Event, sst: Sst) async -> Any {
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
    
    class CustomDevice: Model {
        override var key: String { "device" }
        override func get(event: Event, sst: Sst) async -> Any {
            return ["id": UUID().uuidString]
        }
    }
}
