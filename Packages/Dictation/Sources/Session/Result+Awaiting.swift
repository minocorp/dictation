extension Result {
    static func awaiting(
        isolation: isolated (any Actor)? = #isolation,
        _ body: () async throws(Failure) -> Success,
    ) async -> Result {
        do throws(Failure) {
            return .success(try await body())
        } catch {
            return .failure(error)
        }
    }

    var value: Success? {
        switch self {
        case .success(let value): value
        case .failure: nil
        }
    }
}
