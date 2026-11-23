public import Foundation

public enum EvalCommand {
    private enum Subcommand: String {
        case asr
        case cleanup
    }

    public static func run(_ rawArguments: [String]) async throws(EvalError) -> URL {
        let arguments = try Arguments(rawArguments)
        guard let subcommand = Subcommand(rawValue: arguments.command) else {
            throw .usage(Arguments.usage)
        }
        let root = RepositoryRoot.find()
        let markdown =
            switch subcommand {
            case .asr: try await ASRCommand(arguments: arguments, root: root).run()
            case .cleanup: try await CleanupCommand(arguments: arguments, root: root).run()
            }
        return try ReportFile.write(markdown, root: root)
    }
}
