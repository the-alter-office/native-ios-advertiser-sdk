import Foundation

/// Handles sending UTM tracking and custom analytics events to the backend analytics API
package class UTMAnalytics {
    private static let ANALYTICS_ENDPOINT = "/v2/ssp/analytics-event"


    //this should be computed once and reused for all events in the same app session
    private let flowId = UUID().uuidString


    guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "BASE_API_URL") as? String else {
        fatalError("BASE_API_URL not found in Info.plist")
    }

    private let analyticsUrl: URL = URL(string: baseUrl + UTMAnalytics.ANALYTICS_ENDPOINT)!


    func sendEventToServer(eventName:Sting, properties: [String: Any], onComplete: ((Bool, String?) -> Void)? = nil) {
        var request = URLRequest(url: analyticsUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let constants: [String: Any] = [
            "flowId": flowId,
            "platform" : "IOS",
            "origin" : Bundle.main.bundleIdentifier ?? "Unknown",
        ]

        let eventData: [String: Any] = [
            "type": eventName,
            "properties": properties
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventData, options: [])
            request.httpBody = jsonData
        } catch {
            Logger.log("Failed to serialize event data to JSON: \(error)")
            onComplete?(false, "Failed to serialize event data to JSON")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.log("Failed to send analytics event: \(error)")
                onComplete?(false, error.localizedDescription)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.log("Invalid response received from the server")
                onComplete?(false, "Invalid response received from the server")
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                Logger.log("Analytics event sent successfully")
                onComplete?(true, nil)
            } else {
                Logger.log("Failed to send analytics event. Status code: \(httpResponse.statusCode)")
                onComplete?(false, "Failed to send analytics event. Status code: \(httpResponse.statusCode)")
            }
        }

        task.resume()
    }
}
