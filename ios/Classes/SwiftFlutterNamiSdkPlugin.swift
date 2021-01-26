import Flutter
import UIKit
import Nami

public class SwiftFlutterNamiSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "nami", binaryMessenger: registrar.messenger())
        let signInEventChannel = FlutterEventChannel(name: "signInEvent", binaryMessenger: registrar.messenger())
        let analyticsEventChannel = FlutterEventChannel(name: "analyticsEvent", binaryMessenger: registrar.messenger())
        let entitlementChangeEventChannel = FlutterEventChannel(name: "entitlementChangeEvent", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNamiSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        signInEventChannel.setStreamHandler(SignInEventHandler())
        analyticsEventChannel.setStreamHandler(AnalyticsEventHandler())
        entitlementChangeEventChannel.setStreamHandler(EntitlementChangeEventHandler())
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
        case "currentCustomerJourneyState":
            let state = NamiCustomerManager.currentCustomerJourneyState()
            var eventMap = [String : Any?]()
            eventMap["former_subscriber"] = state?.formerSubscriber
            eventMap["in_grace_period"] = state?.formerSubscriber
            eventMap["in_trial_period"] = state?.formerSubscriber
            eventMap["in_intro_offer_period"] = state?.formerSubscriber
            result(eventMap)
        case "clearAllEntitlements":
            NamiEntitlementManager.clearAllEntitlements()
        case "isEntitlementActive":
            result(NamiEntitlementManager.isEntitlementActive(call.arguments as! String))
        case "activeEntitlements":
            let activeEntitlements = NamiEntitlementManager.activeEntitlements()
            let listofMaps = activeEntitlements.map({ (namiEntitlement: NamiEntitlement) in namiEntitlement.convertToMap()})
            result(listofMaps)
        case "getEntitlements":
            let allEntitlements = NamiEntitlementManager.getEntitlements()
            let listofMaps = allEntitlements.map({ (namiEntitlement: NamiEntitlement) in namiEntitlement.convertToMap()})
            result(listofMaps)
        case "setEntitlements":
            let myArgs = call.arguments as? [[String: Any]]
            var setters = [NamiEntitlementSetter]()
            myArgs?.forEach({ (setterMap:[String : Any]) in
                let setter = NamiEntitlementSetter(id: setterMap["referenceId"] as? String ?? "")
                let expiry = setterMap["expires"] as? Int
                if let date = expiry {
                    setter.expires = Date(timeIntervalSince1970: Double.init(date))
                }
                let platformType = setterMap["platform"] as? String
                if(platformType == "android") {
                    setter.platform = NamiPlatformType.android
                } else if(platformType == "apple") {
                    setter.platform = NamiPlatformType.apple
                } else if(platformType == "web") {
                    setter.platform = NamiPlatformType.web
                }else if(platformType == "roku") {
                    setter.platform = NamiPlatformType.roku
                } else {
                    setter.platform = NamiPlatformType.other
                }
                setter.purchasedSKUid = setterMap["purchasedSKUid"] as? String
                setters.append(setter)
            })
            NamiEntitlementManager.setEntitlements(setters)
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
            NamiPaywallManager.register(applicationSignInProvider: nil)
            return nil
        }
    }
    
    class AnalyticsEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiAnalyticsSupport.registerAnalyticsHandler { (type: NamiAnalyticsActionType, data: [String : Any]) in
                var eventMap = [String : Any]()
                let typeString: String
                if(type == NamiAnalyticsActionType.paywallRaise) {
                    typeString = "paywall_raise"
                } else {
                    typeString = "purchase_activity"
                }
                eventMap["type"] = typeString
                eventMap["campaign_id"] = data[NamiAnalyticsKeys.campaignID]
                eventMap["campaign_name"] = data[NamiAnalyticsKeys.campaignName]
                eventMap["nami_triggered"] = data[NamiAnalyticsKeys.namiTriggered]
                eventMap["paywall_id"] = data[NamiAnalyticsKeys.paywallID]
                eventMap["paywall_name"] = data[NamiAnalyticsKeys.paywallName]
                eventMap["paywall_type"] = data[NamiAnalyticsKeys.paywallType]
                let activityType = data[NamiAnalyticsKeys.purchaseActivityType_ActivityType] as? NamiAnalyticsPurchaseActivityType
                if(activityType == NamiAnalyticsPurchaseActivityType.cancelled) {
                    eventMap["purchase_activity_type"] = "cancelled"
                } else if (activityType == NamiAnalyticsPurchaseActivityType.newPurchase) {
                    eventMap["purchase_activity_type"] = "new_purchase"
                } else if (activityType == NamiAnalyticsPurchaseActivityType.restored) {
                    eventMap["purchase_activity_type"] = "restored"
                } else {
                    eventMap["purchase_activity_type"] = "resubscribe"
                }
                let skus = data[NamiAnalyticsKeys.paywallSKUs_NamiSKU] as? [NamiSKU]
                var list = [[String: Any]]()
                skus?.forEach { (sku: NamiSKU) in
                    list.append(sku.convertToMap())
                }
                eventMap["paywall_products"] = list
                events(eventMap)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiAnalyticsSupport.registerAnalyticsHandler(handler: nil)
            return nil
        }
    }
    
    class EntitlementChangeEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiEntitlementManager.registerChangeHandler { (namiEntitlements: [NamiEntitlement]) in
                let listofMaps = namiEntitlements.map({ (namiEntitlement: NamiEntitlement) in namiEntitlement.convertToMap()})
                events(listofMaps)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiEntitlementManager.registerChangeHandler(entitlementsChangedHandler: nil)
            return nil
        }
    }
}

