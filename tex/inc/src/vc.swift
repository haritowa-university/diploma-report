public protocol ViewModelInjectable {
    associatedtype AssociatedViewModel: LazyViewModel
    
    func setup(with viewModel: AssociatedViewModel)
    func generateInput() -> AssociatedViewModel.InitInput
}

extension ViewModelInjectable {
    fileprivate func setup(using vm: AssociatedViewModel) {
        vm.setup(with: generateInput())
        setup(with: vm)
    }
}

extension ViewModelInjectable where Self: UIViewController {
    func inject(viewModel: AssociatedViewModel) -> Disposable {
        guard !isViewLoaded else {
            setup(using: viewModel)
            return
        }
        
        let rxSelf = self as UIViewController
        
        return rxSelf.rx.sentMessage(#selector(UIViewController.viewDidLoad))
            .map { _ in viewModel }
            .subscribe(onNext: { [unowned self] (_) in
                self.setup(using: viewModel)
            })
    }
}