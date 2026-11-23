import ApplicationServices
import Foundation

internal enum TapThread {
    private static let runLoopSlice: CFTimeInterval = 1

    static func run(context: TapContext, handshake: TapHandshake, exited: DispatchSemaphore) {
        let retained = Unmanaged.passRetained(context)
        switch context.installTaps(userInfo: retained.toOpaque()) {
        case .failure(let error):
            handshake.complete(.failure(error))
        case .success:
            handshake.complete(.success(()))
            while !context.isStopRequested {
                CFRunLoopRunInMode(.defaultMode, runLoopSlice, false)
            }
            context.releasePorts()
        }
        retained.release()
        exited.signal()
    }
}
