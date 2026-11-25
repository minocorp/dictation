import Foundation
public import os

extension Logger {
    public init(dictationCategory category: String) {
        self.init(subsystem: Bundle.main.bundleIdentifier ?? "", category: category)
    }
}
