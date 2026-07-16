import Foundation

public final class AdgeistCore {
    // auto initialization of AdgeistCore singleton instance
    public static let shared = AdgeistCore()

    private let utmTracker = UTMTracker()

    private init() {}

    public func startAttributionTracking(url : URL? = nil) {
        utmTracker.startAttributionTracking(url: url)
    }

    public func trackConversionEvent(
        eventName: String,
        properties: [String: Any] = [:],
        onComplete: ((Bool, String?) -> Void)? = nil
    ) {
        utmTracker.trackConversionEvent(
            eventName: eventName,
            properties: properties,
            onComplete: onComplete
        )
    }
}
