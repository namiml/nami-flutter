package com.namiml.flutter.sdk

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.namiml.Nami
import com.namiml.NamiConfiguration
import com.namiml.NamiLanguageCode
import com.namiml.NamiLogLevel
import com.namiml.NamiError
import com.namiml.analytics.NamiAnalyticsActionType
import com.namiml.analytics.NamiAnalyticsKeys
import com.namiml.analytics.NamiAnalyticsPurchaseActivityType
import com.namiml.analytics.NamiAnalyticsSupport
import com.namiml.billing.NamiPurchase
import com.namiml.billing.NamiPurchaseCompleteResult
import com.namiml.billing.NamiPurchaseManager
import com.namiml.billing.NamiPurchaseState
import com.namiml.campaign.NamiCampaignManager
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
import com.namiml.util.extensions.getFormattedPrice
import com.namiml.util.extensions.getSubscriptionPeriodEnum
import com.squareup.moshi.Moshi
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

/** FlutterNamiSdkPlugin */
class FlutterNamiSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var signInListener: EventChannel
    private lateinit var analyticsListener: EventChannel
    private lateinit var activeEntitlementsListener: EventChannel
    private lateinit var journeyStateListener: EventChannel
    private lateinit var purchaseChangeListener: EventChannel
    private lateinit var accountStateListener: EventChannel
    private lateinit var context: Context
    private lateinit var moshi: Moshi
    private var currentActivityWeakReference: WeakReference<Activity>? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        moshi = Moshi.Builder().build()
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nami")
        signInListener = EventChannel(flutterPluginBinding.binaryMessenger, "signInEvent")
        analyticsListener = EventChannel(flutterPluginBinding.binaryMessenger, "analyticsEvent")
        activeEntitlementsListener =
            EventChannel(flutterPluginBinding.binaryMessenger, "activeEntitlementsEvent")
        purchaseChangeListener =
            EventChannel(flutterPluginBinding.binaryMessenger, "purchasesResponseHandlerData")
        journeyStateListener =
            EventChannel(flutterPluginBinding.binaryMessenger, "journeyStateEvent")
        accountStateListener =
            EventChannel(flutterPluginBinding.binaryMessenger, "accountStateEvent")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        setSignInStreamHandler()
        setAnalyticsStreamHandler()
        setActiveEntitlementsStreamHandler()
        setPurchaseChangeStreamHandler()
        setCustomerJourneyStateHandler()
        setAccountStateHandler()
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

    private fun setAnalyticsStreamHandler() {
        analyticsListener.setStreamHandler(object : StreamHandler(), EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiAnalyticsSupport.registerAnalyticsHandler { namiAnalyticsActionType, map ->
                    val finalMap = HashMap(map)
                    finalMap["type"] = namiAnalyticsActionType.getFlutterString()
                    @Suppress("UNCHECKED_CAST")
                    val skus = map[NamiAnalyticsKeys.PAYWALL_PRODUCTS] as? List<NamiSKU>
                    finalMap[NamiAnalyticsKeys.PAYWALL_PRODUCTS] = skus?.map { it.convertToMap() }
                    val purchasedProduct = map[NamiAnalyticsKeys.PURCHASE_PRODUCT] as? NamiSKU
                    finalMap[NamiAnalyticsKeys.PURCHASE_PRODUCT] = purchasedProduct?.convertToMap()
                    val activityType = map[NamiAnalyticsKeys.PURCHASE_ACTIVITY_TYPE]
                        as? NamiAnalyticsPurchaseActivityType
                    finalMap[NamiAnalyticsKeys.PURCHASE_ACTIVITY_TYPE] =
                        activityType?.getFlutterString()
                    events?.success(finalMap)
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiAnalyticsSupport.registerAnalyticsHandler(null)
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
                    call.argument<String>("appPlatformIdGoogle"),
                    call.argument<Boolean>("bypassStore"),
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
            "launch" -> {
                val callback = { launchResult: LaunchCampaignResult ->
                    when (launchResult) {
                        is LaunchCampaignResult.Success -> {
                            with(hashMapOf("success" to true, "error" to null)) {
                                result.success(this)
                            }
                        }
                        is LaunchCampaignResult.Failure -> {
                            val error = launchResult.error as LaunchCampaignError
                            with(hashMapOf("success" to false, "error" to error.getFlutterString())) {
                                result.success(this)
                            }
                        }
                    }
                }

                val label = call.argument<String>("label") ?: ""

                currentActivityWeakReference?.get()?.let { activity ->
                    NamiCampaignManager.launch(
                        activity,
                        label,
                        callback
                    )
                }
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
            "isSKUIDPurchased" -> {
                val skuId = call.arguments as? String
                skuId?.let {
                    result.success(NamiPurchaseManager.isSKUIDPurchased(it))
                }
            }
            "anySKUIDPurchased" -> {
                @Suppress("UNCHECKED_CAST")
                val skuIds = call.arguments as? List<String>
                skuIds?.let {
                    result.success(NamiPurchaseManager.anySKUIDPurchased(it))
                }
            }
            "buySKU" -> {
                val skuRefId = call.arguments as? String
                val activity = currentActivityWeakReference?.get()
                if (skuRefId != null && activity != null) {
                    NamiPurchaseManager.buySKU(activity, skuRefId) {
                        result.success(it.convertToMap())
                    }
                }
            }
            "consumePurchasedSKU" -> {
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
        bypass: Boolean?,
        namiLogLevel: NamiLogLevel,
        extraDataList: List<String>?
    ) {
        if (platformId == null) {
            return
        }
        val configuration = NamiConfiguration.build(context, platformId) {
            this.logLevel = namiLogLevel
            this.bypassStore = bypass ?: false
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
        // Do nothing
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
        else -> "unknown"
    }
}

private fun NamiAnalyticsPurchaseActivityType.getFlutterString(): String? {
    return when (this) {
        NamiAnalyticsPurchaseActivityType.NEW_PURCHASE -> "new_purchase"
        NamiAnalyticsPurchaseActivityType.RESTORE -> "restore"
        NamiAnalyticsPurchaseActivityType.RESUBSCRIBE -> "resubscribe"
        else -> null
    }
}

private fun NamiSKU.convertToMap(): Map<String, Any?> {
    return hashMapOf(
        "name" to this.skuDetails.name,
        "skuId" to this.skuId,
        "type" to this.type.getFlutterString(),
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

private fun NamiAnalyticsActionType.getFlutterString(): String {
    return when (this) {
        NamiAnalyticsActionType.PAYWALL_RAISE -> "paywall_raise"
        NamiAnalyticsActionType.PAYWALL_RAISE_BLOCKED -> "paywall_raise_blocked"
        NamiAnalyticsActionType.PURCHASE_ACTIVITY -> "purchase_activity"
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