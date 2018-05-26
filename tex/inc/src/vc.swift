public protocol ViewModelInjectable {
    associatedtype AssociatedViewModel: LazyViewModel
    
    func setup(with viewModel: AssociatedViewModel)
    func generateInput() -> AssociatedViewModel.InitInput
}