import Foundation
import RealmSwift

import RxSwift
import RxRealm

class DeviceModel: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""

    // Decoded key data
    dynamic var publicKey: Data = Data()

    @objc override class func primaryKey() -> String? {
        return "id"
    }
}

extension Realm { // Queries
    func getDevices(for userID: String) -> Observable<List<DeviceModel>?> {
        let realmQuery = DB.mainThreadRealm.objects(UserModel.self).filter("id = '\(userID)'")

        return Observable.array(from: realmQuery).map { (users: [UserModel]) -> List<DeviceModel>? in
            guard let user = users.first else { return nil }
            return user.devices
        }
    }
}

import Foundation
import RealmSwift

import RxSwift
import RxRealm

class MessageModel: Object {
    dynamic var id: String = ""
    dynamic var createdDate: Date = Date()

    dynamic var dialogue: UserModel? = nil
    dynamic var sender: UserModel? = nil

    dynamic var messageText: String = ""

    @objc override class func primaryKey() -> String? {
        return "id"
    }

    static func addCurrentUserMessage(with text: String, dialogue: UserModel) {
        guard let currentUser = UserModel.current else { return }

        let model = MessageModel()
        model.messageText = text
        model.sender = currentUser
        model.dialogue = dialogue
        model.id = UUID().uuidString
        model.createdDate = Date()

        let realm = DB.mainThreadRealm
        _ = try? realm.write {
            realm.add(model, update: true)
            dialogue.latestMessage = model
        }
    }
    
    static func addAnotherUserMessage(with text: String, dialogue: UserModel) {
        let model = MessageModel()
        model.messageText = text
        model.sender = dialogue
        model.dialogue = dialogue
        model.id = UUID().uuidString
        model.createdDate = Date()
        
        let realm = DB.mainThreadRealm
        _ = try? realm.write {
            realm.add(dialogue, update: true)
            realm.add(model, update: true)
            dialogue.latestMessage = model
        }
    }

    static func addCurrentUserMessageObservable(with text: String, dialogue: UserModel) -> Single<Void> {
        return Single<Void>.create { observer in
            MessageModel.addCurrentUserMessage(with: text, dialogue: dialogue)
            observer(.success(()))
            return Disposables.create()
        }
    }
}

import Foundation
import RealmSwift

import RxSwift
import RxRealm

class UserModel: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    let devices = List<DeviceModel>()
    
    dynamic var latestMessage: MessageModel? = nil

    let messages = LinkingObjects(fromType: MessageModel.self, property: "dialogue")

    @objc override class func primaryKey() -> String? {
        return "id"
    }

    static func dialogues() -> Observable<[UserModel]> {
        let realmQuery = DB.mainThreadRealm.objects(UserModel.self)
            .sorted(byKeyPath: "latestMessage.createdDate")
            .filter("latestMessage != nil")
        
        return Observable.array(from: realmQuery)
    }

    static var current: UserModel? {
        guard let userID = Session.shared.userID else { return nil }
        return DB.mainThreadRealm.object(ofType: UserModel.self, forPrimaryKey: userID)
    }
}

extension UserModel {
    convenience init(from response: UserResponse, devices: [DeviceModel] = []) {
        self.init()
        
        self.id = response.id
        self.name = response.name
        self.devices.append(objectsIn: devices)
    }
}

import Foundation
import RealmSwift
import RxSwift
import RxRealm


struct DB {
    static let mainThreadRealm = try! Realm()

    static var currentThreadRealm: Realm {
        return try! Realm()
    }

    enum Error: Swift.Error {
        case cantGetRealm
    }

    static func store<T: Object>(objects: [T]) -> Single<[T]> {
        guard let firstObject = objects.first else { return .just(objects) }

        return Single<[T]>.create { singleHandler in
            do {
                let realm = firstObject.realm ?? DB.currentThreadRealm

                try realm.write { realm.add(objects, update: true) }
                singleHandler(.success(objects))
            } catch {
                singleHandler(.error(error))
            }

            return Disposables.create()
        }
    }
}

import Foundation
import SwCrypt

import KeychainAccess

typealias AESKey = Data
typealias RSAPrivateKey = Data
typealias RSAPublicKey = Data

class Crypt {
    struct Constants {
        struct Salt {
            static let defaultSalt = "diploma"

            static func create() -> Data {
                return defaultSalt.data(using: .utf8)!
            }
        }

        // Keychain store keys in encrypted form
        struct Keychain {
            static let prefix = "com.heartbleed.chatty"

            static let service = prefix + ".crypto"

            // Encrypted by derived from pin
            static let aesKey = service + ".aes"
            static let iv = service + ".iv"
            static let pinIV = service + ".pinIV"

            // Encrypted by local key
            static let privateKey = service + ".private"

            // Encrypted by local key
            static let publicKey = service + ".public"

            static let testData = service + ".test"

            static let `default`: KeychainAccess.Keychain = KeychainAccess.Keychain(service: service)
        }

