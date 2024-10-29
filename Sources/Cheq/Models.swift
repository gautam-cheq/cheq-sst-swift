import Foundation


/// Models that provide data for SST events, base models include app, device and library
public struct Models {
    private static var baseModels = try! ModelSet([AppModel(), DeviceModel.default(), LibraryModel()])
    private var modelSet: ModelSet
    
    /// Includes the app and library models, they cannot be overridden
    public static func required() throws -> Models {
        return try! Models(baseModels.getAll().filter {
            $0.modelType == .REQUIRED
        })
    }
    
    /// Includes the app, device and library models, they cannot be overridden
    public static func `default`() throws -> Models {
        return try! Models(baseModels.getAll())
    }
    
    private init(_ models: [Model]) throws {
        self.modelSet = try! ModelSet(models)
    }
    
    
    /// get a model for the given type
    /// - Parameter clazz: model class
    /// - Returns: model if present
    public func get<T: Model>(_ clazz: T.Type) -> T? {
        return modelSet.get(clazz)
    }
    
    
    /// returns all models
    /// - Returns: all model
    public func getAll() -> [Model] {
        return modelSet.getAll()
    }
    
    
    public static func +=<T: Model>(lhs: inout Models, rhs: T) throws {
        let _ = try lhs.add(rhs)
    }
    
    
    /// adds the provided model
    /// - Parameter model: model to add
    /// - Throws: `SstError.invalidModelKey` if model key is invalid, `SstError.duplicateModelKey` if model key is duplicate
    public func add<T: Model>(_ models: T...) throws -> Models {
        for model in models {
            if (model.key.isEmpty) {
                throw SstError.invalidModelKey
            }
            let modelType = type(of: model)
            if modelSet.containsKey(model.key) || modelSet.containsModel(modelType) {
                throw SstError.duplicateModelKey("A model with the key '\(model.key)' or type '\(modelType)' already exists and cannot be overridden")
            }
            if Models.baseModels.containsKey(model.key) && !Models.baseModels.containsModel(modelType) {
                throw SstError.duplicateModelKey("A base model with the key '\(model.key)' cannot be overridden")
            }
            try! modelSet.add(model)
        }
        return self
    }
    
    
    /// remove model for the given type
    /// - Parameter clazz: model class
    public func remove<T: Model>(_ clazz: T.Type) {
        modelSet.remove(clazz)
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
        return modelSet.getAll()
            .filter { $0.modelType != .REQUIRED }
            .reduce(into: [:]) { result, model in
                result[model.key] = model.version
            }
    }
    
    private class ModelSet {
        private var keyedModels: [String: Model] = [:]
        private var models: [ObjectIdentifier: Model] = [:]
        
        init(_ models: [Model]) throws {
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
    
    internal var modelType:ModelType {
        get { .STANDARD }
    }
    
}

enum ModelType {
    case STANDARD
    case DEFAULT
    case REQUIRED
}

class AppModel: Model {
    override var modelType: ModelType {
        get { .REQUIRED }
    }
    
    override var key: String {
        get { "app" }
    }
    
    override func get(event: Event, sst: Sst) async -> Any {
        return Info.appInfo
    }
    
}

/// Device Model Configuration, all properties are enabled by default
public class DeviceModelConfig {
    var screenEnabled: Bool = true
    var osEnabled: Bool = true
    var idEnabled: Bool = true
    
    /// Disables screen data collection
    public func disableScreen() -> DeviceModelConfig {
        self.screenEnabled = false
        return self
    }
    
    /// Disables OS data collection
    public func disableOs() -> DeviceModelConfig {
        self.osEnabled = false
        return self
    }
    
    /// Disables ID data collection
    public func disableId() -> DeviceModelConfig {
        self.idEnabled = false
        return self
    }
    
    /// Creates a new instance of the device model with the custom configuration
    public func create() -> DeviceModel {
        return DeviceModel(self)
    }
}

/// Device Model, collects and exposes device-related data
public class DeviceModel: Model {
    let config:DeviceModelConfig
    
    internal init(_ config:DeviceModelConfig) {
        self.config = config
    }
    
    /// Creates an instance of the ``DeviceModel`` with the default configuration
    public static func `default`() -> DeviceModel {
        return DeviceModel(DeviceModelConfig())
    }
    
    /// Creates an instance of the ``DeviceModelConfig`` for custom configuration
    public static func custom() -> DeviceModelConfig {
        return DeviceModelConfig()
    }
    
    override var modelType: ModelType {
        get { .DEFAULT }
    }
    
    override public var key: String {
        get { "device" }
    }
    
    override public func get(event: Event, sst: Sst) async -> Any {
        return Info.gatherDeviceData(config)
    }
}

class LibraryModel: Model {
    
    override var modelType: ModelType {
        get { .REQUIRED }
    }
    
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
