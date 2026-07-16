import Foundation
import os.log



enum Logger {

    private static let log = OSLog(subsystem: "com.adgeist.advertiser-sdk", category: "AdgeistAdvertiserSDK")

    static func log(_ message: String) {
        os_log("%{public}@", log: log, type: .info, message)
    }
}
