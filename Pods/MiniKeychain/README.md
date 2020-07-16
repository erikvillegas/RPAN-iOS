[![Version](http://img.shields.io/cocoapods/v/MiniKeychain.svg?style=flat)](http://cocoadocs.org/docsets/MiniKeychain)
[![License](https://img.shields.io/cocoapods/l/MiniKeychain.svg?style=flat)](http://cocoadocs.org/docsets/MiniKeychain)
[![Platform](https://img.shields.io/cocoapods/p/MiniKeychain.svg?style=flat)](http://cocoadocs.org/docsets/MiniKeychain)

# MiniKeychain
Keychain library for [reddift](https://github.com/sonsongithub/reddift).
MiniKeychain is developed based on [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess).

# How to use

```
let keychain = MiniKeychain(service: "com.sonson.MiniKeychain")
let name = "name"
let password = "password"
if let data = password.data(using: .utf8) {
    do {
        try keychain.save(key: name, data: data)
    } catch {
        print(error)
    }
}
```

# License

MIT license.