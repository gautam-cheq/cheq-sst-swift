import Foundation


/// Models that provide data for SST events, base models include app, device and library
public struct Models {
    private var baseModelSet: ModelSet = try! ModelSet(AppModel(), DeviceModel(), LibraryModel())
    private var customModelSet: ModelSet = try! ModelSet()
    
    
    /// initialize Models with custom models
    /// - Parameter customModels: custom models to include in every event
    /// - Throws: `SstError.invalidModelKey` if any model keys are invalid, `SstError.duplicateModelKey` if any model keys are duplicates
    public init(_ customModels: Model...) throws {
        for model in customModels {
            try self.add(model)
        }
    }
    
    
    /// get a model for the given type
    /// - Parameter clazz: model class
    /// - Returns: model if present
    public func get<T: Model>(_ clazz: T.Type) -> T? {
        return baseModelSet.get(clazz) ?? customModelSet.get(clazz)
    }
    
    
    /// returns all models
    /// - Returns: all model
    public func getAll() -> [Model] {
        return baseModelSet.getAll() + customModelSet.getAll()
    }
    
    
    public static func +=<T: Model>(lhs: inout Models, rhs: T) throws {
        try lhs.add(rhs)
    }
    
    
    /// adds the provided model
    /// - Parameter model: model to add
    /// - Throws: `SstError.invalidModelKey` if model key is invalid, `SstError.duplicateModelKey` if model key is duplicate
    public func add<T: Model>(_ model: T) throws {
        if (model.key.isEmpty) {
            throw SstError.invalidModelKey
        }
        if baseModelSet.containsKey(model.key) || baseModelSet.containsModel(type(of: model)) {
            throw SstError.duplicateModelKey("A base model with the key '\(model.key)' already exists and cannot be overridden")
        }
        try customModelSet.add(model)
    }
    
    
    /// remove model for the given type
    /// - Parameter clazz: model class
    public func remove<T: Model>(_ clazz: T.Type) {
        customModelSet.remove(clazz)
    }
    
    public static func -=<T: Model>(lhs: inout Models, rhs: T.Type) {
        lhs.remove(rhs)
    }
    
    func collect(event: Event, sst: Sst) async -> [String: Any] {
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
                throw SstError.duplicateModelKey("Model \(type(of: existingModel)) already exists with key \(model.key).")
            }
            if let existingModel = models[ObjectIdentifier(type(of: model))] {
                throw SstError.duplicateModelKey("Model \(type(of: existingModel)) already exists. Cannot add duplicate model class.")
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


/// Base model class, extend with custom logic
open class Model {
    
    public init() {}
    
    /// model key, must be overriden
    open var key: String {
        get {
            fatalError("This property must be overridden")
        }
    }
    
    
    /// model version, default `1.0.0`
    open var version: String {
        get { "1.0.0" }
    }
    
    
    /// returns data to be stored under the model ``key``
    /// - Parameters:
    ///   - event: current SST event
    ///   - sst: SST instance
    /// - Returns: custom data that will be stored under the model ``key``
    open func get(event: Event, sst: Sst) async -> Any {
        fatalError("This method must be overridden")
    }
}

class AppModel: Model {
    override var key: String {
        get { "app" }
    }
    
    override func get(event: Event, sst: Sst) async -> Any {
        return Info.appInfo
    }
}

class DeviceModel: Model {
    override var key: String {
        get { "device" }
    }
    
    override func get(event: Event, sst: Sst) async -> Any {
        return Info.gatherDeviceData()
    }
}

class LibraryModel: Model {
    override var key: String {
        get { "library" }
    }
    
    override func get(event: Event, sst: Sst) async -> Any {
        return [
            "name": Info.library_name,
            "version": Info.library_version,
            "models": sst.config.models.info()
        ]
    }
}
