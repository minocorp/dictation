import Core
import Testing

internal struct RAMTierTests {
    @Test(arguments: [
        (0, RAMTier.ram8), (15, .ram8), (16, .ram16), (23, .ram16), (24, .ram24), (128, .ram24),
    ])
    func tierBoundaries(ramGB: Int, tier: RAMTier) {
        #expect(RAMTier(ramGB: ramGB) == tier)
    }

    @Test
    func machineMemoryIsPositive() {
        #expect(MachineMemory.gigabytes > 0)
    }
}
