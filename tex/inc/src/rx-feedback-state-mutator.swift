func resetLoopVariables(prevState: SearchState) -> SearchState {
    // Reset operationState
}

func searchRequested(prevState: SearchState) -> SearchState {
    guard case .idle = prevState.operationState,
        let nextPageURL = prevState.nextPageURL else {
        return prevState
    }
    
    var newState = prevState
    newState.operationState = .scheduled(nextPageURL)
    return newState
}

func create(input: Event) -> (SearchState) -> SearchState {
    var result = resetLoopVariables
    
    switch input {
    case .loadNewPageRequest: result = result >>> searchRequested
    default: break // Do not handle other cases in example
    }
    
    return result
}