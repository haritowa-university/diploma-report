enum Event {
    case loadNewPageRequest
    case loadCompleted(SearchState)
    case loadFailed(Error)
}