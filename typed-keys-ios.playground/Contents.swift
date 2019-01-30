import Foundation

// MARK: - Property list storage

protocol PropertyListType {}

extension String        : PropertyListType {}
extension Int           : PropertyListType {}
extension Bool          : PropertyListType {}
extension Array         : PropertyListType where Element: PropertyListType {}
extension Dictionary    : PropertyListType where Key == String, Value: PropertyListType {}
extension Data          : PropertyListType {}

protocol PropertyListStoring
{
    func object<T>(forKey key: String) -> T? where T: PropertyListType
    func setValue<T>(_ value: T?, forKey key: String) where T: PropertyListType
}

// MARK: - Typed storage for plist types

struct TypedPropertyListKey<Value: PropertyListType>
{
    var name: String
}

protocol TypedPropertyListStoring: PropertyListStoring
{
    subscript<Value>(key: TypedPropertyListKey<Value>) -> Value? { get set }
}

extension TypedPropertyListStoring
{
    subscript<Value>(key: TypedPropertyListKey<Value>) -> Value?
    {
        get
        {
            return object(forKey: key.name) as Value?
        }
        set
        {
            setValue(newValue, forKey: key.name)
        }
    }
}

// MARK: - Typed storage for codables

struct TypedJSONCodableKey<Value: Codable>
{
    var name: String
}

protocol TypedJSONCodableStoring: PropertyListStoring
{
    subscript<Value>(key: TypedJSONCodableKey<Value>) -> Value? { get set }
}

extension TypedJSONCodableStoring
{
    subscript<Value>(key: TypedJSONCodableKey<Value>) -> Value?
    {
        get
        {
            return (object(forKey: key.name) as Data?).flatMap {
                try? JSONDecoder().decode(Value.self, from: $0)
            }
            
        }
        set
        {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            setValue(data, forKey: key.name)
        }
    }
}

// MARK: - Extension for UserDefaults

extension UserDefaults: TypedPropertyListStoring, TypedJSONCodableStoring
{
    func object<T>(forKey key: String) -> T? where T : PropertyListType
    {
        return object(forKey: key) as? T
    }
    
    func setValue<T>(_ value: T?, forKey key: String) where T : PropertyListType
    {
        setValue(value as Any?, forKey: key)
    }
}

// MARK: - Alternative in-memory implementation

class DictionaryPropertyListStorage: TypedPropertyListStoring, TypedJSONCodableStoring
{
    private var storage: [String: Any] = [:]
    
    func object<T>(forKey key: String) -> T? where T : PropertyListType
    {
        return storage[key] as? T
    }
    
    func setValue<T>(_ value: T?, forKey key: String) where T : PropertyListType
    {
        storage[key] = value
    }
}

protocol TypedKeys
{
    static func plist<Value: PropertyListType>(key: String,
                                               type: Value.Type) -> TypedPropertyListKey<Value>
    static func json<Value: PropertyListType>(key: String,
                                              type: Value.Type) -> TypedJSONCodableKey<Value>
}

// MARK: - Static convenience methods provided for more concise key definitions

extension TypedKeys
{
    static func plist<Value: PropertyListType>(key: String, type: Value.Type) -> TypedPropertyListKey<Value>
    {
        return TypedPropertyListKey(name: key)
    }
    
    static func json<Value: Codable>(key: String, type: Value.Type) -> TypedJSONCodableKey<Value>
    {
        return TypedJSONCodableKey(name: key)
    }
}


// MARK: - Usage

struct Score: Codable
{
    var player: String
    var points: Int
}


/// Defined by app code, inherit TypedKeys to get you namespaced static methods
enum Keys: TypedKeys
{
    static let numberOfCakes = plist(key: "cake-count", type: Int.self)
    static let complexStructure = plist(key: "complex-dictionary", type: [String:[Int]].self)
    static let score = json(key: "highscore", type: Score.self)
}


extension UserDefaults
{
    private static let playgroundSuiteName = "playground-suite"
    
    static let playground = UserDefaults(suiteName: playgroundSuiteName)!
    static func cleanup() { self.init().removePersistentDomain(forName: playgroundSuiteName)}
}

var storage: TypedPropertyListStoring & TypedJSONCodableStoring = UserDefaults.playground

storage[Keys.numberOfCakes] = 4
storage[Keys.numberOfCakes]

storage[Keys.complexStructure] = ["a": [1,2,3]]
storage[Keys.complexStructure]

storage[Keys.score] = Score(player: "John", points: 3)
storage[Keys.score]
String(data: UserDefaults.playground.data(forKey: Keys.score.name)!, encoding: .utf8)

UserDefaults.cleanup()