public extension NamiEntitlement {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["name"] = self.name
        map["description"] = self.description
        map["namiId"] = self.namiID
        map["referenceId"] = self.referenceID
        map["relatedSKUs"] = self.relatedSKUs.map({ (namiSku: NamiSKU) in namiSku.convertToMap()})
        map["purchasedSKUs"] = self.purchasedSKUs.map({ (namiSku: NamiSKU) in namiSku.convertToMap()})
        map["activePurchases"] = self.activePurchases.map({ (namiPurchase: NamiPurchase) in namiPurchase.convertToMap()})
        return map
    }
}

public extension NamiPurchase {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["purchaseInitiatedTimestamp"] = Int.init(self.purchaseInitiatedTimestamp.timeIntervalSince1970)
        map["expires"] = Int.init(self.expires?.timeIntervalSince1970 ?? 0)
        map["fromNami"] = false
        if(self.purchaseSource == NamiPurchaseSource.application) {
            map["purchaseSource"] = "application"
        } else if(self.purchaseSource == NamiPurchaseSource.external) {
            map["purchaseSource"] = "external"
        } else if(self.purchaseSource == NamiPurchaseSource.namiPaywall) {
            map["purchaseSource"] = "nami_paywall"
            map["fromNami"] = true
        } else {
            map["purchaseSource"] = "unknown"
        }
        map["transactionIdentifier"] = self.transactionIdentifier
        map["localizedDescription"] = self.description
        return map
    }
}

public extension NamiSKU {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["description"] = self.product?.localizedDescription
        map["title"] = self.product?.localizedTitle
        map["localizedMultipliedPrice"] = self.product?.localizedMultipliedPrice
        map["price"] = self.product?.price.stringValue
        map["subscriptionGroupIdentifier"] = self.product?.subscriptionGroupIdentifier
        map["skuId"] = self.skuID
        map["localizedPrice"] = self.product?.localizedPrice
        map["numberOfUnits"] = self.product?.subscriptionPeriod?.numberOfUnits
        map["priceLanguage"] = self.product?.priceLocale.languageCode
        map["priceCurrency"] = self.product?.priceLocale.currencyCode
        map["priceCountry"] = self.product?.priceLocale.regionCode
        let period = self.product?.subscriptionPeriod?.unit
        if(period == SKProduct.PeriodUnit.day) {
            map["periodUnit"] = "day"
        } else if(period == SKProduct.PeriodUnit.month) {
            map["periodUnit"] = "month"
        }else if(period == SKProduct.PeriodUnit.week) {
            map["periodUnit"] = "week"
        } else {
            map["periodUnit"] = "year"
        }
        return map
    }
}
