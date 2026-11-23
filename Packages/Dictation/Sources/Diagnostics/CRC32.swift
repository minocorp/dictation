import Foundation

internal enum CRC32 {
    private static let table: [UInt32] = (0..<256)
        .map { index in
            (0..<8)
                .reduce(UInt32(index)) { value, _ in
                    value & 1 == 1 ? 0xEDB8_8320 ^ (value >> 1) : value >> 1
                }
        }

    static func checksum(_ data: Data) -> UInt32 {
        ~data.reduce(UInt32.max) { crc, byte in
            table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
    }
}
