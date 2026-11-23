extension SessionState {
    mutating func apply(_ event: Event) -> [Effect] {
        switch event {
        case .gesture(let gesture, let stamp): handle(gesture, stamp: stamp)
        case .input(let id, let input): handle(input, id: id)
        case .result(let id, let result): handle(result, id: id)
        case .timer(let timer): handle(timer)
        case .system(let system): handle(system)
        case .request(let request): handle(request)
        }
    }
}
