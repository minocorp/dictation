@testable import Context

internal struct FakeSecureInputSource: SecureInputSource {
    var isActive = false

    func isSecureInputActive() -> Bool { isActive }
}
