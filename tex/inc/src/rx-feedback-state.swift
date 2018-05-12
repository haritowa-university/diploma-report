struct SearchState {
    enum OperationState {
        case idle
        case scheduled(URL)
        case inProgress
        case completed
    }
    
    // view model
    var query: String
    var results: [String]
    
    // effects
    var nextPageURL: URL?
    var operationState: OperationState
}