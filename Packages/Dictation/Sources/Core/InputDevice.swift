public enum InputDevice: Codable, Hashable, Sendable {
    case builtIn
    case device(uid: String)
}
