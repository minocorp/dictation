package actor SerialGate {
    private var isBusy = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    package init() {}

    package func run<T: Sendable>(_ work: @Sendable () async -> T) async -> T {
        await acquire()
        let result = await work()
        release()
        return result
    }

    private func acquire() async {
        guard isBusy else {
            isBusy = true
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    private func release() {
        guard !waiters.isEmpty else {
            isBusy = false
            return
        }
        waiters.removeFirst().resume()
    }
}
