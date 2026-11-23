@testable import Context
import Core

internal struct FakeFrontmostAppSource: FrontmostAppSource {
    var app: TargetApp?

    func frontmost() -> TargetApp? { app }
}
