import Foundation
import Chatt

extension SearchState {
    static func initial(for query: String) -> SearchState {
        return SearchState(
            query: query,
            results: [],
            nextPageURL: generateInitialURL(for query: query),
            operationState: .idle
        )
    }
}