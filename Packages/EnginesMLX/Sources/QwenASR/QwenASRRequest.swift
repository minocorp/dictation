internal struct QwenASRRequest: Sendable {
    let audio: [Float]
    let context: String
    let language: String?
}
