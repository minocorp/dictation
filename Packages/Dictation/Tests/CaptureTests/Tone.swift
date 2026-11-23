import Foundation

internal enum Tone {
    static func mono(
        frequency: Double,
        rate: Double,
        seconds: Double,
        amplitude: Float = 0.8,
    )
        -> [Float]
    {
        (0..<Int(rate * seconds))
            .map {
                amplitude * Float(sin(2 * .pi * frequency * Double($0) / rate))
            }
    }

    static func interleaved(
        frequency: Double,
        rate: Double,
        channels: Int,
        seconds: Double,
    ) -> [Float] {
        mono(frequency: frequency, rate: rate, seconds: seconds)
            .flatMap {
                Array(repeating: $0, count: channels)
            }
    }

    static func power(of samples: [Float], at frequency: Double, rate: Double) -> Float {
        var real = 0.0
        var imaginary = 0.0
        for (index, sample) in samples.enumerated() {
            let phase = 2 * Double.pi * frequency * Double(index) / rate
            real += Double(sample) * cos(phase)
            imaginary += Double(sample) * sin(phase)
        }
        let scale = 2 / Double(samples.count)
        return Float(
            ((real * scale) * (real * scale)) + ((imaginary * scale) * (imaginary * scale))
        )
    }
}
