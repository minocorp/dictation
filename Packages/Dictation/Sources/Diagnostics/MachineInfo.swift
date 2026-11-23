import Core
import Foundation

public struct MachineInfo: Codable, Hashable, Sendable {
    public let osVersion: String
    public let chip: String
    public let ramGB: Int

    public init(osVersion: String, chip: String, ramGB: Int) {
        self.osVersion = osVersion
        self.chip = chip
        self.ramGB = ramGB
    }

    public static func current() -> MachineInfo {
        MachineInfo(
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            chip: chipName(),
            ramGB: MachineMemory.gigabytes,
        )
    }

    private static func chipName() -> String {
        var size = 0
        guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 0 else {
            return "unknown"
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0 else {
            return "unknown"
        }
        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(bytes: bytes, encoding: .utf8) ?? "unknown"
    }
}
