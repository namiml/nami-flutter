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
        let purchaseChangeEventChannel = FlutterEventChannel(name: "purchaseChangeEvent", binaryMessenger: registrar.messenger())
        let customerJourneyChangeEventChannel = FlutterEventChannel(name: "customerJourneyChangeEvent", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNamiSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        signInEventChannel.setStreamHandler(SignInEventHandler())
        analyticsEventChannel.setStreamHandler(AnalyticsEventHandler())
        entitlementChangeEventChannel.setStreamHandler(EntitlementChangeEventHandler())
        paywallRaiseEventChannel.setStreamHandler(PaywallRaiseEventHandler())
        purchaseChangeEventChannel.setStreamHandler(PurchaseChangeEventHandler())
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
               let developmentMode = myArgs["developmentMode"] as? Bool,
               let passiveMode = myArgs["passiveMode"] as? Bool,
               let namiLogLevel = myArgs["namiLogLevel"] as? String,
               let namiCommands = myArgs["extraDataList"] as? Array<String> {
                let namiConfig = NamiConfiguration(appPlatformID: appPlatformID)
                namiConfig.bypassStore = bypassStore
                namiConfig.developmentMode = developmentMode
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
               let type = myArgs["type"] as? String {
                if(type == "uuid") {
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
        case "preparePaywallForDisplay":
            let args = call.arguments as? [String: Any]
            if let data = args {
                let developerPaywallId = data["developerPaywallId"] as? String
                let imageRequired = data["backgroundImageRequired"] as? Bool ?? false
                let timeout = data["imageFetchTimeout"] as? Int
                let preparePaywallHandler = { (success: Bool, error: Error?) in
                    result(handlePreparePaywallHandler(success: success, error: error))
                }
                if(developerPaywallId == nil) {
                    if(timeout == nil) {
                        NamiPaywallManager.preparePaywallForDisplay(backgroundImageRequired: imageRequired,prepareHandler:preparePaywallHandler)
                    } else {
                        NamiPaywallManager.preparePaywallForDisplay(backgroundImageRequired: imageRequired, imageFetchTimeout:Double(timeout!),prepareHandler: preparePaywallHandler)
                    }
                } else {
                    if(timeout == nil) {
                        NamiPaywallManager.preparePaywallForDisplay(developerPaywallID: developerPaywallId!, backgroundImageRequired: imageRequired, prepareHandler: preparePaywallHandler)
                    } else {
                        NamiPaywallManager.preparePaywallForDisplay(developerPaywallID: developerPaywallId!, backgroundImageRequired: imageRequired, imageFetchTimeout:Double(timeout!),prepareHandler: preparePaywallHandler)
                    }
                }
            }
        case "processSmartText":
            let args = call.arguments as? [String: Any]
            if let data = args {
                let text = data["text"] as? String
                let dataStores = (data["dataStores"] as? Array<Any>)!
                result(NamiPaywallManager.processSmartText(text: text!, dataStores: dataStores))
            }
        case "raisePaywall":
            // https://github.com/flutter/flutter/issues/9961
            // https://github.com/flutter/flutter/issues/44764
            let viewController = UIApplication.shared.delegate!.window!!.rootViewController!
            let developerPaywallID = call.arguments as? String
            if(developerPaywallID == nil) {
                NamiPaywallManager.raisePaywall(fromVC: viewController)
            } else {
                NamiPaywallManager.raisePaywall(developerPaywallID: developerPaywallID!, fromVC: viewController)
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
        case "blockPaywallAutoRaise":
            let blockPaywallFromRaising = call.arguments as? Bool ?? false
            NamiPaywallManager.registerAllowAutoRaisePaywallHandler { () -> Bool in
                return !blockPaywallFromRaising
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
        case "paywallImpression":
            let args = call.arguments as? String
            if let developerPaywallId = args {
                NamiPaywallManager.paywallImpression(developerID: developerPaywallId)
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
        
        func handlePreparePaywallHandler(success: Bool, error: Error?) -> [String: Any?] {
            var map = [String: Any?]()
            map["success"] = success
            if let error = error as NSError? {
                if(error.code == 0) {
                    map["error"] = "paywall_already_displayed"
                } else if(error.code == 1) {
                    map["error"] = "data_not_available"
                } else if(error.code == 2) {
                    map["error"] = "no_live_campaign"
                } else if(error.code == 3) {
                    map["error"] = "image_load_failed"
                } else if(error.code == 4) {
                    map["error"] = "developer_paywall_id_not_found"
                } else if(error.code == 5) {
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
    
    class PaywallRaiseEventHandler: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            NamiPaywallManager.registerPaywallRaiseHandler  { (_, skus: [NamiSKU]?, developerPaywallId: String, namiPaywall: NamiPaywall) in
                var eventMap = [String : Any]()
                eventMap["namiPaywall"] = namiPaywall.convertToMap()
                var list = [[String: Any]]()
                skus?.forEach { (sku: NamiSKU) in
                    list.append(sku.convertToMap())
                }
                eventMap["skus"] = list
                eventMap["developerPaywallId"] = developerPaywallId
                events(eventMap)
            }
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            NamiPaywallManager.registerPaywallRaiseHandler(nil)
            return nil
        }
    }
    
    class PurchaseChangeEventHandler: NSObject, FlutterStreamHandler {
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

public extension NamiPaywall {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["id"] = self.paywallID
        map["developerPaywallId"] = self.developerPaywallID
        let backgrounds: [String: Any]? = self.paywallValue(forKey: NamiPaywallKeys.backgrounds)
        map["backgroundImageUrlPhone"] = backgrounds?[NamiPaywallBackgroundsKeys.phone.rawValue]
        map["backgroundImageUrlTablet"] = backgrounds?[NamiPaywallBackgroundsKeys.tablet.rawValue]
        map["name"] = self.paywallValue(forKey: NamiPaywallKeys.name)
        map["title"] = self.title
        map["body"] = self.body
        map["legalCitations"] = self.paywallValue(forKey: NamiPaywallKeys.legal_citations)
        map["displayOptions"] = self.paywallValue(forKey: NamiPaywallKeys.display_options)
        map["purchaseTerms"] = self.purchaseTerms
        map["type"] = self.paywallValue(forKey: NamiPaywallKeys.type)
        map["extraData"] = self.paywallValue(forKey: NamiPaywallKeys.marketing_content)
        map["styleData"] = self.styleData.convertToMap()
        map["namiSkus"] = self.paywallValue(forKey: NamiPaywallKeys.skus)
        map["localeConfig"] = self.paywallValue(forKey: NamiPaywallKeys.locale_config)
        return map
    }
}

public extension PaywallStyleData {
    func convertToMap() -> [String: Any] {
        var map = [String: Any]()
        map["bodyFontSize"] = bodyFontSize
        map["bodyTextColor"] = bodyTextColor.toHexString()
        map["titleFontSize"] = titleFontSize
        map["backgroundColor"] = backgroundColor.toHexString()
        map["skuButtonColor"] = skuButtonColor.toHexString()
        map["skuButtonTextColor"] = skuButtonTextColor.toHexString()
        map["skuSubDisplayTextColor"] = skuSubDisplayTextColor.toHexString()
        map["skuSubDisplayTextShadowColor"] = skuSubDisplayShadowColor.toHexString()
        map["skuSubDisplayTextShadowRadius"] = skuSubDisplayShadowRadius
        map["termsLinkColor"] = termsLinkColor.toHexString()
        map["titleTextColor"] = titleTextColor.toHexString()
        map["bodyShadowColor"] = bodyShadowColor.toHexString()
        map["bodyShadowRadius"] = bodyShadowRadius
        map["titleShadowColor"] = titleShadowColor.toHexString()
        map["titleShadowRadius"] = titleShadowRadius
        map["bottomOverlayColor"] = bottomOverlayColor.toHexString()
        map["bottomOverlayCornerRadius"] = bottomOverlayCornerRadius
        map["closeButtonFontSize"] = closeButtonFontSize
        map["closeButtonTextColor"] = closeButtonTextColor.toHexString()
        map["closeButtonShadowColor"] = closeButtonShadowColor.toHexString()
        map["closeButtonShadowRadius"] = closeButtonShadowRadius
        map["signInButtonFontSize"] = signinButtonFontSize
        map["signInButtonTextColor"] = signinButtonTextColor.toHexString()
        map["signInButtonShadowColor"] = signinButtonShadowColor.toHexString()
        map["signInButtonShadowRadius"] = signinButtonShadowRadius
        map["purchaseTermsFontSize"] = purchaseTermsFontSize
        map["purchaseTermsTextColor"] = purchaseTermsTextColor.toHexString()
        map["purchaseTermsShadowColor"] = purchaseTermsShadowColor.toHexString()
        map["purchaseTermsShadowRadius"] = purchaseTermsShadowRadius
        map["restoreButtonFontSize"] = restoreButtonFontSize
        map["restoreButtonTextColor"] = restoreButtonTextColor.toHexString()
        map["restoreButtonShadowColor"] = restoreButtonShadowColor.toHexString()
        map["restoreButtonShadowRadius"] = restoreButtonShadowRadius
        map["featuredSkuButtonColor"] = featuredSkusButtonColor.toHexString()
        map["featuredSkuButtonTextColor"] = featuredSkusButtonTextColor.toHexString()
        return map
    }
}

public extension UIColor {
    func toHexString() -> String {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
}
