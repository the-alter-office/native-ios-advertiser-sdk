import Foundation
import AppTrackingTransparency

public final class AdgeistCore {
    public static let shared = AdgeistCore()

    public let bidRequestBackendDomain: String
    public let packageOrBundleID: String
    public let version: String

    public let deviceIdentifier: DeviceIdentifier
    public let networkUtils: NetworkUtils
    public let deviceMeta: DeviceMeta
    public let utmTracker: UTMTracker

    private static func getDefaultDomain() -> String {
        let frameworkBundle = Bundle(for: AdgeistCore.self)
                        
        if let baseURL = frameworkBundle.object(forInfoDictionaryKey: "BASE_API_URL") as? String {
            print("DEBUG: Using config domain for AdgeistCore: \(baseURL)")
            return baseURL
        }

        return "https://beta.v2.bg-services.adgeist.ai"
    }

    private init() {
        self.bidRequestBackendDomain = AdgeistCore.getDefaultDomain()
        
        self.deviceIdentifier = DeviceIdentifier()
        self.networkUtils = NetworkUtils()
        self.deviceMeta = DeviceMeta()
        
        self.utmTracker = UTMTracker.shared

        let bundle = Bundle.main

        self.packageOrBundleID = bundle.bundleIdentifier ?? ""
        
        // Get version from framework bundle
        let frameworkBundle = Bundle(for: AdgeistCore.self)
        let versionName = frameworkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let versionSuffix = frameworkBundle.object(forInfoDictionaryKey: "VERSION_SUFFIX") as? String ?? ""
        self.version = "IOS-\(versionName)-\(versionSuffix)"
        
        // Initialize UTM analytics with backend domain
        self.utmTracker.initializeAnalytics(bidRequestBackendDomain: self.bidRequestBackendDomain)
        
        // Track first install UTM parameters
        self.utmTracker.initializeInstallReferrer()
        
        self.requestTrackingPermission()
    }
    
    @discardableResult
    public static func initialize() -> AdgeistCore {
        return shared
    }
    
    public static func getInstance() -> AdgeistCore {
        return shared
    }
    
    /// Track UTM parameters from a deeplink URL
    /// Call this when your app handles a deeplink or universal link
    public func trackDeeplink(url: URL) {
        utmTracker.trackFromDeeplink(url: url)
    }
    
    /// Track UTM parameters from a universal link URL
    /// Call this when your app handles a universal link
    public func trackUniversalLink(url: URL) {
        utmTracker.trackFromDeeplink(url: url)
    }
    
    /// Get current UTM tracking data
    public func getUTMData() -> [String: Any] {
        return utmTracker.getUtmParameters()?.toDictionary() ?? [:]
    }
    
    /// Get the current UTM parameters
    public func getCurrentUTM() -> UTMParameters? {
        return utmTracker.getUtmParameters()
    }
    
    private func requestTrackingPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("AdgeistCore: Tracking permission granted")
                case .denied:
                    print("AdgeistCore: Tracking permission denied")
                case .restricted:
                    print("AdgeistCore: Tracking permission restricted")
                case .notDetermined:
                    print("AdgeistCore: Tracking permission not determined")
                @unknown default:
                    print("AdgeistCore: Unknown tracking permission status")
                }
            }
        }
    }
}
