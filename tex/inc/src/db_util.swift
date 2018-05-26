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