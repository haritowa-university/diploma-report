public protocol LazyViewModel {
    associatedtype InitInput
    func setup(with input: InitInput)
}