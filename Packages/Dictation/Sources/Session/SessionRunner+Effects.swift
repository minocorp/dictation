import Core

extension SessionRunner {
    // swiftlint:disable:next cyclomatic_complexity
    func run(_ effect: Effect) {
        switch effect {
        case .startCapture(let id, let device): startCapture(id, device: device)
        case .stopCapture(let id): stopCapture(id)
        case .discardCapture(let id): discardCapture(id)
        case .discardAudio(let url): discardAudio(url)
        case .cancelWork(let id): cancelWork(id)
        case .readAudio(let id, let url): readAudio(id, url: url)
        case .readFocus(let id): readFocus(id)
        case .readSelection(let id): readSelection(id)
        case .transcribe(let segment, let languages):
            transcribe(segment, languages: languages)
        case .clean(let id, let index, let input): clean(id, index: index, input: input)
        case .edit(let id, let selection, let instruction):
            edit(id, selection: selection, instruction: instruction)
        case .insert(let id, let text, let focus): insert(id, text: text, focus: focus)
        case .copy(let text): copy(text)
        case .save(let item): save(item)
        case .update(let item): update(item)
        case .play(let sound): play(sound)
        case .startTimer(let timer, let duration): startTimer(timer, after: duration)
        case .cancelTimer(let timer): cancelTimer(timer)
        case .setTapPolicy(let policy): inputs.keys.setPolicy(policy)
        case .observeForLearning(let text, let focus):
            engines.learning.observe(inserted: text, into: focus)
        }
    }

    private func play(_ sound: Sound) {
        guard environment.preferences().sounds else { return }
        outputs.sounds.play(sound)
        TimingLog.mark("sound", "kind=\(sound)", for: liveCapture ?? state.active?.pending.id)
    }
}
