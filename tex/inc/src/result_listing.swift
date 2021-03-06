class DeviceModel: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""

    // Decoded key data
    dynamic var publicKey: Data = Data()

    @objc override class func primaryKey() -> String? {
        return "id"
    }
}

enum PresentType {
    case push
    case present(wrap: Bool)
}

protocol NavigationEndpoint: URLConvertible {
    var storyboardName: String { get }
    var screenIdentifier: String { get }
    var presentationType: PresentType { get }

    func setup(viewController: UIViewController) -> Bool

    static var patterns: [String] { get }
}

extension NavigationEndpoint {
    public var urlValue: URL? {
        return URL(string: self.urlStringValue)
    }
}

extension URLNavigator {
    func registerEndpoint(name: String) {
        self.map(name) { (url, values) -> Bool in
            guard let endpoint = url as? NavigationEndpoint else { return false }

            let viewController = UIStoryboard(name: endpoint.storyboardName, bundle: Bundle.main)
                    .instantiateViewController(withIdentifier: endpoint.screenIdentifier)

            guard endpoint.setup(viewController: viewController) else { return false }

            switch endpoint.presentationType {
            case .push: Navigator.push(viewController)
            case .present(let wrap): Navigator.present(viewController, wrap: wrap)
            }

            return true
        }
    }

    func registerPatterns<T: NavigationEndpoint>(for endpointType: T.Type) {
        T.patterns.forEach(registerEndpoint)
    }

    func present(endpoint: NavigationEndpoints) {
        self.open(endpoint)
    }
}

protocol Navigatable {
    func performNavigation()
}

enum NavigationDescription: Navigatable {
    case alert(title: String?, message: String?)
    case errorPopup(Error)
    case endpoint(NavigationEndpoints)
    case dismiss
    case popToRoot
    
    func performNavigation() { Navigation.present(from: self) }
}

struct NavigationChainDescription: Navigatable {
    enum DismissDescription {
        case current
        case toRoot
        case none
    }
    
    let dismissStrategy: DismissDescription
    let endpoint: NavigationEndpoints
    
    init(dismissDescription: DismissDescription = .current, endpoint: NavigationEndpoints) {
        self.dismissStrategy = dismissDescription
        self.endpoint = endpoint
    }
    
    func performNavigation() { Navigation.present(from: self) }
}

struct Navigation {
    static func present(endpoint: NavigationEndpoints) {
        Navigator.open(endpoint)
    }
    
    static let navigationObserver = AnyObserver<Navigatable> { (event) in
        guard let value = event.element else { return }
        DispatchQueue.main.async(execute: value.performNavigation)
    }
    
    static func present(from chainDescription: NavigationChainDescription) {
        let completion: () -> Void = { _ in Navigator.open(chainDescription.endpoint) }
        switch chainDescription.dismissStrategy {
        case .current: dismissCurrent(completion: completion)
        case .toRoot: dismissToRoot(completion: completion)
        case .none: completion()
        }
    }
    
    static func present(from description: NavigationDescription) {
        switch description {
        case .endpoint(let endpoint): Navigator.open(endpoint)
        case let .alert(title, message):
            var rootPath = "/alert?"
            if let title = title { rootPath += "title=\(title)" }
            if let message = message { rootPath += "&message=\(message)" }
            Navigator.open(rootPath)
        case .errorPopup(let error):
            present(from: .alert(title: "Error", message: "\(error)"))
        case .dismiss: dismissCurrent()
        case .popToRoot: dismissToRoot()
        }
    }
    
    private static func dismissCurrent(completion: (() -> Void)? = nil) {
        guard var targetViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        while let presentedVC = targetViewController.presentedViewController {
            targetViewController = presentedVC
        }
        
        targetViewController.dismiss(animated: true, completion: completion)
    }
    
    private static func dismissToRoot(completion: (() -> Void)? = nil) {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }

        if let navigationController = rootViewController as? UINavigationController {
            navigationController.popToRootViewController(animated: true)
            completion?()
        }

