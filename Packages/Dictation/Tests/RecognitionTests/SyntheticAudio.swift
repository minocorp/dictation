import Core
@testable import Recognition

internal enum SyntheticAudio {
    struct Piece: Sendable {
        let isSpeech: Bool
        let milliseconds: Int

        static func speech(_ milliseconds: Int) -> Piece {
            Piece(isSpeech: true, milliseconds: milliseconds)
        }

        static func silence(_ milliseconds: Int) -> Piece {
            Piece(isSpeech: false, milliseconds: milliseconds)
        }
    }

    static func samples(_ pieces: [Piece]) -> [Float] {
        var result: [Float] = []
        for piece in pieces {
            let count = SegmentationConfiguration.samples(milliseconds: piece.milliseconds)
            let offset = result.count
            result += (0..<count)
                .map { index in
                    piece.isSpeech ? 0.5 * sinPhase(offset + index) : 0
                }
        }
        return result
    }

    static func chunks(_ samples: [Float], size: Int) -> [AudioChunk] {
        stride(from: 0, to: samples.count, by: size)
            .map {
                AudioChunk(
                    samples: Array(samples[$0..<min($0 + size, samples.count)]),
                    startSample: $0,
                )
            }
    }

    private static func sinPhase(_ index: Int) -> Float {
        Float(index % 36 < 18 ? 1 : -1)
    }
}
