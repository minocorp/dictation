public protocol WordStore: Sendable {
    func all() async throws(StoreError) -> [Word]
    func add(_ word: Word) async throws(StoreError)
    func remove(text: String) async throws(StoreError)
    func recordCorrection(
        from original: String,
        to corrected: String,
    ) async throws(StoreError)
        -> Word?
}
