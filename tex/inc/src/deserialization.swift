import Foundation
import ObjectMapper
import ChatCore

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

    public static func empty() -> ContactListResponse {
        return ContactListResponse(users: [])
    }
}

public extension ContactListResponse {
    public init(map: Map) throws {
        do {
            users = try map.value("contacts")
        } catch (MappingError.keyNotFound) {
            users = []
        } catch {
            throw error
        }
    }
}
