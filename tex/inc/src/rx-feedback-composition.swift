import Foundation
import RxSwift

import RxCocoa
import RxSwift

func createPaginator() {
    let internalOutputQueue = inputSubject
        .observeOn(processingQueue)
        .map(SearchPaginatorStateMutatorFactory.create)
        .scan(SearchState.initial(for: query), accumulator: |>)
        .debug()
        .shareReplayLatestWhileConnected()
    
    // Propagate state to ouput
    // Bind internalOutputQueue to worker
    // Bind worker to the inputSubject
}