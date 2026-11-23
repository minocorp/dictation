public import Core

public struct GlobeSetting: Hashable, Sendable {
    public let usage: GlobeUsage

    public var changesInputSource: Bool { usage == .changeInputSource }
    public var isFnFree: Bool { usage == .doNothing }
    public var recommendedDictateKey: KeyBinding { changesInputSource ? .rightOption : .fn }

    public init(usage: GlobeUsage) {
        self.usage = usage
    }
}
