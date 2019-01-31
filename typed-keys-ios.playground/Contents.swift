import Foundation

// MARK: - Property list storage

protocol PropertyListType {}

extension String        : PropertyListType {}
extension Int           : PropertyListType {}
extension Int8          : PropertyListType {}
extension Int16         : PropertyListType {}
extension Int32         : PropertyListType {}
extension Int64         : PropertyListType {}
extension UInt          : PropertyListType {}
extension UInt8         : PropertyListType {}
extension UInt16        : PropertyListType {}
extension UInt32        : PropertyListType {}
extension UInt64        : PropertyListType {}
extension Float         : PropertyListType {}
extension Double        : PropertyListType {}
extension Bool          : PropertyListType {}
extension Date          : PropertyListType {}
extension Array         : PropertyListType where Element: PropertyListType {}
extension Dictionary    : PropertyListType where Key == String, Value: PropertyListType {}
extension Data          : PropertyListType {}

/// Base API for string-keyed access to plist values
protocol PropertyListStoring
{
    subscript(key: String) -> Any? { get set }
}

/// A Key struct with a seemingly unused type parameter that is used in the protocols below
struct TypedKey<T>
{
    var name: String
}

/// Provides storage for plist and Codable types
protocol TypedKeyValueStoring: PropertyListStoring
{
    subscript<T>(key: TypedKey<T>) -> T? where T: PropertyListType           { get set }
    subscript<T>(key: TypedKey<T>) -> T? where T: PropertyListType & Codable { get set }
    subscript<T>(key: TypedKey<T>) -> T? where T: Codable                    { get set }
}

extension PropertyListStoring
{
    subscript<T: PropertyListType>(key: TypedKey<T>) -> T?
    {
        get
        {
            return self[key.name] as? T
        }
        set
        {
            self[key.name] = newValue
        }
    }
    
    subscript<T: PropertyListType & Codable>(key: TypedKey<T>) -> T?
    {
        get
        {
            return self[key.name] as? T
        }
        set
        {
            self[key.name] = newValue
        }
    }
    
    subscript<T: Codable>(key: TypedKey<T>) -> T?
    {
        get
        {
            return (self[key.name] as? Data).flatMap {
                try? JSONDecoder().decode(T.self, from: $0)
            }
        }
        set
        {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            self[key.name] = data
        }
    }
}


// MARK: - Extension for UserDefaults

extension UserDefaults: TypedKeyValueStoring
{
    subscript(key: String) -> Any?
    {
        get
        {
            return object(forKey: key)
        }
        set
        {
            setValue(newValue, forKey: key)
        }
    }
}

/// Alternative in-memory implementation
class DictionaryPropertyListStorage: TypedKeyValueStoring
{
    private var dictionary: [String: Any] = [:]
    
    subscript(key: String) -> Any? {
        get
        {
            return dictionary[key]
        }
        set
        {
            dictionary[key] = newValue
        }
    }
}


// MARK: - Usage

/// Some Codable struct
struct Score: Codable
{
    var player: String
    var points: Int
}

/// Defined by app code
enum Keys
{
    static let numberOfCakes = TypedKey<Int>(name: "cake-count")
    static let complexStructure = TypedKey<[String:[Int]]>(name: "complex-dictionary")
    static let score = TypedKey<Score>(name: "highscore")
}

// MARK: - Temporary defaults

extension UserDefaults
{
    private static let playgroundSuiteName = "playground-suite"
    
    static let playground = UserDefaults(suiteName: playgroundSuiteName)!
    static func cleanup()
    {
        self.init().removePersistentDomain(forName: playgroundSuiteName)
    }
}

var storage: TypedKeyValueStoring = UserDefaults.playground

storage[Keys.numberOfCakes] = 4
storage[Keys.numberOfCakes]

storage[Keys.complexStructure] = ["a": [1,2,3]]
storage[Keys.complexStructure]

storage[Keys.score] = Score(player: "John", points: 3)
storage[Keys.score]
// check the string value to see the JSON
String(data: UserDefaults.playground.data(forKey: Keys.score.name)!, encoding: .utf8)


// MARK: - You can spread out the definition of the keys if you want
extension Keys
{
    static let date = TypedKey<Date>(name: "date")
}

storage[Keys.date] = Date()
storage[Keys.date]

UserDefaults.cleanup()
