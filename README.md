# Introduction
This is a playground showing how wrap/replace `UserDefaults`
by a fully typed key-value storage API

# UserDefaults
Using UserDefaults, one might normally do the following:

```
UserDefaults.standard.register(defaults: ["NumberOfCakes": 4])
let numCakes = UserDefaults.standard.object(forKey: "NumberOfCakes") as? Int
```

Apart from not using a `String` constant for the key, the main problem with the above code is that:

- you have to cast everywhere you fetch the value
- the type of the value stored under a key, which usually does not change, is not enforced

# A better API

It would be much nicer if one were to be able to do the following:

```
struct MyCodableStruct: Codable
{
    var stuff: Int
}

enum Keys
{
    static let numberOfCakes = TypedKey<Int>(name: "NumberOfCakes")
    static let arrayOfCodableStructs = TypedKey<[MyCodableStruct]>(name: "AmazingStuff")
}

UserDefaults.standard[Keys.arrayOfCodableStructs] = [MyCodableStruct(stuff: 6), MyCodableStruct(stuff: 5)]
assert(UserDefaults.standard[Keys.arrayOfCodableStructs].count == 2)
```