        struct Pin {
            static let pinLength = 4
        }

        struct Key {
            static let rsaKeyLength: Int = 1024
            static let aesKeyLengthBytes: Int = 32
            static let aesKeyLength: Int = aesKeyLengthBytes * 8

            static let ivSize: Int = 16
        }
    }
}

extension Crypt {
    struct Utilities {
        // MARK: = Utilities
        static func existingIdentityData() -> [UserCryptIdentity.IdentityKey] {
            return UserCryptIdentity.IdentityKey.all.filter { isExist(identityData: $0) }
        }
        
        static func isAllIdentityDataExist() -> Bool {
            return existingIdentityData().count == UserCryptIdentity.IdentityKey.all.count
        }

        static func isExist(identityData: UserCryptIdentity.IdentityKey...) -> Bool {
            return identityData.reduce(true) { $0.0 && isExist(identityData: $0.1) }
        }

        static func isExist(identityData: UserCryptIdentity.IdentityKey) -> Bool {
            // Swift, wtf, just compile ??
            if let contains = try? Constants.Keychain.default.contains(identityData.identityKey) {
                return contains
            } else {
                return false
            }
        }

        static func remove(key: UserCryptIdentity.IdentityKey) {
            _ = try? Constants.Keychain.default.remove(key.identityKey)
        }

        static func remove(keys: [UserCryptIdentity.IdentityKey]) {
            keys.forEach(remove)
        }

        static func reset() {
            remove(keys: UserCryptIdentity.IdentityKey.all)
        }

        static func store(key: UserCryptIdentity.IdentityKey, data: Data) throws {
            try Constants.Keychain.default.set(data, key: key.identityKey)
        }

        static func read(for key: UserCryptIdentity.IdentityKey) throws -> Data? {
            return try Constants.Keychain.default.getData(key.identityKey)
        }

        static func read(for key: UserCryptIdentity.IdentityKey) throws -> Data {
            guard let data = try Constants.Keychain.default.getData(key.identityKey) else {
                throw CryptError.cantReadIdentity
            }

            return data
        }

        static func check(pin: String) throws {
            guard pin.characters.count == Constants.Pin.pinLength else {
                throw CryptError.wrongPinLength
            }
        }

        private static func check(pinKey: Data, pinIV: Data) throws {
            let testData: Data = try read(for: .testData)
            let decryptedTestData = try aesDecrypt(data: testData, with: pinKey, iv: pinIV)

            guard let testDataString = String(data: decryptedTestData, encoding: .utf8),
                    testDataString == Crypt.Constants.Keychain.testData else {
                throw CryptError.AESError.cantDecrypt(NSError(domain: Crypt.Constants.Keychain.prefix, code: 1))
            }
        }

        // MARK: - AES
        static func generateAESKey(size: Int = Constants.Key.aesKeyLengthBytes) throws -> AESKey {
            var key = [UInt8](repeating: 0, count: size)
            guard SecRandomCopyBytes(kSecRandomDefault, size, &key) == 0, key.count == size else {
                throw KeyGenerationError.cantCreateAESKey
            }

            return Data(bytes: key)
        }

        static func deriveAESKey(by pin: String) throws -> AESKey {
            do {
                return try CC.KeyDerivation.PBKDF2(pin, salt: Constants.Salt.create(), prf: .sha256, rounds: 100)
            } catch {
                throw KeyGenerationError.cantDeriveKeyFromPin(error)
            }
        }

        // MARK: Encryption
        static func aesEncrypt(data: Data, with key: AESKey, iv: Data) throws -> Data {
            do {
                return try CC.crypt(.encrypt, blockMode: .cbc, algorithm: .aes, padding: .pkcs7Padding, data: data, key: key, iv: iv)
            } catch {
                throw CryptError.AESError.cantEncrypt(error)
            }
        }

        static func aesDecrypt(data: Data, with key: AESKey, iv: Data) throws -> Data {
            do {
                return try CC.crypt(.decrypt, blockMode: .cbc, algorithm: .aes, padding: .pkcs7Padding, data: data, key: key, iv: iv)
            } catch {
                throw CryptError.AESError.cantDecrypt(error)
            }
        }

        static func rsaEncrypt(data: Data, with key: RSAPublicKey) throws -> Data {
            return try CC.RSA.encrypt(data, derKey: key, tag: Data(), padding: .pkcs1, digest: .none)
        }

        static func rsaDecrypt(data: Data, with key: RSAPrivateKey) throws -> Data {
            return try CC.RSA.decrypt(data, derKey: key, tag: Data(), padding: .pkcs1, digest: .none).0
        }

        // MARK: - RSA
        static func getRSAPublicKeyFromPem(_ pem: String) throws -> Data {
            do {
                return try SwKeyConvert.PublicKey.pemToPKCS1DER(pem)
            } catch {
                throw KeyGenerationError.cantConvertPemToRSAKey(error)
            }
        }

