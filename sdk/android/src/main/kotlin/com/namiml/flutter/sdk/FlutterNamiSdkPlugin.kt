package com.namiml.flutter.sdk

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.namiml.Nami
import com.namiml.NamiConfiguration
import com.namiml.NamiExternalIdentifierType
import com.namiml.NamiLanguageCode
import com.namiml.NamiLogLevel
import com.namiml.analytics.NamiAnalyticsActionType
import com.namiml.analytics.NamiAnalyticsKeys
import com.namiml.analytics.NamiAnalyticsPurchaseActivityType
import com.namiml.analytics.NamiAnalyticsSupport
import com.namiml.billing.NamiPurchase
import com.namiml.billing.NamiPurchaseCompleteResult
import com.namiml.billing.NamiPurchaseManager
import com.namiml.billing.NamiPurchaseState
import com.namiml.customer.CustomerJourneyState
import com.namiml.customer.NamiCustomerManager
import com.namiml.entitlement.NamiEntitlement
import com.namiml.entitlement.NamiEntitlementManager
import com.namiml.entitlement.NamiEntitlementSetter
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

/** FlutterNamiSdkPlugin */
class FlutterNamiSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var signInListener: EventChannel
    private lateinit var analyticsListener: EventChannel
    private lateinit var entitlementChangeListener: EventChannel
    private lateinit var customerJourneyChangeListener: EventChannel
    private lateinit var paywallRaiseListener: EventChannel
    private lateinit var purchaseChangeListener: EventChannel
    private lateinit var context: Context
    private lateinit var moshi: Moshi
    private var currentActivityWeakReference: WeakReference<Activity>? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        moshi = Moshi.Builder().build()
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nami")
        signInListener = EventChannel(flutterPluginBinding.binaryMessenger, "signInEvent")
        analyticsListener = EventChannel(flutterPluginBinding.binaryMessenger, "analyticsEvent")
        entitlementChangeListener =
            EventChannel(flutterPluginBinding.binaryMessenger, "entitlementChangeEvent")
        paywallRaiseListener =
            EventChannel(flutterPluginBinding.binaryMessenger, "paywallRaiseEvent")
        purchaseChangeListener =
            EventChannel(flutterPluginBinding.binaryMessenger, "purchaseChangeEvent")
        customerJourneyChangeListener =
            EventChannel(flutterPluginBinding.binaryMessenger, "customerJourneyChangeEvent")

        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        setSignInStreamHandler()
        setAnalyticsStreamHandler()
        setEntitlementStreamHandler()
        setPaywallRaiseStreamHandler()
        setPurchaseChangeStreamHandler()
        setCustomerJourneyChangeStreamHandler()
    }

    private fun setPurchaseChangeStreamHandler() {
        purchaseChangeListener.setStreamHandler(object : StreamHandler(),
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiPurchaseManager.registerPurchasesChangedListener { activePurchases, namiPurchaseState, errorMsg ->
                    val eventMap = mutableMapOf<String, Any?>()
                    eventMap["activePurchases"] = activePurchases.map { it.convertToMap() }
                    eventMap["purchaseState"] = namiPurchaseState.getFlutterString()
                    eventMap["error"] = errorMsg
                    events?.success(eventMap)
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiPurchaseManager.registerPurchasesChangedListener(null)
            }
        })
    }

    private fun setPaywallRaiseStreamHandler() {
        paywallRaiseListener.setStreamHandler(object : StreamHandler(), EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiPaywallManager.registerPaywallRaiseListener { _, namiPaywall, skus, developerPaywallId ->
                    val eventMap = mutableMapOf<String, Any?>()
                    eventMap["namiPaywall"] = namiPaywall.convertToMap()
                    eventMap["skus"] = skus?.map { it.convertToMap() }
                        ?: listOf<Map<String, Any?>>()
                    eventMap["developerPaywallId"] = developerPaywallId
                    events?.success(eventMap)
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiPaywallManager.registerPaywallRaiseListener(null)
            }
        })
    }

    private fun setSignInStreamHandler() {
        signInListener.setStreamHandler(object : StreamHandler(), EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiPaywallManager.registerSignInListener { _, namiPaywall, _ ->
                    events?.success(namiPaywall.convertToMap())
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiPaywallManager.registerSignInListener(null)
            }
        })
    }

    private fun setAnalyticsStreamHandler() {
        analyticsListener.setStreamHandler(object : StreamHandler(), EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiAnalyticsSupport.registerAnalyticsListener { namiAnalyticsActionType, map ->
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
                NamiAnalyticsSupport.registerAnalyticsListener(null)
            }
        })
    }

    private fun setEntitlementStreamHandler() {
        entitlementChangeListener.setStreamHandler(object : StreamHandler(),
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiEntitlementManager.registerEntitlementChangeListener { namiEntitlements ->
                    events?.success(namiEntitlements.map { it.convertToMap() })
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiEntitlementManager.registerEntitlementChangeListener(null)
            }
        })
    }

    private fun setCustomerJourneyChangeStreamHandler() {
        customerJourneyChangeListener.setStreamHandler(object : StreamHandler(),
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NamiCustomerManager.registerCustomerJourneyChangedListener { journeyState ->
                    events?.success(journeyState.convertToMap())
                }
            }

            override fun onCancel(arguments: Any?) {
                NamiCustomerManager.registerCustomerJourneyChangedListener(null)
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
                val namiLanguageCode = call.argument<String>("namiLanguageCode").let { code ->
                    NamiLanguageCode.values().find { it.code == code }.let { namiLanguageCode ->
                        if (namiLanguageCode == null) {
                            Log.d(
                                "NAMI",
                                "Nami language code set in NamiConfiguration " +
                                    "\"$namiLanguageCode\" not found in list of available Nami " +
                                    "Language Codes:\n"
                            )
                        }
                        namiLanguageCode
                    }
                }
                configure(
                    context,
                    call.argument<String>("appPlatformIDGoogle"),
                    call.argument<Boolean>("bypassStore"),
                    call.argument<Boolean>("developmentMode"),
                    namiLogLevel,
                    namiLanguageCode,
                    call.argument<List<String>>("extraDataList")
                )
                result.success(true)
            }
            "setExternalIdentifier" -> {
                val externalIdentifier = call.argument<String>("externalIdentifier")
                val type = call.argument<String>("type")
                val namiExternalIdentifierType = if (type == "uuid") {
                    NamiExternalIdentifierType.UUID
                } else {
                    NamiExternalIdentifierType.SHA_256
                }
                Nami.setExternalIdentifier(externalIdentifier ?: "", namiExternalIdentifierType)
            }
            "clearExternalIdentifier" -> {
                Nami.clearExternalIdentifier()
            }
            "getExternalIdentifier" -> {
                result.success(Nami.getExternalIdentifier())
            }
            "preparePaywallForDisplay" -> {
                val callback = { success: Boolean, error: PreparePaywallError? ->
                    with(hashMapOf("success" to success, "error" to error?.getFlutterString())) {
                        result.success(this)
                    }
                }
                val developerPaywallId = call.argument<String>("developerPaywallId")
                val backgroundImageRequired = call.argument<Boolean>("backgroundImageRequired")
                    ?: false
                val imageFetchTimeout = call.argument<Long>("imageFetchTimeout")
                if (developerPaywallId != null) {
                    NamiPaywallManager.preparePaywallForDisplay(
                        developerPaywallId,
                        backgroundImageRequired,
                        imageFetchTimeout,
                        callback
                    )
                } else {
                    NamiPaywallManager.preparePaywallForDisplay(
                        backgroundImageRequired,
                        imageFetchTimeout,
                        callback
                    )
                }
            }
            "raisePaywall" -> {
                currentActivityWeakReference?.get()?.let { activity ->
                    NamiPaywallManager.raisePaywall(activity)
                }
            }
            "processSmartText" -> {
                val text = call.argument<String>("text")
                val dataStores = call.argument<List<NamiSKU>>("dataStores")
                result.success(
                    NamiPaywallManager.processSmartText(
                        text,
                        dataStores as List<NamiSKU>
                    )
                )
            }
            "currentCustomerJourneyState" -> {
                val stateMap = NamiCustomerManager.currentCustomerJourneyState()?.convertToMap()
                result.success(stateMap)
            }
            "clearAllEntitlements" -> {
                NamiEntitlementManager.clearAllEntitlements()
            }
            "isEntitlementActive" -> {
                result.success(NamiEntitlementManager.isEntitlementActive(call.arguments as String))
            }
            "activeEntitlements" -> {
                result.success(
                    NamiEntitlementManager.activeEntitlements().map { it.convertToMap() })
            }
            "getEntitlements" -> {
                result.success(NamiEntitlementManager.getEntitlements().map { it.convertToMap() })
            }
            "setEntitlements" -> {
                val argument = call.arguments as List<*>
                val entitlementSetters = mutableListOf<NamiEntitlementSetter>()
                argument.forEach { item ->
                    @Suppress("UNCHECKED_CAST")
                    val itemMap = item as Map<String, Any>
                    val expireTime: Long? = itemMap["expires"] as? Long
                    val platformType = when (itemMap["platform"]) {
                        "android" -> NamiPlatformType.ANDROID
                        "apple" -> NamiPlatformType.APPLE
                        "web" -> NamiPlatformType.WEB
                        "roku" -> NamiPlatformType.ROKU
                        else -> NamiPlatformType.OTHER
                    }
                    entitlementSetters.add(
                        NamiEntitlementSetter(
                            referenceId = itemMap["referenceId"] as? String ?: "",
                            expires = expireTime?.let { Date(it) },
                            platform = platformType,
                            purchasedSKUid = itemMap["purchasedSKUid"] as? String
                        )
                    )
                }
                NamiEntitlementManager.setEntitlements(entitlementSetters)
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
            "blockPaywallAutoRaise" -> {
                val allowAutoRaisingPaywall = !(call.arguments as? Boolean ?: false)
                NamiPaywallManager.registerApplicationAutoRaisePaywallBlocker { allowAutoRaisingPaywall }
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
        developmentMode: Boolean?,
        namiLogLevel: NamiLogLevel,
        namiLanguageCode: NamiLanguageCode?,
        extraDataList: List<String>?
    ) {
        if (platformId == null) {
            return
        }
        val configuration = NamiConfiguration.build(context, platformId) {
            this.logLevel = namiLogLevel
            this.bypassStore = bypass ?: false
            this.developmentMode = developmentMode ?: false
            this.settingsList = extraDataList
            this.namiLanguageCode = namiLanguageCode
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
    return hashMapOf("name" to name,
        "description" to desc,
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
        "fromNami" to fromNami,
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
        "description" to this.skuDetails.description,
        "title" to this.skuDetails.title,
        "type" to this.type.getFlutterString(),
        "price" to this.skuDetails.getFormattedPrice().toString(),
        "skuId" to this.skuId,
        "featured" to this.featured,
        "displayText" to this.displayText,
        "displaySubText" to this.displaySubText,
        "localizedPrice" to this.skuDetails.price,
        "numberOfUnits" to 1,
        "priceCurrency" to this.skuDetails.priceCurrencyCode,
        "periodUnit" to (this.skuDetails.getSubscriptionPeriodEnum()?.getFlutterString())
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
        PreparePaywallError.SDK_NOT_INITIALIZED -> "sdk_not_initialized"
        PreparePaywallError.DEVELOPER_PAYWALL_ID_NOT_FOUND -> "developer_paywall_id_not_found"
        PreparePaywallError.IMAGE_LOAD_FAILED -> "image_load_failed"
        PreparePaywallError.NO_LIVE_CAMPAIGN -> "no_live_campaign"
        PreparePaywallError.PAYWALL_ALREADY_DISPLAYED -> "paywall_already_displayed"
        PreparePaywallError.DATA_NOT_AVAILABLE -> "data_not_available"
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
