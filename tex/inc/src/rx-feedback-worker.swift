class SearchWorker {
    func createRequest(for url: URL) -> Observable<Event> {
        return getNextSearchResultPage(for url)
    }
}