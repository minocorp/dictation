internal struct LicenseNotice: Hashable, Identifiable {
    let name: String
    let license: String

    var id: String { name }

    static let thirdParty = [
        LicenseNotice(name: "mlx-swift", license: "MIT"),
        LicenseNotice(name: "mlx-swift-lm", license: "MIT"),
        LicenseNotice(name: "mlx-audio-swift", license: "MIT"),
        LicenseNotice(name: "FluidAudio", license: "Apache-2.0"),
        LicenseNotice(name: "GRDB", license: "MIT"),
        LicenseNotice(name: "Sparkle", license: "MIT"),
    ]
}
