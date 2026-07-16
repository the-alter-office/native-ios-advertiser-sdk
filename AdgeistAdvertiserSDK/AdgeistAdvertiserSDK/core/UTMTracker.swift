import Foundation


final class UTMTracker {

    let analytics = UTMAnalytics()

    var utmMetaData: String? = nil

    init() {}
    
   
    func startAttributionTracking(url: URL? = nil) {
        // Implementation for starting attribution tracking
    if let url = url {
            // Handle the provided URL for attribution tracking
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []
            for queryItem in queryItems {
                if queryItem.name == "utm_data" {
                    utmMetaData = queryItem.value

                    Logger.log("UTM Data found: \(utmMetaData ?? "")")
                }
            }
    }

    analytics.sendEventToServer(eventName: "VISIT", properties: ["utm_data": utmMetaData ]) { success, errorMessage in
            if success {
                Logger.log("Attribution tracking event sent successfully")
            } else {
                Logger.log("Failed to send attribution tracking event: \(errorMessage ?? "Unknown error")")
            }
        }
    }   



    func trackConversionEvent(
        eventName: String,
        properties: [String: Any] = [:],
        onComplete: ((Bool, String?) -> Void)? = nil
    ) {
        analytics.sendEventToServer(eventName: eventName, properties: properties) { success, errorMessage in
            if success {
                Logger.log("Conversion event '\(eventName)' sent successfully")
            } else {
                Logger.log("Failed to send conversion event '\(eventName)': \(errorMessage ?? "Unknown error")")
            }
            onComplete?(success, errorMessage)
        }

    }
}