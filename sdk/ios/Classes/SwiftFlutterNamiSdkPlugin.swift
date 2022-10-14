import Flutter
import UIKit
import Nami

public class SwiftFlutterNamiSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "nami", binaryMessenger: registrar.messenger())
        let signInEventChannel = FlutterEventChannel(name: "signInEvent", binaryMessenger: registrar.messenger())
        let analyticsEventChannel = FlutterEventChannel(name: "analyticsEvent", binaryMessenger: registrar.messenger())
        let activeEntitlementsEventChannel = FlutterEventChannel(name: "activeEntitlementsEvent", binaryMessenger: registrar.messenger())
        let purchasesChangeEventChannel = FlutterEventChannel(name: "purchasesResponseHandlerData", binaryMessenger: registrar.messenger())
        let journeyStateEventChannel = FlutterEventChannel(name: "journeyStateEvent", binaryMessenger: registrar.messenger())
        let accountStateEventChannel = FlutterEventChannel(name: "accountStateEvent", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNamiSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        signInEventChannel.setStreamHandler(SignInEventHandler())
        analyticsEventChannel.setStreamHandler(AnalyticsEventHandler())
        activeEntitlementsEventChannel.setStreamHandler(ActiveEntitlementsEventHandler())
        purchasesChangeEventChannel.setStreamHandler(PurchasesChangedEventHandler())
        journeyStateEventChannel.setStreamHandler(JourneyStateEventHandler())
        accountStateEventChannel.setStreamHandler(AccountStateEventHandler())
    }

    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            
        case "configure":
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any],
               let appPlatformId = myArgs["appPlatformIdApple"] as? String,
               let bypassStore = myArgs["bypassStore"] as? Bool,
               let namiLogLevel = myArgs["namiLogLevel"] as? String,
               let namiCommands = myArgs["extraDataList"] as? Array<String> {
               let namiConfig = NamiConfiguration(appPlatformId: appPlatformId)
                namiConfig.bypassStore = bypassStore
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
            let args = call.arguments as? String
            if let externalIdentifier = args {
                    NamiCustomerManager.login(withId: externalIdentifier)
            }
        case "loggedInId":
            result(NamiCustomerManager.loggedInId())
        case "isLoggedIn":
            result(NamiCustomerManager.isLoggedIn())
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
        case "dismiss":
            let animated = call.arguments as? Bool ?? false
            NamiPaywallManager.dismiss(animated: animated) {
                result(true)
            }
        case "journeyState":
            if let state = NamiCustomerManager.journeyState() {
                result(state.convertToMap())
            } else {
                result(nil)
            }
        case "isEntitlementActive":
            result(NamiEntitlementManager.isEntitlementActive(call.arguments as! String))
        case "active":
            let activeEntitlements = NamiEntitlementManager.active()
            let listofMaps = activeEntitlements.map({ (namiEntitlement: NamiEntitlement) in namiEntitlement.convertToMap()})
            result(listofMaps)
        case "refresh":
            let refreshHandler = { (activeEntitlements: [NamiEntitlement]) in
                let listofMaps = activeEntitlements.map({ (namiEntitlement: NamiEntitlement) in namiEntitlement.convertToMap()})
                result(listofMaps)
            }
            NamiEntitlementManager.refresh(refreshHandler)
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
                result(NamiPurchaseManager.skuPurchased(skuId))
            }
        case "anySKUIDPurchased":
            let args = call.arguments as? [String]
            if let skuIds = args {
                result(NamiPurchaseManager.anySkuPurchased(skuIds))
            }
        case "consumePurchasedSKU":
            let args = call.arguments as? String
            if let skuId = args {
                NamiPurchaseManager.consumePurchasedSku(skuId: skuId)
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
            NamiPaywallManager.registerSignInHandler { (fromvc) in
                // TODO: Figure out what the right thing to do here is.
                events(true)
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
                eventMap["campaign_rule"] = data[NamiAnalyticsKeys.campaignRule]
                eventMap["campaign_segment"] = data[NamiAnalyticsKeys.campaignSegment]
                eventMap["campaign_type"] = data[NamiAnalyticsKeys.campaignType]
                eventMap["campaign_value"] = data[NamiAnalyticsKeys.campaignValue]

                eventMap["paywall"] = data[NamiAnalyticsKeys.paywall]
                eventMap["paywall_type"] = data[NamiAnalyticsKeys.paywallType]

                eventMap["purchased_sku"] = data[NamiAnalyticsKeys.purchasedSKU]
                eventMap["purchased_sku_id"] = data[NamiAnalyticsKeys.purchasedSKUIdentifier]
                eventMap["purchased_sku_price"] = data[NamiAnalyticsKeys.purchasedSKUPrice]
                eventMap["purchased_sku_store_locale"] = data[NamiAnalyticsKeys.purchasedSKUStoreLocale]
                eventMap["purchased_sku_locale"] = data[NamiAnalyticsKeys.purchasedSKULocale]
                eventMap["purchase_timestamp"] = data[NamiAnalyticsKeys.purchasedSKUPurchaseTimestamp_Date]

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
                let skus = data[NamiAnalyticsKeys.paywallSKUs] as? [NamiSKU]
                var list = [[String: Any]]()
                skus?.forEach { (sku: NamiSKU) in
                    list.append(sku.convertToMap())
                }
                eventMap["paywall_skus"] = list

                eventMap["paywall_raise_source"] = data[NamiAnalyticsKeys.paywallRaiseSource]

                events(eventMap)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiAnalyticsSupport.registerAnalyticsHandler(handler: nil)
            return nil
        }
    }
    
    class ActiveEntitlementsEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiEntitlementManager.registerActiveEntitlementsHandler { (activeEntitlements: [NamiEntitlement]) in
                let listofMaps = activeEntitlements.map({ (namiEntitlement: NamiEntitlement) in namiEntitlement.convertToMap()})
                events(listofMaps)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiEntitlementManager.unregisterActiveEntitlementsHandler()
            return nil
        }
    }
    
    class JourneyStateEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiCustomerManager.registerJourneyStateHandler { newCustomerJourneyState in
                events(newCustomerJourneyState.convertToMap())
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiCustomerManager.registerJourneyStateHandler(nil)
            return nil
        }
    }
    
    class PurchasesChangedEventHandler: NSObject, FlutterStreamHandler {
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

    class AccountStateEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiCustomerManager.registerAccountStateHandler { (accountStateAction: AccountStateAction, success: Bool, error: Error?) in
                var eventMap = [String : Any]()
                eventMap["accountStateAction"] = accountStateAction.toFlutterString()
                eventMap["success"] = success
                eventMap["error"] = error?.localizedDescription
                events(eventMap)
            }
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiCustomerManager.registerAccountStateHandler(nil)
            return nil
        }
    }
}


