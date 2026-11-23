import Foundation

extension UIString {
    static let modelsSpeech = resource("modelsSpeech")
    static let modelsCleanup = resource("modelsCleanup")
    static let modelsBuiltInSpeechName = resource("modelsBuiltInSpeechName")
    static let modelsBuiltInCleanupName = resource("modelsBuiltInCleanupName")
    static let modelsBuiltIn = resource("modelsBuiltIn")
    static let modelsRecommended = resource("modelsRecommended")
    static func modelsLicense(_ name: String) -> LocalizedStringResource {
        resource(interpolated: "modelsLicenseName \(name)")
    }
    static let modelsStateNotDownloaded = resource("modelsStateNotDownloaded")
    static let modelsStateWaiting = resource("modelsStateWaiting")
    static let modelsStateDownloading = resource("modelsStateDownloading")
    static let modelsStateVerifying = resource("modelsStateVerifying")
    static let modelsStateReady = resource("modelsStateReady")
    static let modelsStateFailed = resource("modelsStateFailed")
    static let modelsErrorDiskSpace = resource("modelsErrorDiskSpace")
    static let modelsErrorNetwork = resource("modelsErrorNetwork")
    static let modelsErrorVerification = resource("modelsErrorVerification")
    static let modelsErrorFile = resource("modelsErrorFile")
    static let modelsErrorLoad = resource("modelsErrorLoad")
    static let modelsErrorUnknown = resource("modelsErrorUnknown")
    static let modelsDownload = resource("modelsDownload")
    static let modelsCancelDownload = resource("modelsCancelDownload")
    static let modelsAllowConstrained = resource("modelsAllowConstrained")
    static let modelsDelete = resource("modelsDelete")
    static let modelsDeleteAll = resource("modelsDeleteAll")
    static let modelsDeleteAllTitle = resource("modelsDeleteAllTitle")
    static let modelsDeleteAllConfirm = resource("modelsDeleteAllConfirm")
    static let modelsDeleteAllCancel = resource("modelsDeleteAllCancel")
}
