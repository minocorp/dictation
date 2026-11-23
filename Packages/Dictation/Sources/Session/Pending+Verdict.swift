extension Pending {
    var verdict: Verdict? {
        guard isAudioClosed else { return nil }
        if let failure { return .failed(failure) }
        guard segmentsEnded, allSegmentsCleaned else { return nil }
        switch kind {
        case .editPending: return nil
        case .dictation: return textVerdict
        case .edit: return editVerdict
        }
    }

    private var textVerdict: Verdict {
        let text = cleanedTranscript
        return text.isEmpty ? .noSpeech : .text(text)
    }

    private var editVerdict: Verdict? {
        guard !cleanedTranscript.isEmpty else { return .noSpeech }
        switch rewrite {
        case .notStarted, .running: return nil
        case .done(.success(let text)): return .text(text)
        case .done(.failure(let error)): return .failed(.cleanup(error))
        }
    }
}
