# Advertiser UTM Tracker

No initialization is required. The SDK auto-initializes on first use via `AdgeistCore.shared`.

### 1. AppDelegate Integration (UIKit)

Add the following to your `AppDelegate.swift`:

```swift
import UIKit
import AdgeistAdvertiserSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Check if app was opened via URL on first launch
        if let url = launchOptions?[.url] as? URL {
            // This captures install attribution with UTM parameters
            UTMTracker.shared.initializeInstallReferrer(url: url)
        } else {
            // No URL provided (organic install)
            UTMTracker.shared.initializeInstallReferrer()
        }

        return true
    }

    // Handle URLs when app is already running (deeplinks)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        UTMTracker.shared.trackFromDeeplink(url: url)
        return true
    }

    // Handle Universal Links
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        UTMTracker.shared.trackFromDeeplink(url: url)
        return true
    }
}
```

### 2. SceneDelegate Integration (UIKit with Scenes)

Add the following to your `SceneDelegate.swift`:

```swift
import UIKit
import AdgeistAdvertiserSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let _ = (scene as? UIWindowScene) else { return }

        // Check for URL context on first launch
        if let urlContext = connectionOptions.urlContexts.first {
            UTMTracker.shared.initializeInstallReferrer(url: urlContext.url)
        } else {
            UTMTracker.shared.initializeInstallReferrer()
        }

        // Handle Universal Links
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            UTMTracker.shared.initializeInstallReferrer(url: url)
        }
    }

    // Handle URLs when app is already running
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            UTMTracker.shared.trackFromDeeplink(url: url)
        }
    }

    // Handle Universal Links when app is running
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }

        UTMTracker.shared.trackFromDeeplink(url: url)
    }
}
```

### 3. SwiftUI App Integration (iOS 14+)

For SwiftUI apps, use `@UIApplicationDelegateAdaptor` or handle URLs directly:

```swift
import SwiftUI
import AdgeistAdvertiserSDK

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle deeplinks when app is running
                    UTMTracker.shared.trackFromDeeplink(url: url)
                }
        }
    }
}

// AppDelegate for first launch handling
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Check for URL on first launch
        if let url = launchOptions?[.url] as? URL {
            UTMTracker.shared.initializeInstallReferrer(url: url)
        } else {
            UTMTracker.shared.initializeInstallReferrer()
        }

        return true
    }
}
```

### 4. Tracking Conversion Events

Report custom conversion events (for example a purchase, sign-up, or add-to-cart) from anywhere in your app using `AdgeistCore.shared.trackConversionEvent`. Any UTM parameters captured from the install or a deeplink are automatically attached to the event, along with the device fingerprint and capability profile.

```swift
import AdgeistAdvertiserSDK

// Minimal — just an event name
AdgeistCore.shared.trackConversionEvent(eventName: "purchase")

// With custom properties
AdgeistCore.shared.trackConversionEvent(
    eventName: "purchase",
    properties: [
        "orderId": "ORD-12345",
        "value": 49.99,
        "currency": "USD",
        "isFirstPurchase": true
    ]
)

// With a completion handler to observe the result
AdgeistCore.shared.trackConversionEvent(
    eventName: "sign_up",
    properties: ["plan": "pro"]
) { success, error in
    if success {
        print("Conversion event sent")
    } else {
        print("Failed to send event: \(error ?? "unknown error")")
    }
}
```

**Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `eventName` | `String` | Yes | Name of the event (sent to the backend as the event `type`). |
| `properties` | `[String: Any]` | No | Key/value pairs describing the event. Use `String`, `Number`, or `Bool` values. Defaults to empty. |
| `onComplete` | `((Bool, String?) -> Void)?` | No | Optional callback with the send result: `(true, nil)` on success, or `(false, errorMessage)` on failure. |




