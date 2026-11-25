import Core

internal struct TapHealthCheck: Sendable {
    let probe: any TapProbe
    let clock: any Clock<Duration>
    let interval: Duration

    func run(into continuation: AsyncStream<TapHealth>.Continuation) async {
        var last: TapHealth?
        while !Task.isCancelled {
            let current = probe.read()
            if current != last {
                last = current
                continuation.yield(current)
            }
            guard await clock.sleepUnlessCancelled(for: interval) else { return }
        }
    }
}
