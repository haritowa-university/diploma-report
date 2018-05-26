import Foundation
import ObjectMapper

final class ResponseContainer<InnerResponse: ImmutableMappable>: 
	ImmutableMappable {
    let data: InnerResponse

    public required init(map: Map) throws {
        data = try map.value("data")
    }
}