        static func generateRSAKeyPair() throws -> (privateKey: RSAPrivateKey, publicKey: RSAPublicKey) {
            do {
                return try CC.RSA.generateKeyPair()
            } catch {
                throw KeyGenerationError.cantCreateRSAKeyPair(error)
            }
        }

        // MARK: - Creation
        static func createIdentity() throws -> UserCryptIdentity {
            // Generate key
            let key = try generateAESKey()
            let keyIV = try generateAESKey(size: Constants.Key.ivSize)

            // RSA
            let (privateKey, publicKey) = try generateRSAKeyPair()

            let pem = SwKeyConvert.PublicKey.derToPKCS8PEM(publicKey)

            return UserCryptIdentity(
                    privateKey: privateKey,
                    publicKey: publicKey,
                    publicKeyPEM: pem,
                    localAESKey: key,
                    localAESIV: keyIV
            )
        }

        static func store(identity: UserCryptIdentity, pin: String, rewrite: Bool = true) throws {
            try check(pin: pin)

            if rewrite {
                reset()
            } else {
                // Check if there is any old credentials

                let existingData = existingIdentityData()
                guard existingData.isEmpty else {
                    throw CryptError.identityAlreadyExist(data: existingData)
                }
            }

            // Encrypt local aes key with derived from pin code key
            let pinKey = try deriveAESKey(by: pin)
            let pinIV = try generateAESKey(size: Constants.Key.ivSize)

            let encryptedLocalKey = try aesEncrypt(data: identity.localAESKey, with: pinKey, iv: pinIV)
            let encryptedKeyIV = try aesEncrypt(data: identity.localAESIV, with: pinKey, iv: pinIV)

            let encryptedPublicKey = try aesEncrypt(data: identity.publicKey, with: identity.localAESKey, iv: identity.localAESIV)
            let encryptedPrivateKey = try aesEncrypt(data: identity.privateKey, with: identity.localAESKey, iv: identity.localAESIV)

            let encryptedTestData = try aesEncrypt(data: Crypt.Constants.Keychain.testData.data(using: .utf8)!, with: pinKey, iv: pinIV)

            do {
                try store(key: .aes, data: encryptedLocalKey)
                try store(key: .iv, data: encryptedKeyIV)

                try store(key: .pinIV, data: pinIV)

                try store(key: .rsaPrivate, data: encryptedPrivateKey)
                try store(key: .rsaPublic, data: encryptedPublicKey)

                try store(key: .testData, data: encryptedTestData)
            } catch {
                reset()
                throw CryptError.cantStoreIdentity
            }
        }

        // MARK: Read
        static func readIdentity(with pin: String) throws -> UserCryptIdentity {
            try check(pin: pin)

            let pinIV: Data = try read(for: .pinIV)
            let pinKey = try deriveAESKey(by: pin)

            let encryptedLocalKey: Data = try read(for: .aes)
            let encryptedLocalIV: Data = try read(for: .iv)

            let encryptedPrivateKey: Data = try read(for: .rsaPrivate)
            let encryptedPublicKey: Data = try read(for: .rsaPublic)

            try check(pinKey: pinKey, pinIV: pinIV)

            let localKey = try aesDecrypt(data: encryptedLocalKey, with: pinKey, iv: pinIV)
            let localIV = try aesDecrypt(data: encryptedLocalIV, with: pinKey, iv: pinIV)

            let publicKey = try aesDecrypt(data: encryptedPublicKey, with: localKey, iv: localIV)
            let privateKey = try aesDecrypt(data: encryptedPrivateKey, with: localKey, iv: localIV)

            let pem = SwKeyConvert.PublicKey.derToPKCS8PEM(publicKey)

            return UserCryptIdentity(
                    privateKey: privateKey,
                    publicKey: publicKey,
                    publicKeyPEM: pem,
                    localAESKey: localKey,
                    localAESIV: localIV
            )
        }
    }
}

import Foundation

struct UserCryptIdentity {
    enum IdentityKey {
        case aes
        case iv
        case pinIV
        case rsaPublic
        case rsaPrivate

        case testData

        var identityKey: String {
            switch self {
            case .aes: return Crypt.Constants.Keychain.aesKey
            case .pinIV: return Crypt.Constants.Keychain.pinIV
            case .iv: return Crypt.Constants.Keychain.iv
            case .rsaPublic: return Crypt.Constants.Keychain.publicKey
            case .rsaPrivate: return Crypt.Constants.Keychain.privateKey
            case .testData: return Crypt.Constants.Keychain.testData
            }
        }

        static let all: [IdentityKey] = [
                IdentityKey.aes,
                IdentityKey.pinIV,
                IdentityKey.iv,
                IdentityKey.rsaPublic,
                IdentityKey.rsaPrivate,
                IdentityKey.testData
        ]
    }

    let privateKey: RSAPrivateKey
    let publicKey: RSAPublicKey

    let publicKeyPEM: String

    let localAESKey: AESKey
    let localAESIV: Data
}