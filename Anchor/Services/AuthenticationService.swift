import Foundation
@preconcurrency import LocalAuthentication

enum BiometryKind {
    case none
    case touchID
    case faceID
}

@MainActor
struct AuthenticationService {
    func biometryKind() -> BiometryKind {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            return false
        }
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Anchor") { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
