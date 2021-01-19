import Flutter
import UIKit
import Nami

public class SwiftFlutterNamiSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "nami", binaryMessenger: registrar.messenger())
        let signInEventChannel = FlutterEventChannel(name: "signInEvent", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNamiSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        signInEventChannel.setStreamHandler(SignInEventHandler())
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
               let developmentMode = myArgs["developmentMode"] as? Bool,
               let passiveMode = myArgs["passiveMode"] as? Bool,
               let namiLogLevel = myArgs["namiLogLevel"] as? Int,
               let namiCommands = myArgs["extraDataList"] as? Array<String> {
                let namiConfig = NamiConfiguration(appPlatformID: appPlatformID)
                namiConfig.bypassStore = bypassStore
                namiConfig.developmentMode = developmentMode
                namiConfig.passiveMode = passiveMode
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
        case "clearExternalIdentifier":
            Nami.clearExternalIdentifier()
        case "setExternalIdentifier":
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any],
               let externalIdentifier = myArgs["externalIdentifier"] as? String,
               let type = myArgs["type"] as? Int {
                if(type == NamiExternalIdentifierType.uuid.rawValue) {
                    Nami.setExternalIdentifier(externalIdentifier: externalIdentifier, type: NamiExternalIdentifierType.uuid)
                } else {
                    Nami.setExternalIdentifier(externalIdentifier: externalIdentifier, type: NamiExternalIdentifierType.sha256)
                }
            } else {
                print(FlutterError(code: "-1", message: "iOS could not extract " +
                                    "flutter arguments in method: (sendParams)", details: nil))
            }
        case "getExternalIdentifier":
            result(Nami.getExternalIdentifier())
        case "canRaisePaywall":
            result(NamiPaywallManager.canRaisePaywall())
        case "raisePaywall":
            // https://github.com/flutter/flutter/issues/9961
            // https://github.com/flutter/flutter/issues/44764
            let viewController = UIApplication.shared.delegate!.window!!.rootViewController!
            NamiPaywallManager.raisePaywall(fromVC: viewController)
        default:
            result("iOS " + UIDevice.current.systemVersion)
        }
    }
    
    class SignInEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiPaywallManager.register { (_, id: String, paywall: NamiPaywall) in
                var eventMap = [String : String]()
                eventMap["name"] = paywall.paywallValue(forKey: NamiPaywallKeys.name)
                eventMap["allowClosing"] = paywall.paywallValue(forKey: NamiPaywallKeys.allow_closing)
                eventMap["backgroundImageUrlPhone"] = paywall.paywallValue(forKey: NamiPaywallKeys.background_image_url_phone)
                eventMap["backgroundImageUrlTablet"] = paywall.paywallValue(forKey: NamiPaywallKeys.background_image_url_tablet)
                eventMap["body"] = paywall.description
                eventMap["title"] = paywall.title
                eventMap["developerPaywallId"] = paywall.paywallValue(forKey: NamiPaywallKeys.developer_paywall_id)
                eventMap["privacyPolicy"] = paywall.paywallValue(forKey: NamiPaywallKeys.privacy_policy)
                eventMap["purchaseTerms"] = paywall.paywallValue(forKey: NamiPaywallKeys.purchase_terms)
                eventMap["restoreControl"] = paywall.paywallValue(forKey: NamiPaywallKeys.restore_control)
                eventMap["signInControl"] = paywall.paywallValue(forKey: NamiPaywallKeys.sign_in_control)
                eventMap["tosLink"] = paywall.paywallValue(forKey: NamiPaywallKeys.tos_link)
                eventMap["type"] = paywall.paywallValue(forKey: NamiPaywallKeys.type)
                events(eventMap)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            return nil
        }
        
        
    }
}
