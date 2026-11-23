import Core
import Foundation

internal enum CAFFormat {
    static let fileTag = Array("caff".utf8)
    static let descriptionTag = Array("desc".utf8)
    static let dataTag = Array("data".utf8)
    static let linearPCMTag = Array("lpcm".utf8)
    static let tagSize = 4
    static let sampleRate = Double(AudioChunk.sampleRate)
    static let bytesPerSample = MemoryLayout<Float>.size
    static let fileHeaderSize = 8
    static let chunkHeaderSize = 12
    static let descriptionSize = 32
    static let editCountSize = 4
    static let dataSizeOffset = fileHeaderSize + chunkHeaderSize + descriptionSize + 4
    static let samplesOffset = dataSizeOffset + 8 + editCountSize
    static let unknownDataSize: Int64 = -1
    static let floatLittleEndianFlags: UInt32 = 3

    static func header() -> Data {
        var data = Data()
        data.append(contentsOf: fileTag)
        data.appendBigEndian(UInt16(1))
        data.appendBigEndian(UInt16(0))
        data.append(contentsOf: descriptionTag)
        data.appendBigEndian(Int64(descriptionSize))
        data.appendBigEndian(sampleRate.bitPattern)
        data.append(contentsOf: linearPCMTag)
        data.appendBigEndian(floatLittleEndianFlags)
        data.appendBigEndian(UInt32(bytesPerSample))
        data.appendBigEndian(UInt32(1))
        data.appendBigEndian(UInt32(1))
        data.appendBigEndian(UInt32(bytesPerSample * 8))
        data.append(contentsOf: dataTag)
        data.appendBigEndian(unknownDataSize)
        data.appendBigEndian(UInt32(0))
        return data
    }

    static func dataChunkSize(sampleCount: Int) -> Int64 {
        Int64(editCountSize + sampleCount * bytesPerSample)
    }
}

extension Data {
    mutating func appendBigEndian<Value: FixedWidthInteger>(_ value: Value) {
        Swift.withUnsafeBytes(of: value.bigEndian) { append(contentsOf: $0) }
    }

    func bigEndianValue<Value: FixedWidthInteger>(at offset: Int, as type: Value.Type) -> Value {
        withUnsafeBytes {
            Value(bigEndian: $0.loadUnaligned(fromByteOffset: offset - startIndex, as: type))
        }
    }
}
