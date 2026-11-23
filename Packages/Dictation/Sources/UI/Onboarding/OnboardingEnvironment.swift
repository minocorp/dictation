public import Core

public struct OnboardingEnvironment {
    let permissions: any PermissionMonitor
    let levels: @MainActor () -> AsyncStream<Float>
    let isBluetoothInput: @MainActor () -> Bool
    let recommendedModels: @MainActor () -> [ModelEntry]
    let finish: @MainActor () -> Void

    public init(
        permissions: any PermissionMonitor,
        levels: @escaping @MainActor () -> AsyncStream<Float>,
        isBluetoothInput: @escaping @MainActor () -> Bool,
        recommendedModels: @escaping @MainActor () -> [ModelEntry],
        finish: @escaping @MainActor () -> Void,
    ) {
        self.permissions = permissions
        self.levels = levels
        self.isBluetoothInput = isBluetoothInput
        self.recommendedModels = recommendedModels
        self.finish = finish
    }
}
