public enum Gesture: Hashable, Sendable {
    case pressBegan
    case released
    case handsFreeBegan
    case handsFreeEnded
    case editBegan
    case cancel
    case abandon
    case restore
    case stop
    case pasteLast
}
