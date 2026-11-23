import Carbon

internal struct SystemSecureInputSource: SecureInputSource {
    func isSecureInputActive() -> Bool {
        IsSecureEventInputEnabled()
    }
}
