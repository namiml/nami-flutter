import Flutter
import UIKit
import Nami

public class SwiftFlutterNamiSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "nami", binaryMessenger: registrar.messenger())
        let signInEventChannel = FlutterEventChannel(name: "signInEvent", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNamiSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        
        case "configure":
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any],
               let appPlatformID = myArgs["appPlatformIDApple"] as? String,
               let bypassStore = myArgs["bypassStore"] as? Bool,
               let namiLogLevel = myArgs["namiLogLevel"] as? Int,
               let namiCommands = myArgs["extraDataList"] as? Array<String> {
                let namiConfig = NamiConfiguration(appPlatformID: appPlatformID)
                namiConfig.bypassStore = bypassStore
                namiConfig.namiCommands = namiCommands
                if(namiLogLevel == NamiLogLevel.debug.rawValue) {
                    namiConfig.logLevel = NamiLogLevel.debug
                } else if(namiLogLevel == NamiLogLevel.info.rawValue) {
                    namiConfig.logLevel = NamiLogLevel.info
                } else if(namiLogLevel == NamiLogLevel.warn.rawValue) {
                    namiConfig.logLevel = NamiLogLevel.warn
                } else {
                    namiConfig.logLevel = NamiLogLevel.error
                }
                Nami.configure(namiConfig: namiConfig)
            } else {
                print(FlutterError(code: "-1", message: "iOS could not extract " +
                                    "flutter arguments in method: (sendParams)", details: nil))
            }
            result(true)
        default:
            result("iOS " + UIDevice.current.systemVersion)
        }
        result("iOS " + UIDevice.current.systemVersion)
    }
}
