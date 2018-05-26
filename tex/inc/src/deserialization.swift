struct UserResponse: ImmutableMappable {
    let name: String
    
    let idInt: Int
    
    var id: String {
        return "\(idInt)"
    }

    public init(map: Map) throws {
        self.name = try map.value("name")
        self.idInt = try map.value("id")
    }
}

struct ContactListResponse: ImmutableMappable {
    let users: [UserResponse]

    public init(map: Map) throws {
        users = try map.value("contacts")
    }
}
