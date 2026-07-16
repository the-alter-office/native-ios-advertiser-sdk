import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Tracks per-session engagement state: when the session (VISIT) started,
/// how long since the last tracked event, and whether the user has engaged
final class SessionTracker {

    /// Point-in-time view of the session, attached to every analytics request
    struct Snapshot {
        /// Milliseconds since the last tracked event
        let sessionDuration: Int
        /// Milliseconds since the VISIT event / session start
        let totalSessionDuration: Int
        /// True once the user has performed any action this session
        let isEngaged: Bool
    }

    static let shared = SessionTracker()

    /// Called when the app moves to the background so the owner can flush a
    /// SESSION_DURATION event. Invoke the completion once the send finishes
    /// so the background task can end.
    var onSessionEnd: ((Snapshot, @escaping () -> Void) -> Void)? {
        get { queue.sync { _onSessionEnd } }
        set { queue.sync { _onSessionEnd = newValue } }
    }

    /// All mutable state is confined to this queue
    private let queue = DispatchQueue(label: "com.adgeist.session-tracker")

    /// Injectable so tests can control time
    private let now: () -> TimeInterval

    private var _onSessionEnd: ((Snapshot, @escaping () -> Void) -> Void)?
    private var visitTimestamp: TimeInterval
    private var sessionDurationStart: TimeInterval
    private var isEngaged = false

    init(clock: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        self.now = clock
        let start = clock()
        self.visitTimestamp = start
        self.sessionDurationStart = start
        observeAppLifecycle()
    }

    /// Marks the start of a session; call when the VISIT event is sent
    func startSession() {
        queue.sync {
            let start = now()
            visitTimestamp = start
            sessionDurationStart = start
            isEngaged = false
        }
    }

    /// Records a user action (screen change, button click, custom event):
    /// flips `isEngaged` to true and resets the per-event timer.
    /// Returns the durations measured up to this action.
    func recordEngagement() -> Snapshot {
        queue.sync {
            let current = now()
            let snapshot = Snapshot(
                sessionDuration: millis(from: sessionDurationStart, to: current),
                totalSessionDuration: millis(from: visitTimestamp, to: current),
                isEngaged: true
            )
            isEngaged = true
            sessionDurationStart = current
            return snapshot
        }
    }

    /// Current values without marking engagement (e.g. for the VISIT event itself)
    func snapshot() -> Snapshot {
        queue.sync { unsafeSnapshot(at: now()) }
    }

    /// Snapshot for a session-end (SESSION_DURATION) event: keeps the current
    /// `isEngaged` value but resets the per-event timer, since a duration
    /// event is being sent
    func flushSnapshot() -> Snapshot {
        queue.sync {
            let current = now()
            let snapshot = unsafeSnapshot(at: current)
            sessionDurationStart = current
            return snapshot
        }
    }

    /// Must be called on `queue`
    private func unsafeSnapshot(at current: TimeInterval) -> Snapshot {
        Snapshot(
            sessionDuration: millis(from: sessionDurationStart, to: current),
            totalSessionDuration: millis(from: visitTimestamp, to: current),
            isEngaged: isEngaged
        )
    }

    private func millis(from start: TimeInterval, to end: TimeInterval) -> Int {
        max(0, Int((end - start) * 1000))
    }

    // MARK: - App lifecycle

    private func observeAppLifecycle() {
        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    @objc private func appDidEnterBackground() {
        guard let handler = onSessionEnd else { return }

        let snapshot = flushSnapshot()

        // Keep the app alive long enough for the network request to finish
        var taskId: UIBackgroundTaskIdentifier = .invalid
        let endTask = {
            if taskId != .invalid {
                UIApplication.shared.endBackgroundTask(taskId)
                taskId = .invalid
            }
        }
        taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: endTask)

        handler(snapshot, endTask)
    }
    #endif
}
