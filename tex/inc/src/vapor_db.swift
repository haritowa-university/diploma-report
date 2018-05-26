final class User: Model {
    typealias Database = FooDatabase
    typealias ID = Int

    static let idKey: IDKey = .id
    var id: Int?
    var name: String
    var age: Int

    init(id: Int? = nil, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
}