import Core

extension TapPolicy {
    func shouldSwallowPress(of event: RawKeyEvent) -> Bool {
        if dictateKey.dictateMatch(for: event) != nil { return !event.trigger.isSharedModifier }
        if pasteLast.matchesPress(event) { return true }
        return swallowsEscape && dictateKey.isPlainEscape(event)
    }

    func isRelevant(_ event: RawKeyEvent) -> Bool {
        let trigger = event.trigger
        if trigger == dictateKey.trigger || trigger == pasteLast.trigger || trigger == .escape {
            return true
        }
        return dictateKey.isShortcutKey(event)
    }
}
