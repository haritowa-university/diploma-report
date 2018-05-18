@discardableResult
public func testAsync<T>(
	operation: Observable<T>,
	elements: Int,
	timeout: Double? = 1,
	actionBeforeTest: (() -> ())? = nil
) -> [T]? {
    let testObservable = operation
	    .take(elements)
	    .share(replay: elements)

    let disposable = testObservable.subscribe()
    
    actionBeforeTest?()
    
    let result = try? testObservable
	    .toBlocking(timeout: timeout)
	    .toArray()

    disposable.dispose()
    return result
}