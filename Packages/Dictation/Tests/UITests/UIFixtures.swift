import Core
import Foundation

internal enum UIFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    static func item(
        id: DictationID = DictationID(),
        date: Date = referenceDate,
        raw: String = "um hello",
        final: String = "Hello.",
        audioURL: URL? = nil,
        status: HistoryItem.Status = .inserted,
    ) -> HistoryItem {
        HistoryItem(
            id: id,
            date: date,
            appBundleID: "com.apple.TextEdit",
            appName: "TextEdit",
            kind: .dictation,
            rawText: raw,
            finalText: final,
            instruction: nil,
            audioURL: audioURL,
            duration: .seconds(2),
            status: status,
        )
    }

    static func entry(id: String, stage: ModelStage, bytes: Int = 1_000) -> ModelEntry {
        ModelEntry(
            id: id,
            stage: stage,
            displayName: id,
            family: "test",
            repo: "test/\(id)",
            revision: "rev",
            observedRevision: nil,
            format: .mlxSafetensors,
            quant: "4bit",
            license: "Apache-2.0",
            licenseVerified: true,
            languages: ["en"],
            minRAMGB: 8,
            downloadBytes: bytes,
            files: [],
            defaultFor: [],
            runtime: nil,
            verified: [],
            unverified: nil,
        )
    }

    static func event(
        _ phase: RawKeyEvent.Phase = .pressed,
        code: UInt16,
        modifiers: KeyModifiers = [],
    ) -> RawKeyEvent {
        RawKeyEvent(phase: phase, trigger: .key(code: code), modifiers: modifiers)
    }
}
