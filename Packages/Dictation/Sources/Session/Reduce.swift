internal func reduce(_ state: inout SessionState, _ event: Event) -> [Effect] {
    let policy = state.tapPolicy
    var effects = state.apply(event)
    effects += state.settle()
    state.refreshHUD()
    if state.tapPolicy != policy {
        effects.append(.setTapPolicy(state.tapPolicy))
    }
    return effects
}
