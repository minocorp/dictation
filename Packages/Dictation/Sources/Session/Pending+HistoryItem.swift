import Core
import Foundation

extension Pending {
    func historyItem(
        finalText: String,
        status: HistoryItem.Status,
        keepsAudio: Bool = true,
    ) -> HistoryItem {
        HistoryItem(
            id: existing?.id ?? id,
            date: existing?.date ?? date,
            appBundleID: target?.target.bundleID ?? existing?.appBundleID ?? "",
            appName: target?.target.name ?? existing?.appName ?? "",
            kind: historyKind,
            rawText: historyRawText,
            finalText: finalText,
            instruction: historyInstruction,
            audioURL: keepsAudio ? audioURL : nil,
            duration: duration,
            status: status,
        )
    }

    private var historyKind: HistoryItem.Kind {
        switch kind {
        case .dictation: .dictation
        case .edit, .editPending: .edit
        }
    }

    private var historyRawText: String {
        guard case .edit(let selection) = kind else { return rawTranscript }
        return selection
    }

    private var historyInstruction: String? {
        guard case .edit = kind else { return nil }
        return cleanedTranscript
    }

    private var duration: Duration {
        guard sampleCount > 0 else { return existing?.duration ?? .zero }
        return .milliseconds(sampleCount * 1_000 / AudioChunk.sampleRate)
    }
}
