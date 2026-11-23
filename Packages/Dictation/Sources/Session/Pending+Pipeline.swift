import Core
import Foundation

extension Pending {
    mutating func advance(languages: [Locale]) -> [Effect] {
        guard failure == nil, stage != .waiting, delivery != .canceled else { return [] }
        var effects: [Effect] = []
        for index in orderedIndices {
            effects += step(at: index, languages: languages)
        }
        return effects + rewriteIfReady()
    }

    private mutating func step(at index: Int, languages: [Locale]) -> [Effect] {
        switch segments[index] {
        case .recorded(let segment): transcribeStep(segment, languages: languages)
        case .transcribed(let raw): cleanStep(index, raw: raw)
        case .transcribing, .cleaning, .cleaned, .none: []
        }
    }

    private mutating func transcribeStep(_ segment: Segment, languages: [Locale]) -> [Effect] {
        segments[segment.index] = .transcribing
        return [.transcribe(segment, languages: languages)]
    }

    private mutating func cleanStep(_ index: Int, raw: String) -> [Effect] {
        guard !raw.isEmpty else {
            segments[index] = .cleaned(raw: raw, text: "")
            return []
        }
        switch kind {
        case .editPending:
            return []
        case .edit:
            segments[index] = .cleaned(raw: raw, text: raw)
            return []
        case .dictation:
            return requestCleaning(index, raw: raw)
        }
    }

    private mutating func requestCleaning(_ index: Int, raw: String) -> [Effect] {
        guard index == 0 || segments[index - 1]?.cleanedText != nil else { return [] }
        let hasLaterSegment = segments.keys.contains { $0 > index }
        guard hasLaterSegment || segmentsEnded else { return [] }
        segments[index] = .cleaning(raw: raw)
        return [
            .clean(
                id,
                index: index,
                input: CleanInput(
                    text: raw,
                    contextBefore: contextBefore(index: index),
                    isFinalSegment: !hasLaterSegment,
                ),
            )
        ]
    }

    private mutating func rewriteIfReady() -> [Effect] {
        guard case .edit(let selection) = kind, rewrite == .notStarted, segmentsEnded,
            allSegmentsCleaned, !cleanedTranscript.isEmpty
        else { return [] }
        rewrite = .running
        return [.edit(id, selection: selection, instruction: cleanedTranscript)]
    }
}
