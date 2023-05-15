import Flutter
import UIKit
import NamiApple

struct NamiFlutterCache {
    static var paywallActionCallback: ((NamiPaywallAction, NamiSKU?) -> Void)?
}

public class SwiftFlutterNamiSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "nami", binaryMessenger: registrar.messenger())
        let signInEventChannel = FlutterEventChannel(name: "signInEvent", binaryMessenger: registrar.messenger())
        let activeEntitlementsEventChannel = FlutterEventChannel(name: "activeEntitlementsEvent", binaryMessenger: registrar.messenger())
        let purchasesChangeEventChannel = FlutterEventChannel(name: "purchasesResponseHandlerData", binaryMessenger: registrar.messenger())
        let journeyStateEventChannel = FlutterEventChannel(name: "journeyStateEvent", binaryMessenger: registrar.messenger())
        let accountStateEventChannel = FlutterEventChannel(name: "accountStateEvent", binaryMessenger: registrar.messenger())
        let campaignsEventChannel = FlutterEventChannel(name: "campaignsEvent", binaryMessenger: registrar.messenger())
        let closePaywallEventChannel = FlutterEventChannel(name: "closePaywallEvent", binaryMessenger: registrar.messenger())
        let buySkuEventChannel = FlutterEventChannel(name: "buySkuEvent", binaryMessenger:
            registrar.messenger())
        let paywallActionEventChannel = FlutterEventChannel(name: "paywallActionEvent", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNamiSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        signInEventChannel.setStreamHandler(SignInEventHandler())
        activeEntitlementsEventChannel.setStreamHandler(ActiveEntitlementsEventHandler())
        purchasesChangeEventChannel.setStreamHandler(PurchasesChangedEventHandler())
        journeyStateEventChannel.setStreamHandler(JourneyStateEventHandler())
        accountStateEventChannel.setStreamHandler(AccountStateEventHandler())
        campaignsEventChannel.setStreamHandler(CampaignsEventHandler())
        closePaywallEventChannel.setStreamHandler(ClosePaywallEventHandler())
        buySkuEventChannel.setStreamHandler(BuySkuEventHandler())
        paywallActionEventChannel.setStreamHandler(PaywallActionEventHandler())
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
        case "deviceId":
            result(NamiCustomerManager.deviceId())
        case "launch":
            let args = call.arguments as? [String: Any]
            if let data = args {
                let label = data["label"] as? String
                let campaignLaunchHandler = { (success: Bool, error: Error?) in
                    result(handleLaunchCampaignResult(success: success, error: error))
                }

                let paywallActionHandler = { (action: NamiPaywallAction, sku: NamiSKU?, purchaseError: Error?, purchases: [NamiApple.NamiPurchase]) in
                    NamiFlutterCache.paywallActionCallback?(action, sku)
                    return
                }

                if(label != nil) {
                    NamiCampaignManager.launch(label: label, launchHandler: campaignLaunchHandler, paywallActionHandler: paywallActionHandler)
                } else {
                    NamiCampaignManager.launch(launchHandler: campaignLaunchHandler, paywallActionHandler: paywallActionHandler)
                }
            }
        case "allCampaigns":
            let allCampaigns = NamiCampaignManager.allCampaigns()
            let listOfMaps = allCampaigns.map({ (campaign: NamiCampaign) in campaign.convertToMap()})
            result(listOfMaps)

        case "campaigns.refresh":
            NamiCampaignManager.refresh{(campaigns: [NamiCampaign]) in
                let listOfMaps = campaigns.map({ (campaign: NamiCampaign) in campaign.convertToMap()})
                result(listOfMaps)
            }

        case "isCampaignAvailable":
            let args = call.arguments as? [String: Any]
            var isAvailable = false
            if let data = args {
                let label = data["label"] as? String
                if(label != nil){
                    isAvailable = NamiCampaignManager.isCampaignAvailable(label: label!)
                } else {
                    isAvailable = NamiCampaignManager.isCampaignAvailable()
                }
            }
            result(isAvailable)

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
        case "skuPurchased":
            let args = call.arguments as? String
            if let skuId = args {
                result(NamiPurchaseManager.skuPurchased(skuId))
            }
        case "anySkuPurchased":
            let args = call.arguments as? [String]
            if let skuIds = args {
                result(NamiPurchaseManager.anySkuPurchased(skuIds))
            }
        case "presentCodeRedemptionSheet":
            NamiPurchaseManager.presentCodeRedemptionSheet()
        case "consumePurchasedSku":
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
    
    class CampaignsEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiCampaignManager.registerAvailableCampaignsHandler {(campaigns: [NamiCampaign]) in
                let listofMaps = campaigns.map({ (campaign: NamiCampaign) in campaign.convertToMap()})
                events(listofMaps)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiCampaignManager.unregisterAvailableCampaignsHandler()
            return nil
        }
    }

    class ClosePaywallEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiPaywallManager.registerCloseHandler { (fromvc) in
                events(nil)
            }
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiPaywallManager.registerCloseHandler(nil)
            return nil
        }
    }

    class BuySkuEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiPaywallManager.registerBuySkuHandler { sku in
                events(sku.id)
            }
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiPaywallManager.registerBuySkuHandler(nil)
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

    class PaywallActionEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiFlutterCache.paywallActionCallback = { (action: NamiPaywallAction, sku: NamiSKU?) in
                events(self.handlePaywallAction(action: action, sku: sku))
            }
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            return nil
        }

        private func handlePaywallAction(action: NamiPaywallAction, sku: NamiSKU?) -> [String: Any?] {
            var map = [String: Any?]()
            map["action"] = action.toFlutterString()
            map["sku"] = sku?.convertToMap()
            return map
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
        case  AccountStateAction.ADVERTISING_ID_SET:
            return "advertising_id_set"
        case  AccountStateAction.ADVERTISING_ID_CLEARED:
            return "advertising_id_cleared"
        case  AccountStateAction.VENDOR_ID_SET:
            return "vendor_id_set"
        case  AccountStateAction.VENDOR_ID_CLEARED:
            return "vendor_id_cleared"
        case  AccountStateAction.CUSTOMER_DATA_PLATFORM_ID_SET:
            return "customer_data_platform_id_set"
        case  AccountStateAction.CUSTOMER_DATA_PLATFORM_ID_CLEARED:
            return "customer_data_platform_id_cleared"
        default:
            return "unknown"
        }
    }
}

public extension NamiPaywallAction {
    func toFlutterString() -> String {
        switch self {
        case NamiPaywallAction.show_paywall:
            return "NAMI_SHOW_PAYWALL"
        case NamiPaywallAction.close_paywall:
            return "NAMI_CLOSE_PAYWALL"
        case NamiPaywallAction.restore_purchases:
            return "NAMI_RESTORE_PURCHASES"
        case NamiPaywallAction.sign_in:
            return "NAMI_SIGN_IN"
        case NamiPaywallAction.buy_sku:
            return "NAMI_BUY_SKU"
        case NamiPaywallAction.select_sku:
            return "NAMI_SELECT_SKU"
        case NamiPaywallAction.purchase_selected_sku:
            return "NAMI_PURCHASE_SELECTED_SKU"
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

public extension NamiCampaign {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["paywall"] = self.paywall
        map["segment"] = self.segment
        if(self.type == NamiCampaignRuleType.default) {
            map["type"] = "DEFAULT"
        } else if (self.type == NamiCampaignRuleType.label) {
            map["type"] = "LABEL"
        } else {
            map["type"] = "LABEL"
        }
        map["value"] = self.value
        return map
    }
}
