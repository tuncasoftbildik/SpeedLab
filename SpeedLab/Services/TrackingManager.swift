import Foundation
import AppTrackingTransparency
import AdSupport

/// Wraps App Tracking Transparency authorization request.
/// Apple requires the ATT prompt before collecting IDFA for tracking
/// (we use Google AdMob which may use IDFA for personalized ads).
enum TrackingManager {
    /// Request ATT authorization if not yet determined.
    /// Safe to call multiple times — iOS shows the prompt only once.
    /// Must be invoked while the app is in the foreground/active state.
    static func requestAuthorizationIfNeeded() async -> ATTrackingManager.AuthorizationStatus {
        // If user already responded, return current status without prompting.
        let current = ATTrackingManager.trackingAuthorizationStatus
        if current != .notDetermined {
            return current
        }
        return await ATTrackingManager.requestTrackingAuthorization()
    }
}
