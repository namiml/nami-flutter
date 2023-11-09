package com.namiml.flutter.sdk

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.amazon.device.iap.model.Product
import com.android.billingclient.api.ProductDetails
import com.namiml.Nami
import com.namiml.NamiConfiguration
import com.namiml.NamiLanguageCode
import com.namiml.NamiLogLevel
import com.namiml.NamiError
import com.namiml.billing.NamiPurchase
import com.namiml.billing.NamiPurchaseCompleteResult
import com.namiml.billing.NamiPurchaseManager
import com.namiml.billing.NamiPurchaseState
import com.namiml.campaign.NamiCampaignManager
import com.namiml.paywall.model.NamiPaywallEvent
import com.namiml.campaign.LaunchCampaignError
import com.namiml.campaign.LaunchCampaignResult
import com.namiml.customer.CustomerJourneyState
import com.namiml.customer.NamiCustomerManager
import com.namiml.customer.AccountStateAction
import com.namiml.entitlement.NamiEntitlement
import com.namiml.entitlement.NamiEntitlementManager
import com.namiml.entitlement.NamiPlatformType
import com.namiml.ml.NamiMLManager
import com.namiml.paywall.LegalCitations
import com.namiml.paywall.NamiLocaleConfig
import com.namiml.paywall.NamiPaywall
import com.namiml.paywall.NamiPaywallManager
import com.namiml.paywall.NamiPurchaseSource
import com.namiml.paywall.NamiSKU
import com.namiml.paywall.NamiSKUType
import com.namiml.paywall.PaywallDisplayOptions
import com.namiml.paywall.PaywallStyleData
import com.namiml.paywall.PreparePaywallError
import com.namiml.paywall.SubscriptionPeriod
import com.namiml.paywall.model.NamiPaywallAction
import com.namiml.campaign.NamiCampaign
import com.namiml.paywall.model.NamiPaywallComponentChange
import com.namiml.paywall.model.NamiPurchaseSuccess
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.lang.ref.WeakReference
import java.util.Date
import java.util.logging.StreamHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.LocalDate
import android.net.Uri;
import com.namiml.flutter.sdk.convertToMap


