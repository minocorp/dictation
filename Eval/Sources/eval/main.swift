import EvalKit
import Foundation

do {
    let report = try await EvalCommand.run(Array(CommandLine.arguments.dropFirst()))
    FileHandle.standardOutput.write(Data((report.path + "\n").utf8))
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
