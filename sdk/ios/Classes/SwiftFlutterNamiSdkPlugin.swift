import Flutter
import UIKit
import NamiApple

struct NamiFlutterCache {
    static var paywallActionCallback: ((NamiPaywallEvent) -> Void)?
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
        let restorePaywallEventChannel = FlutterEventChannel(name: "restorePaywallEvent", binaryMessenger: registrar.messenger())
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
        restorePaywallEventChannel.setStreamHandler(RestorePaywallEventHandler())
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
               let namiLogLevel = myArgs["namiLogLevel"] as? String,
               let namiCommands = myArgs["extraDataList"] as? Array<String> {
                let namiConfig = NamiConfiguration(appPlatformId: appPlatformId)
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
            
        case "setCustomerAttribute":
            if let args = call.arguments as? [String: String] {
                args.forEach({
                    NamiCustomerManager.setCustomerAttribute($0.key, $0.value)
                })
            }
            
        case "getCustomerAttribute":
            let args = call.arguments as? String
            if let data = args {
                result(NamiCustomerManager.getCustomerAttribute(key: data))
            }
            
        case "clearCustomerAttribute":
            let args = call.arguments as? String
            if let data = args {
                NamiCustomerManager.clearCustomerAttribute(data)
            }
            
        case "clearAllCustomerAttribute":
            NamiCustomerManager.clearAllCustomerAttributes()

        case "setCustomerDataPlatformId":
           let args = call.arguments as? String
           if let withId = args {
              NamiCustomerManager.setCustomerDataPlatformId(with: withId)
           }

        case "clearCustomerDataPlatformId":
             NamiCustomerManager.clearCustomerDataPlatformId()

        case "setAnonymousMode":
            let args = call.arguments as? Bool
            if let anonymousMode = args {
               NamiCustomerManager.setAnonymousMode(anonymousMode)
            }

        case "inAnonymousMode":
              result(NamiCustomerManager.inAnonymousMode())


        case "launch":
            let args = call.arguments as? [String: Any]
            if let data = args {
                let label = data["label"] as? String
                let urlString = data["url"] as? String
                
                let campaignLaunchHandler = { (success: Bool, error: Error?) in
                    result(handleLaunchCampaignResult(success: success, error: error))
                }
                
                let paywallActionHandler = { (paywallEvent: NamiPaywallEvent) in
                    NamiFlutterCache.paywallActionCallback?(paywallEvent)
                    return
                }
                
                if (label != nil) {
                    NamiCampaignManager.launch(label: label, launchHandler: campaignLaunchHandler, paywallActionHandler: paywallActionHandler)
                }
                else if (urlString != nil) {
                   if let url = URL(string: urlString!){
                    NamiCampaignManager.launch(url:url, launchHandler: campaignLaunchHandler, paywallActionHandler: paywallActionHandler)
                   }
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
            let args = call.arguments as? [String: Any?]
            var isAvailable = false
            if let data = args {
                let label = data["label"] as? String
                let urlData = data["url"] as? String
                if let label = label {
                    isAvailable = NamiCampaignManager.isCampaignAvailable(label: label)
                } else if let urlData = urlData, let url = URL(string: urlData){
                    isAvailable = NamiCampaignManager.isCampaignAvailable(url:url)
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

        case "buySkuComplete":
            if let data = call.arguments as? [String:Any?],
                let product = data["product"] as? [String: Any?],
                let transactionID = data["transactionID"] as? String,
                let originalTransactionID = data["originalTransactionID"] as? String,
                let price = data["price"] as? String,
                let decimalPrice = Decimal(string: price),
                let currencyCode = data["currencyCode"] as? String,
                let skuProduct = product.convertToNamiSku() {
                
                let namiPurchaseSuccess = NamiPurchaseSuccess(
                    product: skuProduct,
                    transactionID: transactionID,
                    originalTransactionID: originalTransactionID,
                    price: decimalPrice,
                    currencyCode: currencyCode
                )
                NamiPaywallManager.buySkuComplete(purchaseSuccess: namiPurchaseSuccess)
                result(true);
            }
            
        case "buySkuCancel":
            NamiPaywallManager.buySkuCancel()
            
            
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
        case "allPurchases":
            let allPurchases = NamiPurchaseManager.allPurchases()
            let listofMaps = allPurchases.map({ (namiPurchase: NamiPurchase) in namiPurchase.convertToMap()})
            result(listofMaps)
        case "skuPurchased":
            let args = call.arguments as? String
            if let skuId = args {
            Task {
                let success = await NamiPurchaseManager.skuPurchased(skuId)
                 result(success)
            }
            }
        case "anySkuPurchased":
            let args = call.arguments as? [String]
            if let skuIds = args {
               Task {
                   let success = await NamiPurchaseManager.anySkuPurchased(skuIds)
                         result(success)
                    }
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
    
    class RestorePaywallEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiPaywallManager.registerRestoreHandler {
                // TODO: Figure out what the right thing to do here is.
                events(true)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiPaywallManager.registerRestoreHandler(nil)
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
                events(sku.convertToMap())
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
            NamiFlutterCache.paywallActionCallback = { (paywallEvent: NamiPaywallEvent) in
                events(self.handlePaywallEvent(event: paywallEvent))
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            return nil
        }
        
        private func handlePaywallEvent(event: NamiPaywallEvent) -> [String: Any?] {
            var map = [String: Any?]()
            map["action"] = event.action.toFlutterString()
            map["campaignId"] = event.campaignId
            map["campaignName"] = event.campaignName
            map["campaignType"] = event.campaignType.toFlutterString()
            map["campaignLabel"] = event.campaignLabel
            map["campaignUrl"] = event.campaignUrl
            map["paywallId"] = event.paywallId
            map["paywallName"] = event.paywallName
            map["componentChange"] = event.componentChange?.convertToMap()
            map["segmentId"] = event.segmentId
            map["externalSegmentId"] = event.externalSegmentId
            map["deeplinkUrl"] = event.externalSegmentId
            map["sku"] = event.sku?.convertToMap()
            map["purchaseError"] = event.purchaseError
            map["purchases"] = event.purchases.map({ $0.convertToMap() })
            map["videoMetadata"] = event.videoMetadata?.convertToMap()
            map["timeSpentOnPaywall"] = event.timeSpentOnPaywall

            return map
        }
    }
}

public extension NamiPaywallEventComponentChange {
    func convertToMap() -> [String: Any?] {
        var map = [String: Any?]()
        
        map["id"] = id
        map["name"] = name
        
        return map
    }
}

public extension AccountStateAction {
    func toFlutterString() -> String {
        switch self {
        case AccountStateAction.login:
            return "login"
        case AccountStateAction.logout:
            return "logout"
        case  AccountStateAction.advertising_id_set:
            return "advertising_id_set"
        case  AccountStateAction.advertising_id_cleared:
            return "advertising_id_cleared"
        case  AccountStateAction.vendor_id_set:
            return "vendor_id_set"
        case  AccountStateAction.vendor_id_cleared:
            return "vendor_id_cleared"
        case  AccountStateAction.customer_data_platform_id_set:
            return "customer_data_platform_id_set"
        case  AccountStateAction.customer_data_platform_id_cleared:
            return "customer_data_platform_id_cleared"
        case AccountStateAction.anonymous_mode_on:
            return "anonymous_mode_on"
        case AccountStateAction.anonymous_mode_off:
            return "anonymous_mode_off"
        case AccountStateAction.nami_device_id_set:
            return "nami_device_id_set"
        case AccountStateAction.nami_device_id_cleared:
            return "nami_device_id_cleared"
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
        case NamiPaywallAction.purchase_success:
            return "NAMI_PURCHASE_SUCCESS"
        case NamiPaywallAction.purchase_deferred:
            return "NAMI_PURCHASE_DEFERRED"
        case NamiPaywallAction.purchase_failed:
            return "NAMI_PURCHASE_FAILED"
        case NamiPaywallAction.purchase_cancelled:
            return "NAMI_PURCHASE_CANCELLED"
        case NamiPaywallAction.purchase_pending:
            return "NAMI_PURCHASE_PENDING"
        case NamiPaywallAction.purchase_unknown:
            return "NAMI_PURCHASE_UNKNOWN"
        case NamiPaywallAction.deeplink:
            return "NAMI_DEEP_LINK"
        case NamiPaywallAction.toggle_change:
            return "NAMI_TOGGLE_CHANGE"
        case NamiPaywallAction.page_change:
            return "NAMI_PAGE_CHANGE"
        case NamiPaywallAction.slide_change:
            return "NAMI_SLIDE_CHANGE"
        case NamiPaywallAction.nami_reload_products:
            return "NAMI_RELOAD_PRODUCTS"
        case NamiPaywallAction.nami_collapsible_drawer_open:
            return "NAMI_COLLAPSIBLE_DRAWER_OPEN"
        case NamiPaywallAction.nami_collapsible_drawer_close:
            return "NAMI_COLLAPSIBLE_DRAWER_CLOSE"
        case NamiPaywallAction.video_play:
            return "NAMI_PLAY_VIDEO"
        case NamiPaywallAction.video_pause:
            return "NAMI_PAUSE_VIDEO"
        case NamiPaywallAction.video_resume:
            return "NAMI_VIDEO_RESUMED"
        case NamiPaywallAction.video_end:
            return "NAMI_VIDEO_ENDED"
        case NamiPaywallAction.video_change:
            return "NAMI_VIDEO_CHANGED"
        case NamiPaywallAction.video_mute:
            return "NAMI_VIDEO_MUTED"
        case NamiPaywallAction.video_unmute:
            return "NAMI_VIDEO_UNMUTED"
        default:
            return "unknown"
        }
    }
}

public extension NamiCampaignType {
    func toFlutterString() -> String {
        switch self {
        case NamiCampaignType.default:
            return "DEFAULT"
        case NamiCampaignType.label:
            return "LABEL"
        case NamiCampaignType.url:
            return "URL"
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

public extension NamiPaywallEventVideoMetadata{
    func convertToMap() -> [String: Any]{
        var map = [String: Any]()
        map["id"] = self.id
        map["name"] = self.name
        map["url"] = self.url
        map["loopVideo"] = self.loopVideo
        map["muteByDefault"] = self.muteByDefault
        map["autoplayVideo"] = self.autoplayVideo
        map["contentTimecode"] = self.contentTimecode
        map["contentDuration"] = self.contentDuration
        return map
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
        var map: [String: Any] = [:]
        map["paywall"] = self.paywall
        map["segment"] = self.segment
        if(self.type == NamiCampaignType.default) {
            map["type"] = "DEFAULT"
        } else if (self.type == NamiCampaignType.label) {
            map["type"] = "LABEL"
        } else if (self.type == NamiCampaignType.url) {
            map["type"] = "URL"
        } else {
            map["type"] = "LABEL"
        }
        map["value"] = self.value
        return map
    }
}

public extension String{
    func convertToNamiSKYType() -> NamiSKUType {
        if self == "one_time_purchase" {
            return NamiSKUType.one_time_purchase
        } else if self == "subscription" {
            return NamiSKUType.subscription
        } else {
            return NamiSKUType.unknown
        }
    }
}

public extension [String: Any?] {
    func convertToNamiSku() -> NamiSKU? {
        if let skuId = self["skuId"] as? String,
           let type = self["type"] as? String  {
            let id = self["id"] as? String
            return NamiSKU(namiId: id ?? UUID().uuidString, storeId: skuId, skuType: type.convertToNamiSKYType())
        }
        return nil
    }
}
