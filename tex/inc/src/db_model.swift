class DeviceModel: Object {
    // Device id, must be unique
    dynamic var id: String = ""

    // Device name
    dynamic var name: String = ""

    // Decoded key data
    dynamic var publicKey: Data = Data()

    @objc dynamic var tmpID = 0

    let owners = LinkingObjects(fromType: User.self, property: "devices")

    let dialogues: LinkingObjects(fromType: Dialogue.self, property: "devices")

    @objc override class func primaryKey() -> String? {
        return "id"
    }

    // We do not want to store temp value
    override static func ignoredProperties() -> [String] {
        return ["tmpID"]
    }
}

extension DeviceModel {
    public init(id: String, name: String, publicKey: Data, tmpID: Int) {
        self.id = id
        self.name = name
        self.publicKey = publicKey
        self.tmpID = tmpID
    }
}