import Foundation

internal enum ZipArchive {
    private static let localHeaderSignature: UInt32 = 0x0403_4B50
    private static let centralHeaderSignature: UInt32 = 0x0201_4B50
    private static let endSignature: UInt32 = 0x0605_4B50
    private static let versionNeeded: UInt16 = 20
    private static let utf8NameFlag: UInt16 = 0x0800
    private static let dosDate1980: UInt16 = 0x0021

    static func archive(_ entries: [(name: String, data: Data)]) -> Data {
        var body = Data()
        var directory = Data()
        for entry in entries {
            let name = Data(entry.name.utf8)
            let crc = CRC32.checksum(entry.data)
            let offset = UInt32(body.count)
            body.append(
                header(signature: localHeaderSignature, name: name, data: entry.data, crc: crc)
            )
            body.append(name)
            body.append(entry.data)
            directory.append(
                header(
                    signature: centralHeaderSignature,
                    name: name,
                    data: entry.data,
                    crc: crc,
                    localOffset: offset,
                )
            )
            directory.append(name)
        }
        var archive = body
        archive.append(directory)
        archive.append(
            endRecord(count: entries.count, directorySize: directory.count, offset: body.count)
        )
        return archive
    }

    private static func header(
        signature: UInt32,
        name: Data,
        data: Data,
        crc: UInt32,
        localOffset: UInt32? = nil,
    ) -> Data {
        var header = Data()
        header.append(le: signature)
        if localOffset != nil { header.append(le: versionNeeded) }
        header.append(le: versionNeeded)
        header.append(le: utf8NameFlag)
        header.append(le: UInt16(0))
        header.append(le: UInt16(0))
        header.append(le: dosDate1980)
        header.append(le: crc)
        header.append(le: UInt32(data.count))
        header.append(le: UInt32(data.count))
        header.append(le: UInt16(name.count))
        header.append(le: UInt16(0))
        if let localOffset {
            header.append(le: UInt16(0))
            header.append(le: UInt16(0))
            header.append(le: UInt16(0))
            header.append(le: UInt32(0))
            header.append(le: localOffset)
        }
        return header
    }

    private static func endRecord(count: Int, directorySize: Int, offset: Int) -> Data {
        var record = Data()
        record.append(le: endSignature)
        record.append(le: UInt16(0))
        record.append(le: UInt16(0))
        record.append(le: UInt16(count))
        record.append(le: UInt16(count))
        record.append(le: UInt32(directorySize))
        record.append(le: UInt32(offset))
        record.append(le: UInt16(0))
        return record
    }
}

extension Data {
    fileprivate mutating func append<T: FixedWidthInteger>(le value: T) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}
