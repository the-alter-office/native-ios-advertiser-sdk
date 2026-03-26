# Advertiser UTM Tracker

Initialization is required. Call `AdgeistCore.initialize()` as early as possible at app startup to ensure tracking permission is requested, install referrer is captured, and the analytics backend is connected before any deeplink arrives.


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
            AdgeistCore.shared.initializeInstallReferrer(url: url)
        } else {
            // No URL provided (organic install)
            AdgeistCore.shared.initializeInstallReferrer()
        }

        return true
    }

    // Handle URLs when app is already running (deeplinks)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AdgeistCore.shared.trackDeeplink(url: url)
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

        AdgeistCore.shared.trackUniversalLink(url: url)
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
            AdgeistCore.shared.initializeInstallReferrer(url: urlContext.url)
        } else {
            AdgeistCore.shared.initializeInstallReferrer()
        }

        // Handle Universal Links
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            AdgeistCore.shared.initializeInstallReferrer(url: url)
        }
    }

    // Handle URLs when app is already running
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            AdgeistCore.shared.trackDeeplink(url: url)
        }
    }

    // Handle Universal Links when app is running
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }

        AdgeistCore.shared.trackUniversalLink(url: url)
    }
}
```

### 3. SwiftUI App Integration (iOS 14+)

Initialize `AdgeistCore` in your `App`'s `init()` to ensure it runs before any view is rendered:

```swift
import SwiftUI
import AdgeistAdvertiserSDK

@main
struct YourApp: App {
    init() {
        // Required: initializes tracking permission, install referrer,
        // and backend connection at app startup
        AdgeistCore.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle deeplinks when app is running
                    AdgeistCore.shared.trackDeeplink(url: url)
                }
        }
    }
}
```


