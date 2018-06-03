class DeviceModel: Object {
    // Device id, must be unique
    dynamic var id: String = ""

    // Device name
    dynamic var name: String = ""

    // Decoded key data
    dynamic var publicKey: Data = Data()

    @objc dynamic var tmpID = 0

    let owners = LinkingObjects(fromType: User.self, property: "devices")

    @objc override class func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["tmpID"]
    }
}