class DeviceModel: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""

    // Decoded key data
    dynamic var publicKey: Data = Data()

    @objc override class func primaryKey() -> String? {
        return "id"
    }
}