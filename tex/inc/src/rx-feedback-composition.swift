import Foundation
import RxSwift
import RxCocoa

func createPaginator() {
    let internalOutputQueue = inputSubject
        .observeOn(processingQueue)
        .map(SearchPaginatorStateMutatorFactory.create)
        .scan(SearchState.initial(for: query), accumulator: |>)
        .shareReplayLatestWhileConnected()
    
    // Propagate state to ouput
    // Bind internalOutputQueue to worker
    // Bind worker to inputSubject
}