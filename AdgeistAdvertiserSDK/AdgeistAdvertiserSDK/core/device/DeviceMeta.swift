import Foundation
import UIKit


public struct DeviceMeta {

    // Singleton instance of DeviceMeta, initialized on the main thread to ensure UIKit APIs are accessed correctly.
    public static let shared: DeviceMeta = {
        if Thread.isMainThread {
            return DeviceMeta()
        }
        return DispatchQueue.main.sync { DeviceMeta() }
    }()

    let deviceName: String
    let deviceModel: String
    let deviceManufacturer = "Apple"

    let screenWidth: Int
    let screenHeight: Int
    let screenPixelRatio: Float
    let screenDensity: Float

    let osName: String
    let osVersion: String

    let noOfProcessors: Int
    let ram: Int // in GB
    let architecture: String

    let deviceType: String

    /// Must be called on the main thread — use `shared` instead.
    private init() {
        let device = UIDevice.current
        let screen = UIScreen.main

        deviceName = device.name
        deviceModel = device.model

        screenWidth = Int(screen.bounds.width)
        screenHeight = Int(screen.bounds.height)
        screenPixelRatio = Float(screen.scale)
        screenDensity = Float(screen.scale)

        osName = device.systemName
        osVersion = device.systemVersion

        noOfProcessors = ProcessInfo.processInfo.processorCount
        ram = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))
        architecture = "ARM64"

        switch device.userInterfaceIdiom {
        case .phone:
            deviceType = "iPhone"
        case .pad:
            deviceType = "iPad"
        case .tv:
            deviceType = "Apple TV"
        case .carPlay:
            deviceType = "CarPlay"
        case .mac:
            deviceType = "Mac"
        default:
            deviceType = "Unknown"
        }
    }
}
