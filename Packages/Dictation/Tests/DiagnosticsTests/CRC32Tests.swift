@testable import Diagnostics
import Foundation
import Testing

internal struct CRC32Tests {
    @Test
    func matchesTheStandardCheckValue() {
        #expect(CRC32.checksum(Data("123456789".utf8)) == 0xCBF4_3926)
    }

    @Test
    func emptyInputIsZero() {
        #expect(CRC32.checksum(Data()) == 0)
    }
}
