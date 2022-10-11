import Flutter
import UIKit
import Nami

public class SwiftFlutterNamiSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "nami", binaryMessenger: registrar.messenger())
        let signInEventChannel = FlutterEventChannel(name: "signInEvent", binaryMessenger: registrar.messenger())
        let analyticsEventChannel = FlutterEventChannel(name: "analyticsEvent", binaryMessenger: registrar.messenger())
        let entitlementChangeEventChannel = FlutterEventChannel(name: "entitlementChangeEvent", binaryMessenger: registrar.messenger())
        let paywallRaiseEventChannel = FlutterEventChannel(name: "paywallRaiseEvent", binaryMessenger: registrar.messenger())
        let purchasesChangeEventChannel = FlutterEventChannel(name: "purchasesResponseHandlerData", binaryMessenger: registrar.messenger())
        let customerJourneyChangeEventChannel = FlutterEventChannel(name: "customerJourneyChangeEvent", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNamiSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        signInEventChannel.setStreamHandler(SignInEventHandler())
        analyticsEventChannel.setStreamHandler(AnalyticsEventHandler())
        entitlementChangeEventChannel.setStreamHandler(EntitlementChangeEventHandler())
        paywallRaiseEventChannel.setStreamHandler(PaywallRaiseEventHandler())
        purchaseChangedEventChannel.setStreamHandler(PurchasesChangedEventHandler())
        customerJourneyChangeEventChannel.setStreamHandler(CustomerJourneyChangeEventHandler())
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
               let passiveMode = myArgs["passiveMode"] as? Bool,
               let namiLogLevel = myArgs["namiLogLevel"] as? String,
               let namiCommands = myArgs["extraDataList"] as? Array<String> {
                let namiConfig = NamiConfiguration(appPlatformId: appPlatformID)
                namiConfig.bypassStore = bypassStore
                namiConfig.passiveMode = passiveMode
                namiConfig.namiCommands = namiCommands
                if(namiLogLevel == "debug") {
                    namiConfig.logLevel = NamiLogLevel.debug
                } else if(namiLogLevel == "info") {
                    namiConfig.logLevel = NamiLogLevel.info
                } else if(namiLogLevel == "warn") {
                    namiConfig.logLevel = NamiLogLevel.warn
                } else {
                    namiConfig.logLevel = NamiLogLevel.error
                }
                Nami.configure(with: namiConfig)
            } else {
                print(FlutterError(code: "-1", message: "iOS could not extract " +
                                   "flutter arguments in method: (sendParams)", details: nil))
            }
            result(true)
        case "logout":
            NamiCustomerManager.logout()
        case "login":
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any],
               let externalIdentifier = myArgs["withId"] as! String,
                NamiCustomerManager.login(withId: externalIdentifier)
            } else {
                print(FlutterError(code: "-1", message: "iOS could not extract " +
                                   "flutter arguments in method: (sendParams)", details: nil))
            }
        case "loggedInId":
            result(NamiCustomerManager.loggedInId())
        case "launch":
            let args = call.arguments as? [String: Any]
            if let data = args {
                let label = data["label"] as? String
                let campaignLaunchHandler = { (success: Bool, error: Error?) in
                    result(handleLaunchCampaignResult(success: success, error: error))
                }
                if(label == nil) {
                    NamiCampaignManager.launch(label: label, launchHandler: campaignLaunchHandler)
                } else {
                    NamiCampaignManager.launch(launchHandler: campaignLaunchHandler)
                }
            }
        case "dismissNamiPaywallIfOpen":
            let animated = call.arguments as? Bool ?? false
            NamiPaywallManager.dismissNamiPaywallIfOpen(animated: animated) {
                result(true)
            }
        case "currentCustomerJourneyState":
            if let state = NamiCustomerManager.currentCustomerJourneyState() {
                result(state.convertToMap())
            } else {
                result(nil)
            }
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
        case "coreAction":
            let args = call.arguments as? String
            if let label = args {
                NamiMLManager.coreAction(label: label)
            }
        case "enterCoreContent":
            let args = call.arguments as? [String]
            if let labels = args {
                NamiMLManager.enterCoreContent(labels: labels)
            }
        case "exitCoreContent":
            let args = call.arguments as? [String]
            if let labels = args {
                NamiMLManager.exitCoreContent(labels: labels)
            }
        case "clearBypassStorePurchases":
            NamiPurchaseManager.clearBypassStorePurchases()
        case "allPurchases":
            let allPurchases = NamiPurchaseManager.allPurchases()
            let listofMaps = allPurchases.map({ (namiPurchase: NamiPurchase) in namiPurchase.convertToMap()})
            result(listofMaps)
        case "isSKUIDPurchased":
            let args = call.arguments as? String
            if let skuId = args {
                result(NamiPurchaseManager.isSKUIDPurchased(skuId))
            }
        case "anySKUIDPurchased":
            let args = call.arguments as? [String]
            if let skuIds = args {
                result(NamiPurchaseManager.anySKUIDPurchased(skuIds))
            }
        case "consumePurchasedSKU":
            let args = call.arguments as? String
            if let skuId = args {
                NamiPurchaseManager.consumePurchasedSKU(skuID: skuId)
            }
        case "buySKU":
            let args = call.arguments as? String
            if let skuRefId = args {
                NamiPurchaseManager.skusForSKUIDs(skuIDs: [skuRefId]) { (success: Bool, skus: [NamiSKU]?, invalidSKUIDs: [String]?, error: Error?) in
                    if let sku = skus?.first {
                        NamiPurchaseManager.buySKU(sku) { (purchases: [NamiPurchase], state: NamiPurchaseState, error: Error?) in
                            if(state != NamiPurchaseState.pending) {
                                var eventMap = [String : Any?]()
                                eventMap["error"] = error?.localizedDescription
                                // Delete this once buySKU is working on iOS
                                eventMap["original_state"] = state.readableString()
                                // Delete this once buySKU is working on iOS
                                eventMap["purchases"] = purchases.count
                                // react to the state of the purchase
                                if state == .purchased {
                                    eventMap["purchaseState"] = "purchased"
                                }
                                else {
                                    eventMap["purchaseState"] = "failed"
                                }
                                result(eventMap)
                            }
                        }
                    }
                }
            }
        default:
            result("iOS " + UIDevice.current.systemVersion)
        }
        
        func handleLaunchCampaignResult(success: Bool, error: Error?) -> [String: Any?] {
            var map = [String: Any?]()
            map["success"] = success
            if let error = error as NSError? {
                if(error.code == 0) {
                    map["error"] = "default_campaign_not_found"
                } else if(error.code == 1) {
                    map["error"] = "labeled_campaign_not_found"
                } else if(error.code == 2) {
                    map["error"] = "campaign_data_not_found"
                } else if(error.code == 3) {
                    map["error"] = "paywall_already_displayed"
                } else if(error.code == 4) {
                    map["error"] = "sdk_not_initialized"
                } else {
                    map["error"] = nil
                }
            }
            return map
        }
    }
    
    class SignInEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiPaywallManager.registerSignInHandler { (_, id: String, paywall: NamiPaywall) in
                events(paywall.convertToMap())
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiPaywallManager.registerSignInHandler(nil)
            return nil
        }
    }
    
    class AnalyticsEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiAnalyticsSupport.registerAnalyticsHandler { (type: NamiAnalyticsActionType, data: [String : Any]) in
                var eventMap = [String : Any?]()
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
            NamiEntitlementManager.registerEntitlementsChangedHandler { (namiEntitlements: [NamiEntitlement]) in
                let listofMaps = namiEntitlements.map({ (namiEntitlement: NamiEntitlement) in namiEntitlement.convertToMap()})
                events(listofMaps)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiEntitlementManager.registerEntitlementsChangedHandler(nil)
            return nil
        }
    }
    
    class CustomerJourneyChangeEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiCustomerManager.registerJourneyStateChangedHandler { newCustomerJourneyState in
                events(newCustomerJourneyState.convertToMap())
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiCustomerManager.registerJourneyStateChangedHandler(nil)
            return nil
        }
    }
    
    class PurchasesChangedHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiPurchaseManager.registerPurchasesChangedHandler { (activePurchases: [NamiPurchase], namiPurchaseState: NamiPurchaseState, error: Error?) in
                var eventMap = [String : Any]()
                eventMap["activePurchases"] = activePurchases.map({ (namiPurchase: NamiPurchase) in namiPurchase.convertToMap()})
                eventMap["purchaseState"] = namiPurchaseState.toFlutterString()
                eventMap["error"] = error?.localizedDescription
                events(eventMap)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiPurchaseManager.registerPurchasesChangedHandler(nil)
            return nil
        }
    }
}

