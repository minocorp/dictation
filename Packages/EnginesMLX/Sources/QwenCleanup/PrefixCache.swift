import MLXLMCommon

internal struct PrefixCache {
    let tokens: [Int]
    let layers: [any KVCache]

    func suffix(of prompt: [Int]) -> [Int]? {
        guard prompt.count > tokens.count, prompt.starts(with: tokens) else { return nil }
        return Array(prompt[tokens.count...])
    }

    func copiedLayers() -> [any KVCache] {
        layers.map { $0.copy() }
    }
}
