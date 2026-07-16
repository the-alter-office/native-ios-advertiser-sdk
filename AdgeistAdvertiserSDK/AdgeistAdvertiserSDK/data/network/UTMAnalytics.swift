import Foundation


struct AnalyticsRequestBody: Codable {
    //required fields
    let type: String
    let flowId: String
    let origin: String

    //optional fields
    let metaData: String?
    let platform: String?
    let additionalData: AdditionalData?
    let deviceType: String?
    let deviceBrand: String?
    let screenWidth: Int?
    let screenHeight: Int?
    let screenPixelRatio: Double?
    let screenDensity: Double?
    let coreArchitecture: String?
    let osName: String?
    let osVersion: String?
    let noOfProcessors: Int?
    let properties: [String: AnalyticsPropertyValue]?

    struct AdditionalData: Codable {
        let userId: String?
        let lastDeepLinkReferrer: String?
        let sessionDuration: Int?
        let totalSessionDuration: Int?
        let isEngaged: Bool?
        let device: DeviceInfo?
    }

    struct DeviceInfo: Codable {
        let deviceManufacturer: String?
        let deviceName: String?
        let deviceVersion: String?
        let screenWidth: Int?
        let screenHeight: Int?
        let screenDensity: Double?
        let osName: String?
        let osVersion: String?
        let noOfCPUs: Int?
        let ram: Int?
        let architecture: String?
    }
}

/// An event property value — the backend accepts only string, number, or boolean
enum AnalyticsPropertyValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    /// Bridges from untyped input (e.g. `[String: Any]`); nil for unsupported types
    init?(_ value: Any) {
        switch value {
        case let bool as Bool: self = .bool(bool)
        case let int as Int: self = .int(int)
        case let double as Double: self = .double(double)
        case let string as String: self = .string(string)
        default: return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected string, number, or boolean")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        }
    }
}

/// Handles sending UTM tracking and custom analytics events to the backend analytics API
class UTMAnalytics {
    private static let ANALYTICS_ENDPOINT = "/v2/ssp/analytics-event"


    //this should be computed once and reused for all events in the same app session
    private let flowId = UUID().uuidString


    private let deviceMeta = DeviceMeta.shared


    private let baseURL: String = Bundle.main.object(forInfoDictionaryKey: "BASE_API_URL") as? String ?? ""


    private lazy var analyticsUrl: URL? = URL(string: baseURL + UTMAnalytics.ANALYTICS_ENDPOINT)


    func buildEventPayload(eventName: String, properties: [String: Any]) -> AnalyticsRequestBody {
        let supportedProperties = properties.compactMapValues(AnalyticsPropertyValue.init)

        let droppedKeys = Set(properties.keys).subtracting(supportedProperties.keys)
        if !droppedKeys.isEmpty {
            Logger.log("Dropped unsupported property values for keys: \(droppedKeys.sorted().joined(separator: ", "))")
        }

        return AnalyticsRequestBody(
            type: eventName,
            flowId: flowId,
            origin: Bundle.main.bundleIdentifier ?? "Unknown",
            metaData: nil,
            platform: "IOS",
            additionalData: nil,
            deviceType: deviceMeta.deviceType,
            deviceBrand: deviceMeta.deviceManufacturer,
            screenWidth: deviceMeta.screenWidth,
            screenHeight: deviceMeta.screenHeight,
            screenPixelRatio: Double(deviceMeta.screenPixelRatio),
            screenDensity: Double(deviceMeta.screenDensity),
            coreArchitecture: deviceMeta.architecture,
            osName: deviceMeta.osName,
            osVersion: deviceMeta.osVersion,
            noOfProcessors: deviceMeta.noOfProcessors,
            properties: supportedProperties
        )
    }


    func sendEventToServer(eventName: String, properties: [String: Any], onComplete: ((Bool, String?) -> Void)? = nil) {
        guard let analyticsUrl = analyticsUrl else {
            Logger.log("Invalid analytics URL — check BASE_API_URL in Info.plist")
            onComplete?(false, "Invalid analytics URL")
            return
        }

        var request = URLRequest(url: analyticsUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let eventData = buildEventPayload(eventName: eventName, properties: properties)

        do {
            request.httpBody = try JSONEncoder().encode(eventData)
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
