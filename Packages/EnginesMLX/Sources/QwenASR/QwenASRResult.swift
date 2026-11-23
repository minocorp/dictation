internal struct QwenASRResult: Sendable {
    let text: String
    let detectedLanguage: String?
    let promptTokens: Int
    let generatedTokens: Int
}
