import Vapor

public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    router.get("users", Int.parameter) { req -> String in
	    let id = try req.parameters.next(Int.self)
	    return "requested id #\(id)"
	}
}