public extension NamiPurchaseState {
    func toFlutterString() -> String {
        switch self {
        case NamiPurchaseState.cancelled:
            return "cancelled"
        case NamiPurchaseState.failed:
            return "failed"
        case NamiPurchaseState.pending:
            return "pending"
        case NamiPurchaseState.consumed:
            return "consumed"
        case NamiPurchaseState.deferred:
            return "deferred"
        case NamiPurchaseState.resubscribed:
            return "resubscribed"
        case NamiPurchaseState.unsubscribed:
            return "unsubscribed"
        case NamiPurchaseState.purchased:
            return "purchased"
        default:
            return "unknown"
        }
    }
}

public extension CustomerJourneyState {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["former_subscriber"] = self.formerSubscriber
        map["in_grace_period"] = self.inGracePeriod
        map["in_trial_period"] = self.inTrialPeriod
        map["in_intro_offer_period"] = self.inIntroOfferPeriod
        map["is_cancelled"] = self.isCancelled
        map["in_pause"] = self.inPause
        map["in_account_hold"] = self.inAccountHold
        return map
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
        var expiry: Int? = nil
        if let timeSince = self.expires?.timeIntervalSince1970 {
            expiry = Int.init(timeSince)
        }
        var map = [String: Any]()
        map["purchaseInitiatedTimestamp"] = Int.init(self.purchaseInitiatedTimestamp.timeIntervalSince1970)
        map["expires"] = expiry
        map["fromNami"] = false
        if(self.purchaseSource == NamiPurchaseSource.campaign) {
            map["purchaseSource"] = "campaign"
        } else if(self.purchaseSource == NamiPurchaseSource.marketplace) {
            map["purchaseSource"] = "marketplace"
        } else {
            map["purchaseSource"] = "unknown"
        }
        map["transactionIdentifier"] = self.transactionIdentifier
        map["skuId"] = self.skuID
        return map
    }
}

public extension NamiSKU {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["description"] = self.product?.localizedDescription ?? ""
        map["title"] = self.product?.localizedTitle ?? ""
        map["displayText"] = self.namiDisplayText
        map["displaySubText"] = self.namiSubDisplayText
        map["localizedMultipliedPrice"] = self.product?.localizedMultipliedPrice
        map["price"] = self.product?.price.stringValue ?? ""
        map["subscriptionGroupIdentifier"] = self.product?.subscriptionGroupIdentifier
        map["skuId"] = self.skuID
        map["featured"] = self.productMetadata?[NamiSKUKeys.featured.rawValue]
        map["localizedPrice"] = self.localizedCurrentPrice
        map["numberOfUnits"] = self.product?.subscriptionPeriod?.numberOfUnits ?? 0
        map["priceLanguage"] = self.product?.priceLocale.languageCode
        map["priceCurrency"] = self.product?.priceLocale.currencyCode ?? ""
        map["priceCountry"] = self.product?.priceLocale.regionCode
        if(self.type == NamiSKUType.one_time_purchase) {
            map["type"] = "one_time_purchase"
        } else if (self.type == NamiSKUType.subscription) {
            map["type"] = "subscription"
        } else {
            map["type"] = "unknown"
        }
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