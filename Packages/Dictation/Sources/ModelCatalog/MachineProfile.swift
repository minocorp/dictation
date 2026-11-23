import Core
public import Foundation

public struct MachineProfile: Hashable, Sendable {
    public let ramGB: Int
    public let languages: [Locale]

    public init(ramGB: Int, languages: [Locale]) {
        self.ramGB = ramGB
        self.languages = languages
    }

    public static func current(languages: [Locale]) -> MachineProfile {
        MachineProfile(
            ramGB: MachineMemory.gigabytes,
            languages: languages,
        )
    }
}
