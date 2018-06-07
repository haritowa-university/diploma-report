import Foundation
import ObjectMapper

struct SendMessageRequest {
    let text: String
    let receiverID: String
}

extension SendMessageRequest: BaseRequest {
    public func mapping(map: Map) {
        text >>> map["text"]
        receiverID >>> map["id"]
    }
}

struct SendMessagesRequest {
	let messages: [SendMessageRequest]
}

extension SendMessagesRequest {
	public func mapping(map: Map) {
        messages >>> map["messages"]
    }
}