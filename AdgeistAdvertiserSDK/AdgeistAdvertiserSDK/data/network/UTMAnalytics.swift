import Foundation

/// Handles sending UTM tracking and custom analytics events to the backend analytics API
public class UTMAnalytics {
    private let bidRequestBackendDomain: String
    private let deviceMeta: DeviceMeta
    private let deviceIdentifier: DeviceIdentifier
    private static let TAG = "UTMAnalytics"
    private static let ANALYTICS_ENDPOINT = "/v2/ssp/analytics-event"

    init(bidRequestBackendDomain: String, deviceMeta: DeviceMeta, deviceIdentifier: DeviceIdentifier) {
        self.bidRequestBackendDomain = bidRequestBackendDomain
        self.deviceMeta = deviceMeta
        self.deviceIdentifier = deviceIdentifier
    }

    // MARK: - Public API

    /// Send UTM parameters to backend API
    public func sendUtmData(
        _ params: UTMParameters,
        eventType: String = EventTypes.VISIT,
        additionalData: [String: Any]? = nil,
        onComplete: ((Bool, String?) -> Void)? = nil
    ) {
        sendEvent(params: params, eventType: eventType, additionalData: additionalData, onComplete: onComplete)
    }

    /// Send an install attribution event (first launch only)
    public func sendInstallAttributionEvent(utmParameters: UTMParameters?) {
        if let params = utmParameters {
            sendUtmData(params, eventType: EventTypes.INSTALL) { success, error in
                let attribution = "attributed"
                if success {
                    print("\(Self.TAG): INSTALL event sent - \(attribution)")
                } else {
                    print("\(Self.TAG): INSTALL event failed - \(attribution), error: \(error ?? "unknown")")
                }
            }
        }
    }

    /// Track a custom conversion event with an arbitrary set of properties
    /// - Parameters:
    ///   - eventName: Name of the event (sent as `type`)
    ///   - properties: Key/value pairs (String, Number or Bool values)
    ///   - utmParameters: Current UTM parameters used to populate the shared context fields
    public func trackConversionEvent(
        eventName: String,
        properties: [String: Any] = [:],
        utmParameters: UTMParameters? = nil,
        onComplete: ((Bool, String?) -> Void)? = nil
    ) {
        sendEvent(
            params: utmParameters ?? UTMParameters(),
            eventType: eventName,
            properties: properties,
            onComplete: onComplete
        )
    }

    // MARK: - Private Helpers

    /// Resolves the device fingerprint, builds the payload and POSTs it to the analytics endpoint.
    /// Shared by every event type so the request/build logic lives in one place.
    private func sendEvent(
        params: UTMParameters,
        eventType: String,
        additionalData: [String: Any]? = nil,
        properties: [String: Any]? = nil,
        onComplete: ((Bool, String?) -> Void)? = nil
    ) {
        deviceIdentifier.getDeviceIdentifier { [weak self] fingerprint in
            guard let self = self else { return }
            DispatchQueue.global(qos: .background).async {
                let payload = self.buildPayload(
                    params: params,
                    eventType: eventType,
                    deviceFingerPrint: fingerprint,
                    additionalData: additionalData,
                    properties: properties
                )
                self.post(payload: payload, onComplete: onComplete)
            }
        }
    }

    /// Build the JSON payload shared by all analytics events.
    private func buildPayload(
        params: UTMParameters,
        eventType: String,
        deviceFingerPrint: String,
        additionalData: [String: Any]? = nil,
        properties: [String: Any]? = nil
    ) -> [String: Any] {
        let dims = deviceMeta.getScreenDimensions()

        // Fields that always have a meaningful value on iOS.
        var payload: [String: Any] = [
            "metaData": params.data ?? "",
            "platform": "IOS",
            "flowId": params.sessionId ?? "",
            "type": eventType,
            "origin": params.source ?? "",
            "deviceFingerPrint": deviceFingerPrint,
            "fingerPrintType": "IDFA",
            "deviceType": deviceMeta.getDeviceType(),
            "deviceBrand": deviceMeta.getDeviceBrand(),
            "screenWidth": dims["width"] ?? 0,
            "screenHeight": dims["height"] ?? 0,
            "screenPixelRatio": deviceMeta.getScreenPixelRatio(),
            "screenDensity": deviceMeta.getScreenDensity(),
            "osName": deviceMeta.getOperatingSystem(),
            "osVersion": deviceMeta.getOSVersionName(),
            "noOfProcessors": deviceMeta.getAvailableProcessors(),
            "isTouchScreenCapable": deviceMeta.isTouchScreenAvailable(),
            "isNFCCapable": deviceMeta.isNfcCapable(),
            "isGPUCapable": deviceMeta.isGpuCapable(),
            "isVRCapable": deviceMeta.isVrCapable(),
            "isScreenReaderEnabled": deviceMeta.isScreenReaderPresent()
        ]

        // Fields with no guaranteed iOS equivalent — only sent when a value is available.
        // (pageUrl, userAgent, browserName/Version, webglRenderer, isNFCEnabled are omitted on iOS.)
        if let architecture = deviceMeta.getCpuType() {
            payload["architecture"] = architecture
        }
        if let networkType = deviceMeta.getNetworkType() {
            payload["networkType"] = networkType
        }

        if let additionalData = additionalData {
            payload["additionalData"] = additionalData
        }
        if let properties = properties {
            payload["properties"] = properties
        }

        return payload
    }

    /// POST a prepared payload to the analytics endpoint.
    private func post(payload: [String: Any], onComplete: ((Bool, String?) -> Void)?) {
        do {
            let url = "\(bidRequestBackendDomain)\(Self.ANALYTICS_ENDPOINT)"
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])

            guard let requestUrl = URL(string: url) else {
                let errorMessage = "Invalid URL: \(url)"
                print("\(Self.TAG): \(errorMessage)")
                onComplete?(false, errorMessage)
                return
            }

            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    let errorMessage = "Failed to send analytics event to backend: \(error.localizedDescription)"
                    print("\(Self.TAG): \(errorMessage)")
                    onComplete?(false, errorMessage)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    let errorMessage = "Invalid response type"
                    print("\(Self.TAG): \(errorMessage)")
                    onComplete?(false, errorMessage)
                    return
                }

                if httpResponse.statusCode != 200 {
                    let errorBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No error message"
                    let errorMessage = "Analytics API request failed with code: \(httpResponse.statusCode), message: \(errorBody)"
                    print("\(Self.TAG): \(errorMessage)")
                    onComplete?(false, errorMessage)
                    return
                }

                print("\(Self.TAG): Analytics event sent successfully to backend")
                onComplete?(true, nil)
            }

            task.resume()

        } catch {
            let errorMessage = "Error sending analytics event to backend: \(error.localizedDescription)"
            print("\(Self.TAG): \(errorMessage)")
            onComplete?(false, errorMessage)
        }
    }
}