        rootViewController.dismiss(animated: true, completion: completion)
    }

    static func registerEndpoints() {
        Navigator.registerPatterns(for: NavigationEndpoints.self)
    }
}

enum NavigationEndpoints: NavigationEndpoint {
    case signUp(userCryptIdentityInfo: UserCryptIdentityInfo)
    case pinCode

    case setIP
    case fetchData

    case home
    
    case dialogue(UserModel)

    var storyboardName: String {
        switch self {
        case .signUp, .pinCode: return "Authorization"
        case .fetchData, .setIP: return "Main"
        case .home: return "TabBar"
        case .dialogue: return "Dialogue"
        }
    }

    var screenIdentifier: String {
        switch self {
        case .signUp: return "authorization"
        case .pinCode: return "pinCode"
        case .fetchData: return "fetchData"
        case .home: return "root"
        case .dialogue: return "dialogue"
        case .setIP: return "setip"
        }
    }
    
    var urlStringValue: String {
        switch self {
        case .signUp: return "chatty://signup"
        case .pinCode: return "chatty://pincode"
        case .fetchData: return "chatty://fetchdata"
        case .home: return "chatty://home"
        case .dialogue: return "chatty://dialogue"
        case .setIP: return "chatty://setIP"
        }
    }

    static var patterns: [String] = [
        "chatty://signup",
        "chatty://pincode",
        "chatty://fetchdata",
        "chatty://home",
        "chatty://dialogue",
        "chatty://setIP"
    ]

    var presentationType: PresentType {
        switch self {
        case .home: return .present(wrap: true)
        case .pinCode, .signUp, .setIP: return .present(wrap: false)
        case .fetchData, .dialogue: return .push
        }
    }

    func setup(viewController: UIViewController) -> Bool {
        switch self {
        case .signUp(let userCryptIdentityInfo):
            return NavigationEndpoints.setupSignUp(viewController: viewController, userCryptIdentityInfo: userCryptIdentityInfo)
        case .pinCode:
            return NavigationEndpoints.setupPinCode(viewController: viewController)
        case .fetchData:
            return NavigationEndpoints.setupFetchData(viewController: viewController)
        case .home: return true
        case .dialogue(let dialogue):
            return NavigationEndpoints.setupDialogue(viewController: viewController, dialogue: dialogue)
        case .setIP:
            return NavigationEndpoints.setupSetIP(viewController: viewController)
        }
    }

    private static func setupSetIP(viewController: UIViewController) -> Bool {
        guard let fetchViewController = viewController as? SetIPViewController else { return false }
        let viewModel = SetIPViewModel()
        fetchViewController.inject(viewModel: viewModel)

        return true
    }

    private static func setupFetchData(viewController: UIViewController) -> Bool {
        guard let fetchViewController = viewController as? UpdateDataViewController else { return false }
        let viewModel = UpdateDataViewModel()
        fetchViewController.inject(viewModel: viewModel)

        return true
    }

    private static func setupPinCode(viewController: UIViewController) -> Bool {
        guard let pinCodeViewController = viewController as? PinCodeViewController else { return false }
        let viewModel = PinCodeViewModel()
        pinCodeViewController.inject(viewModel: viewModel)

        return true
    }
    
    private static func setupDialogue(viewController: UIViewController, dialogue: UserModel) -> Bool {
        guard let pinCodeViewController = viewController as? ChatViewController else { return false }
        let viewModel = ChatViewModel(dialogue: dialogue)
        pinCodeViewController.inject(viewModel: viewModel)
        
        return true
    }

    private static func setupSignUp(viewController: UIViewController, userCryptIdentityInfo: UserCryptIdentityInfo) -> Bool {
        guard let signUpViewController = viewController as? SignInViewController else { return false }

        let signInViewModel = SignInViewModel(signingIdentity: userCryptIdentityInfo)
        signUpViewController.inject(viewModel: signInViewModel)
        
        return true
    }
}


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
    }
}