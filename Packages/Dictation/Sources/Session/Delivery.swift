internal enum Delivery: Equatable, Sendable {
    case insert
    case keepAsLast
    case canceled
    case background
}
