import Foundation

public class Models {
    private var baseModelSet: ModelSet = try! ModelSet(AppModel(), DeviceModel(), LibraryModel())
    private var customModelSet: ModelSet = try! ModelSet()
    
    public init(_ customModels: Model...) throws {
        for model in customModels {
            try self.add(model)
        }
    }
    
    func get<T: Model>(_ clazz: T.Type) -> T? {
        return baseModelSet.get(clazz) ?? customModelSet.get(clazz)
    }
    
    func getAll() -> [Model] {
        return baseModelSet.getAll() + customModelSet.getAll()
    }
    
    static func +=<T: Model>(lhs: inout Models, rhs: T) throws {
        try lhs.add(rhs)
    }
    
    func add<T: Model>(_ model: T) throws {
        if (model.key.isEmpty) {
            throw SSTError.invalidModelKey
        }
        if baseModelSet.containsKey(model.key) || baseModelSet.containsModel(type(of: model)) {
            throw SSTError.duplicateModelKey("A base model with the key '\(model.key)' already exists and cannot be overridden")
        }
        try customModelSet.add(model)
    }
    
    func remove<T: Model>(_ clazz: T.Type) {
        customModelSet.remove(clazz)
    }
    
    static func -=<T: Model>(lhs: inout Models, rhs: T.Type) {
        lhs.remove(rhs)
    }
    
    func collect(event: TrackEvent, sst: SST) async -> [String: Any] {
        var result: [String: Any] = [:]
        for model in getAll() {
            result[model.key] = await model.get(event: event, sst: sst)
        }
        return result
    }
    
    func info() -> [String: String] {
        var result: [String: String] = [:]
        for model in customModelSet.getAll() {
            result[model.key] = model.version
        }
        return result
    }
    
    private class ModelSet {
        private var keyedModels: [String: Model] = [:]
        private var models: [ObjectIdentifier: Model] = [:]
        
        init(_ models: Model...) throws {
            for model in models {
                try add(model)
            }
        }
        
        func get<T: Model>(_ clazz: T.Type) -> T? {
            let model = models[ObjectIdentifier(clazz)]
            return model as? T
        }
        
        func getAll() -> [Model] {
            return Array(models.values)
        }
        
        func add<T: Model>(_ model: T) throws {
            if let existingModel = keyedModels[model.key] {
                throw SSTError.duplicateModelKey("Model \(type(of: existingModel)) already exists with key \(model.key).")
            }
            if let existingModel = models[ObjectIdentifier(type(of: model))] {
                throw SSTError.duplicateModelKey("Model \(type(of: existingModel)) already exists. Cannot add duplicate model class.")
            }
            keyedModels[model.key] = model
            models[ObjectIdentifier(type(of: model))] = model
        }
        
        func remove<T: Model>(_ clazz: T.Type) {
            if let model = models.removeValue(forKey: ObjectIdentifier(clazz)) {
                keyedModels.removeValue(forKey: model.key)
            }
        }
        
        func containsKey(_ key: String) -> Bool {
            return keyedModels.keys.contains(key)
        }
        
        func containsModel<T: Model>(_ clazz: T.Type) -> Bool {
            return models.keys.contains(ObjectIdentifier(clazz))
        }
    }
}

open class Model {
    
    public init() {}
    
    open var key: String {
        get {
            fatalError("This property must be overridden")
        }
    }
    
    open var version: String {
        get { "0.1" }
    }
    
    open func get(event: TrackEvent, sst: SST) async -> Any {
        fatalError("This method must be overridden")
    }
}

class AppModel: Model {
    override var key: String {
        get { "app" }
    }
    
    override func get(event: TrackEvent, sst: SST) async -> Any {
        return Info.appInfo
    }
}

class DeviceModel: Model {
    override var key: String {
        get { "device" }
    }
    
    override func get(event: TrackEvent, sst: SST) async -> Any {
        return Info.gatherDeviceData()
    }
}

class LibraryModel: Model {
    override var key: String {
        get { "library" }
    }
    
    override func get(event: TrackEvent, sst: SST) async -> Any {
        return [
            "name": "ios-swift",
            "version": "0.1",
            "models": sst.config.models.info()
        ]
    }
}
