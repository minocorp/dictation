@testable import QwenCleanup
import Testing

internal struct PrefixCacheTests {
    private let cache = PrefixCache(tokens: [1, 2, 3], layers: [])

    @Test
    func suffixIsWhatFollowsThePrefix() {
        #expect(cache.suffix(of: [1, 2, 3, 4, 5]) == [4, 5])
    }

    @Test
    func promptWithDifferentPrefixHasNoSuffix() {
        #expect(cache.suffix(of: [1, 9, 3, 4]) == nil)
    }

    @Test
    func promptEqualToPrefixHasNoSuffix() {
        #expect(cache.suffix(of: [1, 2, 3]) == nil)
    }
}
