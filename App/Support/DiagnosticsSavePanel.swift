import AppKit
import UniformTypeIdentifiers

@MainActor
internal enum DiagnosticsSavePanel {
    static func chooseDestination() -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = "Diagnostics.zip"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