/** FlutterNamiSdkPlugin */
class FlutterNamiSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var signInListener: EventChannel
    private lateinit var activeEntitlementsListener: EventChannel
    private lateinit var journeyStateListener: EventChannel
    private lateinit var purchaseChangeListener: EventChannel
    private lateinit var accountStateListener: EventChannel
    private lateinit var campaignsListener: EventChannel
    private lateinit var closePaywallListener: EventChannel
    private lateinit var buySkuListener: EventChannel
    private lateinit var paywallActionListener: EventChannel
    private lateinit var restorePaywallListener: EventChannel
    private lateinit var context: Context
    private var currentActivityWeakReference: WeakReference<Activity>? = null
    private var paywallActionCallback: ((NamiPaywallEvent) -> Unit)? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nami")
        signInListener = EventChannel(flutterPluginBinding.binaryMessenger, "signInEvent")
        activeEntitlementsListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "activeEntitlementsEvent")
        purchaseChangeListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "purchasesResponseHandlerData")
        journeyStateListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "journeyStateEvent")
        accountStateListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "accountStateEvent")
        campaignsListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "campaignsEvent")
        closePaywallListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "closePaywallEvent")
        buySkuListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "buySkuEvent")
        restorePaywallListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "restorePaywallEvent")
        paywallActionListener =
                EventChannel(flutterPluginBinding.binaryMessenger, "paywallActionEvent")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        setSignInStreamHandler()
        setRestorePaywallStreamHandler()
        setActiveEntitlementsStreamHandler()
        setPurchaseChangeStreamHandler()
        setCustomerJourneyStateHandler()
        setAccountStateHandler()
        setCampaignStreamHandler()
        setClosePaywallStreamHandler()
        setBuySkuStreamHandler()
        setPaywallActionStreamHandler()
    }

    private fun setPurchaseChangeStreamHandler() {
        purchaseChangeListener.setStreamHandler(object : StreamHandler(),
                EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiPurchaseManager.registerPurchasesChangedHandler { activePurchases, namiPurchaseState, errorMsg ->
                    val eventMap = mutableMapOf<String, Any?>()
                    eventMap["activePurchases"] = activePurchases.map { it.convertToMap() }
                    eventMap["purchaseState"] = namiPurchaseState.getFlutterString()
                    eventMap["error"] = errorMsg
                    events?.success(eventMap)
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiPurchaseManager.registerPurchasesChangedHandler(null)
            }
        })
    }

    private fun setSignInStreamHandler() {
        signInListener.setStreamHandler(object : StreamHandler(), EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiPaywallManager.registerSignInHandler { context ->
                    // TODO: Figure out what the right thing to do here is.
                    events?.success(true)
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiPaywallManager.registerSignInHandler(null)
            }
        })
    }

    private fun setRestorePaywallStreamHandler() {
        restorePaywallListener.setStreamHandler(object : StreamHandler(), EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiPaywallManager.registerRestoreHandler { context ->
                    CoroutineScope(Dispatchers.Main).launch {
                        events?.success(true)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiPaywallManager.registerRestoreHandler { null }
            }
        })
    }

    private fun setActiveEntitlementsStreamHandler() {
        activeEntitlementsListener.setStreamHandler(object : StreamHandler(),
                EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiEntitlementManager.registerActiveEntitlementsHandler { namiEntitlements ->
                    CoroutineScope(Dispatchers.Main).launch {
                        events?.success(namiEntitlements.map { it.convertToMap() })
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiEntitlementManager.registerActiveEntitlementsHandler(null)
            }
        })
    }

    private fun setCustomerJourneyStateHandler() {
        journeyStateListener.setStreamHandler(object : StreamHandler(),
                EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiCustomerManager.registerJourneyStateHandler { journeyState ->
                    CoroutineScope(Dispatchers.Main).launch {
                        events?.success(journeyState.convertToMap())
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiCustomerManager.registerJourneyStateHandler(null)
            }
        })
    }

    private fun setAccountStateHandler() {
        accountStateListener.setStreamHandler(object : StreamHandler(), EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiCustomerManager.registerAccountStateHandler { accountStateAction, success, error ->
                    val eventMap = mutableMapOf<String, Any?>()
                    eventMap["accountStateAction"] = accountStateAction.getFlutterString()
                    eventMap["success"] = success
                    if (error != null) {
                        eventMap["error"] = error.errorMessage
                    }
                    CoroutineScope(Dispatchers.Main).launch {
                        events?.success(eventMap)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiCustomerManager.registerAccountStateHandler(null)
            }
        })
    }

    private fun setCampaignStreamHandler() {
        campaignsListener.setStreamHandler(object : StreamHandler(),
                EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiCampaignManager.registerAvailableCampaignsHandler { namiCampaigns ->
                    CoroutineScope(Dispatchers.Main).launch {
                        events?.success(namiCampaigns.map { it.convertToMap() })
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiCampaignManager.registerAvailableCampaignsHandler {

                }
            }
        })
    }

    private fun setClosePaywallStreamHandler() {
        closePaywallListener.setStreamHandler(object : StreamHandler(),
                EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiPaywallManager.registerCloseHandler {
                    CoroutineScope(Dispatchers.Main).launch {
                        events?.success(null)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiPaywallManager.registerCloseHandler(null)
            }
        })
    }

    private fun setBuySkuStreamHandler() {
        buySkuListener.setStreamHandler(object : StreamHandler(),
                EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiPaywallManager.registerBuySkuHandler { _, sku ->
                    CoroutineScope(Dispatchers.Main).launch {
                        events?.success(sku.convertToMap())
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiPaywallManager.registerBuySkuHandler(null)
            }
        })
    }


    private fun setPaywallActionStreamHandler() {
        paywallActionListener.setStreamHandler(object : StreamHandler(),
                EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                paywallActionCallback = { namiPaywallEvent ->
                    CoroutineScope(Dispatchers.Main).launch {
                        events?.success(namiPaywallEvent.converToMap())
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
            }
        })
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "configure" -> {
                val namiLogLevel = when (call.argument<String>("namiLogLevel")) {
                    "warn" -> NamiLogLevel.WARN
                    "debug" -> NamiLogLevel.DEBUG
                    "info" -> NamiLogLevel.INFO
                    else -> NamiLogLevel.ERROR
                }
                configure(
                        context,
                        call.argument<String>("appPlatformIdAndroid"),
                        namiLogLevel,
                        call.argument<List<String>>("extraDataList")
                )
                result.success(true)
            }

            "login" -> {
                val withId = call.arguments as? String
                if (withId != null) {
                    NamiCustomerManager.login(withId)
                }
            }

            "logout" -> {
                NamiCustomerManager.logout()
            }

            "loggedInId" -> {
                result.success(NamiCustomerManager.loggedInId())
            }

            "isLoggedIn" -> {
                result.success(NamiCustomerManager.isLoggedIn())
            }

            "deviceId" -> {
                result.success(NamiCustomerManager.deviceId())
            }

            "setCustomerAttribute" -> {
                val data = call.arguments as? Map<String, String>
                data?.forEach {
                    NamiCustomerManager.setCustomerAttribute(it.key, it.value)
                }

            }

            "getCustomerAttribute" -> {
                val attributeName = call.arguments as? String
                if (attributeName != null) {
                    result.success(NamiCustomerManager.getCustomerAttribute(attributeName))
                }
            }

            "clearCustomerAttribute" -> {
                val attributeName = call.arguments as? String
                if (attributeName != null) {
                    result.success(NamiCustomerManager.clearCustomerAttribute(attributeName))
                }

            }

            "clearAllCustomerAttribute" -> {
                NamiCustomerManager.clearAllCustomerAttributes()
            }

            "setAnonymousMode" -> {
                var anonymousMode = call.arguments as? Boolean
                if(anonymousMode != null){
                    NamiCustomerManager.setAnonymousMode(anonymousMode)
                }
            }

            "isAnonymousMode" -> {
                result.success(NamiCustomerManager.inAnonymousMode())
            }

            "launch" -> {
                val callback = { launchResult: LaunchCampaignResult ->
                    when (launchResult) {
                        is LaunchCampaignResult.Success -> {
                            with(mapOf("success" to true, "error" to null)) {
                                result.success(this)
                            }
                        }

                        is LaunchCampaignResult.Failure -> {
                            val error = launchResult.error as? LaunchCampaignError
                            with(mapOf("success" to false, "error" to error?.getFlutterString())) {
                                result.success(this)
                            }
                        }
                    }
                }


                val actionCallback = { namiPaywallEvent: NamiPaywallEvent ->
                    paywallActionCallback?.invoke(namiPaywallEvent)
                    Unit
                }
                val label = call.argument<String?>("label") ?: ""
                val url = call.argument<String?>("url")

                currentActivityWeakReference?.get()?.let { activity ->
                    NamiCampaignManager.launch(
                            activity,
                            label,
                            actionCallback,
                            null,
                            if (url != null) Uri.parse(url) else null,
                            callback
                    )
                }
            }

            "buySkuComplete" -> {
                val data = call.arguments as Map<String, Any?>
                val product = data["product"] as Map<String, Any?>
                val expiresDate = data["expiresDate"] as String?
                val purchaseDate = data["purchaseDate"] as String
                val purchaseSuccess =
                        NamiPurchaseSuccess.GooglePlay(
                                product = product.convertToNamiSKU(),
                                orderId = data["orderId"] as String,
                                purchaseToken = data["purchaseToken"] as String
                        )

                currentActivityWeakReference?.get()?.let { activity ->
                    NamiPaywallManager.buySkuComplete(activity, purchaseSuccess = purchaseSuccess)
                }
            }

            "buySkuCancel" -> {
                NamiPaywallManager.buySkuCancel()
            }

            "allCampaigns" -> {
                result.success(
                        NamiCampaignManager.allCampaigns().map { it.convertToMap() }
                )
            }

            "campaigns.refresh" -> {
                NamiCampaignManager.refresh { campaigns ->
                    result.success(campaigns?.map { it.convertToMap() })
                }
            }

            "isCampaignAvailable" -> {
                val data = call.arguments as Map<String, Any?>

                val label = data["label"] as String?
                val url = data["url"] as String?
                result.success(
                        if (label != null) {
                            NamiCampaignManager.isCampaignAvailable(label = label)
                        } else if (url != null) {
                            val uri = Uri.parse(url)
                            NamiCampaignManager.isCampaignAvailable(uri = uri)
                        } else {
                            NamiCampaignManager.isCampaignAvailable()
                        }
                )
            }

            "dismiss" -> {
                result.notImplemented()
            }

            "journeyState" -> {
                val stateMap = NamiCustomerManager.journeyState()?.convertToMap()
                result.success(stateMap)
            }

            "isEntitlementActive" -> {
                result.success(NamiEntitlementManager.isEntitlementActive(call.arguments as String))
            }

            "active" -> {
                result.success(
                        NamiEntitlementManager.active().map { it.convertToMap() })
            }

            "refresh" -> {
                NamiEntitlementManager.refresh() {
                    result.success(it)
                }
            }

            "coreAction" -> {
                @Suppress("UNCHECKED_CAST")
                val label = call.arguments as? String
                label?.let {
                    NamiMLManager.coreAction(it)
                }
            }

            "enterCoreContent" -> {
                @Suppress("UNCHECKED_CAST")
                val labels = call.arguments as? List<String>
                labels?.let {
                    NamiMLManager.enterCoreContent(it)
                }
            }

            "exitCoreContent" -> {
                @Suppress("UNCHECKED_CAST")
                val labels = call.arguments as? List<String>
                labels?.let {
                    NamiMLManager.exitCoreContent(it)
                }
            }

            "clearBypassStorePurchases" -> {
                NamiPurchaseManager.clearBypassStorePurchases()
            }

            "allPurchases" -> {
                result.success(NamiPurchaseManager.allPurchases().map { it.convertToMap() })
            }

            "skuPurchased" -> {
                val skuId = call.arguments as? String
                skuId?.let {
                    result.success(NamiPurchaseManager.isSKUIDPurchased(it))
                }
            }

            "anySkuPurchased" -> {
                @Suppress("UNCHECKED_CAST")
                val skuIds = call.arguments as? List<String>
                skuIds?.let {
                    result.success(NamiPurchaseManager.anySKUIDPurchased(it))
                }
            }

            "consumePurchasedSku" -> {
                val skuRefId = call.arguments as? String
                if (skuRefId != null) {
                    NamiPurchaseManager.consumePurchasedSKU(skuRefId)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun configure(
            context: Context,
            platformId: String?,
            namiLogLevel: NamiLogLevel,
            extraDataList: List<String>?
    ) {
        if (platformId == null) {
            return
        }

        val configuration = NamiConfiguration.build(context, platformId) {
            this.logLevel = namiLogLevel
            this.settingsList = extraDataList
        }
        Nami.configure(configuration)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        signInListener.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivityWeakReference = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        currentActivityWeakReference = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivityWeakReference = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {
        currentActivityWeakReference = null
    }
}

private fun CustomerJourneyState.convertToMap(): Map<String, Boolean> {
    return mapOf(
            "former_subscriber" to formerSubscriber,
            "in_grace_period" to inGracePeriod,
            "in_trial_period" to inTrialPeriod,
            "in_intro_offer_period" to inIntroOfferPeriod,
            "is_cancelled" to isCancelled,
            "in_pause" to inPause,
            "in_account_hold" to inAccountHold
    )
}


private fun NamiPurchaseCompleteResult.convertToMap(): Map<String, Any?> {
    val purchaseState = if (isSuccessful) {
        "purchased"
    } else {
        "failed"
    }
    return hashMapOf("purchaseState" to purchaseState, "error" to this.message)
}

private fun NamiEntitlement.convertToMap(): Map<String, Any?> {
    return hashMapOf(
            "name" to name,
            "desc" to desc,
            "namiId" to namiId,
            "referenceId" to referenceId,
            "relatedSKUs" to relatedSKUs.map { it.convertToMap() },
            "purchasedSKUs" to purchasedSKUs.map { it.convertToMap() },
            "activePurchases" to activePurchases.map { it.convertToMap() })
}


private fun NamiCampaign.convertToMap(): Map<String, Any?> {
    return mapOf(
            "paywall" to paywall,
            "segment" to segment,
            "type" to type.name,
            "value" to value
    )
}

private fun NamiPurchase.convertToMap(): Map<String, Any?> {
    return hashMapOf(
            "purchaseInitiatedTimestamp" to purchaseInitiatedTimestamp,
            "expires" to expires?.time,
            "purchaseSource" to purchaseSource.getFlutterString(),
            "skuId" to skuId,
            "transactionIdentifier" to transactionIdentifier,
            "localizedDescription" to localizedDescription
    )
}

private fun NamiPaywallEvent.converToMap(): Map<String, Any?> {
    return hashMapOf<String, Any?>(
            "action" to this.action.name,
            "campaignId" to this.campaignId,
            "campaignName" to this.campaignName,
            "campaignType" to this.campaignType,
            "campaignLabel" to this.campaignLabel,
            "campaignUrl" to this.campaignUrl,
            "paywallId" to this.paywallId,
            "paywallName" to this.paywallName,
            "componentChange" to this.componentChange?.convertToMap(),
            "segmentId" to this.segmentId,
            "externalSegmentid" to this.externalSegmentId,
            "deeplinkUrl" to this.deeplinkUrl,
            "sku" to this.sku?.convertToMap(),
            "purchaseError" to this.purchaseError,
            "purchases" to this.purchases?.map { it.convertToMap() },
            "skus" to this.skus?.map { it.convertToMap() }
    )
}

private fun NamiPurchaseSource.getFlutterString(): String {
    return when (this) {
        NamiPurchaseSource.CAMPAIGN -> "campaign"
        NamiPurchaseSource.MARKETPLACE -> "marketplace"
        NamiPurchaseSource.UNKNOWN -> "unknown"
        else -> ""
    }
}

private fun AccountStateAction.getFlutterString(): String {
    return when (this) {
        AccountStateAction.LOGIN -> "login"
        AccountStateAction.LOGOUT -> "logout"
        AccountStateAction.ADVERTISING_ID_SET -> "advertising_id_set"
        AccountStateAction.ADVERTISING_ID_CLEARED -> "advertising_id_cleared"
        AccountStateAction.VENDOR_ID_SET -> "vendor_id_set"
        AccountStateAction.VENDOR_ID_CLEARED -> "vendor_id_cleared"
        AccountStateAction.CUSTOMER_DATA_PLATFORM_ID_SET -> "customer_data_platform_id_set"
        AccountStateAction.CUSTOMER_DATA_PLATFORM_ID_CLEARED -> "customer_data_platform_id_cleared"
        AccountStateAction.NAMI_DEVICE_ID_SET -> "nami_device_id_set"
        AccountStateAction.NAMI_DEVICE_ID_CLEARED -> "nami_device_id_cleared"
        AccountStateAction.ANONYMOUS_MODE_ON -> "anonymous_mode_on"
        AccountStateAction.ANONYMOUS_MODE_OFF -> "anonymous_mode_off"
        else -> "unknown"
    }
}


private fun NamiSKU.convertToMap(): Map<String, Any?> {
    return hashMapOf(
            "name" to this.name,
            "skuId" to this.skuId,
            "type" to this.type.getFlutterString(),
    )
}


private fun Map<String, Any?>.convertToNamiSKU(): NamiSKU {
    return NamiSKU(
            skuId = this["skuId"] as String,
            productDetails = null,
            amazonProduct = null,
            id = this["id"] as String?,
            type = NamiSKUType.valueOf(this["type"] as String),
            name = this["name"] as String,
            featured = false,
            rawDisplayText = null,
            rawSubDisplayText = null,
            entitlements = emptyList(),
            variables = null,
            promoId = null
    )
}


private fun NamiPaywallComponentChange.convertToMap(): Map<String, Any?> {
    return hashMapOf(
            "id" to this.id,
            "name" to this.name,
    )
}

private fun NamiSKUType.getFlutterString(): String {
    return when (this) {
        NamiSKUType.ONE_TIME_PURCHASE -> "one_time_purchase"
        NamiSKUType.UNKNOWN -> "unknown"
        NamiSKUType.SUBSCRIPTION -> "subscription"
    }
}

private fun PreparePaywallError?.getFlutterString(): String? {
    return when (this) {
        PreparePaywallError.PAYWALL_DATA_NOT_FOUND -> "paywall_data_not_found"
        PreparePaywallError.PAYWALL_IMAGE_LOAD_FAILED -> "image_load_failed"
        PreparePaywallError.PAYWALL_DATA_NOT_AVAILABLE -> "paywall_data_not_available"
        PreparePaywallError.NO_LIVE_CAMPAIGN -> "no_live_campaign"
        PreparePaywallError.PLAY_BILLING_NOT_AVAILABLE -> "play_billing_not_available"
        else -> null
    }
}

private fun SubscriptionPeriod.getFlutterString(): String {
    return when (this) {
        SubscriptionPeriod.WEEKLY -> "week"
        SubscriptionPeriod.MONTHLY -> "month"
        SubscriptionPeriod.ANNUAL -> "year"
        SubscriptionPeriod.QUARTERLY -> "quarter"
        SubscriptionPeriod.HALF_YEAR -> "half_year"
        SubscriptionPeriod.FOUR_WEEKS -> "four_weeks"
    }
}

private fun NamiPurchaseState.getFlutterString(): String {
    return when (this) {
        NamiPurchaseState.CANCELLED -> "cancelled"
        NamiPurchaseState.FAILED -> "failed"
        NamiPurchaseState.PURCHASED -> "purchased"
        // TODO Add PENDING HERE
        else -> "unknown"
    }
}

private fun LaunchCampaignError.getFlutterString(): String {
    return when (this) {
        LaunchCampaignError.SDK_NOT_INITIALIZED -> "sdk_not_initialized"
        LaunchCampaignError.DEFAULT_CAMPAIGN_NOT_FOUND -> "default_campaign_not_found"
        LaunchCampaignError.LABELED_CAMPAIGN_NOT_FOUND -> "labeled_campaign_not_found"
        LaunchCampaignError.PAYWALL_ALREADY_DISPLAYED -> "paywall_already_displayed"
        LaunchCampaignError.CAMPAIGN_DATA_NOT_FOUND -> "campaign_data_not_found"
        else -> "unknown"
    }
}