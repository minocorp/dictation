import SwiftUI

internal struct OnboardingStepBadge: View {
    let number: Int
    let isActive: Bool
    let isComplete: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text(number, format: .number)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isActive ? Color.white : Color.secondary)
            }
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }

    private var fill: Color {
        if isComplete { return .green }
        return isActive ? .accentColor : Color.primary.opacity(0.08)
    }
}
