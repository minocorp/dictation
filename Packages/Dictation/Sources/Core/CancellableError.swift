public protocol CancellableError: Error, Equatable, Sendable {
    static var cancelled: Self { get }
}
