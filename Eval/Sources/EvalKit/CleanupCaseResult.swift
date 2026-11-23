internal import Cleanup

internal struct CleanupCaseResult {
    let testCase: CleanupCase
    let final: String
    let source: CleanupSource
    let rawOutput: String?
    let modelDuration: Duration?
    let pipelineDuration: Duration

    var wasModelCalled: Bool {
        switch source {
        case .gateSkipped, .disabled: false
        case .model, .fallback: true
        }
    }

    var passedGuards: Bool { source == .model }
}
