import Foundation

public enum MachineMemory {
    private static let bytesPerGB: UInt64 = 1_073_741_824

    public static var gigabytes: Int {
        Int(ProcessInfo.processInfo.physicalMemory / bytesPerGB)
    }
}
