import Core

extension HistoryItem {
    func replacingApp(_ target: TargetApp?) -> HistoryItem {
        HistoryItem(
            id: id,
            date: date,
            appBundleID: target?.bundleID ?? "",
            appName: target?.name ?? "",
            kind: kind,
            rawText: rawText,
            finalText: finalText,
            instruction: instruction,
            audioURL: audioURL,
            duration: duration,
            status: status,
        )
    }
}