public extension AccountStateAction {
    func toFlutterString() -> String {
        switch self {
        case AccountStateAction.login:
            return "login"
        case AccountStateAction.logout:
            return "logout"
        default:
            return "unknown"
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
        map["description"] = self.desc
        map["referenceId"] = self.referenceId
        map["relatedSKUs"] = self.relatedSkus.map({ (namiSku: NamiSKU) in namiSku.convertToMap()})
        map["purchasedSKUs"] = self.purchasedSkus.map({ (namiSku: NamiSKU) in namiSku.convertToMap()})
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
        if(self.purchaseSource == NamiPurchaseSource.campaign) {
            map["purchaseSource"] = "campaign"
        } else if(self.purchaseSource == NamiPurchaseSource.marketplace) {
            map["purchaseSource"] = "marketplace"
        } else {
            map["purchaseSource"] = "unknown"
        }
        map["transactionIdentifier"] = self.transactionIdentifier
        map["skuId"] = self.skuId
        return map
    }
}

public extension NamiSKU {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["name"] = self.name
        map["skuId"] = self.skuId
        if(self.type == NamiSKUType.one_time_purchase) {
            map["type"] = "one_time_purchase"
        } else if (self.type == NamiSKUType.subscription) {
            map["type"] = "subscription"
        } else {
            map["type"] = "unknown"
        }
        return map
    }
}