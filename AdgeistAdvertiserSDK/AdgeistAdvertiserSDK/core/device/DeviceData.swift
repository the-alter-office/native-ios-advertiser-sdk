
import Foundation
import UIKit
import CoreTelephony
import CoreMotion
import Metal
import CoreNFC

/// Collects everything that can be extracted from the device.
///
/// Native iOS exposes most hardware/OS fields. Browser-only fields
/// (`browserName`, `browserVersion`, `webglRenderer`) are intentionally
/// left `nil` since there is no web view context here.
package class DeviceData {


//     "deviceManufacturer": "string",
//       "deviceName": "string",
//       "deviceVersion": "string",
//       "screenWidth": 0,
//       "screenHeight": 0,
//       "screenDensity": 0,
//       "osName": "string",
//       "osVersion": "string",
//       "noOfCPUs": 0,
//       "ram": 0,
//       "architecture": "string"

// "deviceType": "string",
//   "deviceBrand": "string",
//   "screenWidth": 10000,
//   "screenHeight": 10000,
//   "screenPixelRatio": 10,
//   "screenDensity": 2000,
//   "coreArchitecture": "string",
//   "osName": "string",
//   "osVersion": "string",
//   "noOfProcessors": 256,
//   "browserName": "string",
//   "browserVersion": "string",
//   "networkType": "string",
//   "isTouchScreenCapable": true,
//   "isNFCCapable": true,
//   "isNFCEnabled": true,
//   "isGPUCapable": true,
//   "isVRCapable": true,
//   "isScreenReaderEnabled": true,
//   "webglRenderer": "string"

    package init() {}

    let deviceManufacturer: String = "Apple"
    let deviceVersion: String = UIDevice.current.model
    let osName: String = UIDevice.current.systemName
    let osVersion: String = UIDevice.current.systemVersion

  

    let noOfCPUs: Int = ProcessInfo.processInfo.processorCount
    let ram: Int = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)) // bytes to GB
    


    // let screenWidth: Int = Int(UIScreen.main.bounds.width)
    // let screenHeight: Int = Int(UIScreen.main.bounds.height)
    // let screenDensity: Float = Float(UIScreen.main.scale)
    // let deviceModel: String = UIDevice.current.model
    // let deviceName: String = UIDevice.current.name

       
}
