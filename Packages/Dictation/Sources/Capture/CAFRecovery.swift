public import Core
public import Foundation

public enum CAFRecovery {
    public static let malformedFileCode = -1

    public static func samples(at url: URL) throws(CaptureError) -> [Float] {
        let data: Data
        do {
            data = try Data(contentsOf: url, options: .mappedIfSafe)
        } catch {
            throw .diskWriteFailed(code: (error as NSError).code)
        }
        guard let range = sampleRange(in: data) else {
            throw .diskWriteFailed(code: malformedFileCode)
        }
        return data[range]
            .withUnsafeBytes { raw in
                var samples = [Float](repeating: 0, count: raw.count / CAFFormat.bytesPerSample)
                samples.withUnsafeMutableBytes { $0.copyMemory(from: raw) }
                return samples
            }
    }

    private static func sampleRange(in data: Data) -> Range<Int>? {
        guard data.starts(with: CAFFormat.fileTag), data.count >= CAFFormat.fileHeaderSize else {
            return nil
        }
        var offset = data.startIndex + CAFFormat.fileHeaderSize
        var hasFormat = false
        while offset + CAFFormat.chunkHeaderSize <= data.endIndex {
            let tag = data[offset..<offset + CAFFormat.tagSize]
            let declaredSize = data.bigEndianValue(at: offset + CAFFormat.tagSize, as: Int64.self)
            let payload = offset + CAFFormat.chunkHeaderSize
            if tag.elementsEqual(CAFFormat.descriptionTag) {
                guard declaredSize == CAFFormat.descriptionSize,
                    isExpectedFormat(data, at: payload)
                else { return nil }
                hasFormat = true
            } else if tag.elementsEqual(CAFFormat.dataTag) {
                guard hasFormat else { return nil }
                return dataRange(data, payload: payload, declaredSize: declaredSize)
            }
            guard declaredSize >= 0, declaredSize <= Int64(data.endIndex - payload) else {
                return nil
            }
            offset = payload + Int(declaredSize)
        }
        return nil
    }

    private static func dataRange(_ data: Data, payload: Int, declaredSize: Int64) -> Range<Int> {
        let available = data.endIndex - payload
        let declared = declaredSize < 0 ? available : Int(min(declaredSize, Int64(available)))
        let sampleBytes = max(declared - CAFFormat.editCountSize, 0)
        let start = payload + CAFFormat.editCountSize
        return start..<start + sampleBytes / CAFFormat.bytesPerSample * CAFFormat.bytesPerSample
    }

    private static func isExpectedFormat(_ data: Data, at start: Int) -> Bool {
        guard data.endIndex - start >= CAFFormat.descriptionSize else { return false }
        return Double(bitPattern: data.bigEndianValue(at: start, as: UInt64.self))
            == CAFFormat.sampleRate
            && data[start + 8..<start + 12].elementsEqual(CAFFormat.linearPCMTag)
            && data.bigEndianValue(at: start + 12, as: UInt32.self)
                == CAFFormat.floatLittleEndianFlags
            && data.bigEndianValue(at: start + 24, as: UInt32.self) == 1
            && data.bigEndianValue(at: start + 28, as: UInt32.self)
                == UInt32(CAFFormat.bytesPerSample * 8)
    }
}
