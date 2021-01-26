package com.namiml.flutter.sdk

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import com.namiml.Nami
import com.namiml.NamiConfiguration
import com.namiml.NamiExternalIdentifierType
import com.namiml.NamiLogLevel
import com.namiml.analytics.NamiAnalyticsActionType
import com.namiml.analytics.NamiAnalyticsKeys
import com.namiml.analytics.NamiAnalyticsPurchaseActivityType
import com.namiml.analytics.NamiAnalyticsSupport
import com.namiml.billing.NamiPurchase
import com.namiml.customer.NamiCustomerManager
import com.namiml.entitlement.NamiEntitlement
import com.namiml.entitlement.NamiEntitlementManager
import com.namiml.entitlement.NamiEntitlementSetter
import com.namiml.entitlement.NamiPlatformType
import com.namiml.paywall.*
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
import java.util.*
import java.util.logging.StreamHandler
import kotlin.collections.HashMap


private const val LOG_TAG = "NAMI"

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
    private lateinit var context: Context
    private lateinit var moshi: Moshi
    private var currentActivityWeakReference: WeakReference<Activity>? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        moshi = Moshi.Builder().build()
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nami")
        signInListener = EventChannel(flutterPluginBinding.binaryMessenger, "signInEvent")
        analyticsListener = EventChannel(flutterPluginBinding.binaryMessenger, "analyticsEvent")
        entitlementChangeListener = EventChannel(flutterPluginBinding.binaryMessenger, "entitlementChangeEvent")

        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        setSignInStreamHandler()
        setAnalyticsStreamHandler()
        setEntitlementStreamHandler()
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
                    finalMap[NamiAnalyticsKeys.PURCHASE_ACTIVITY_TYPE] = activityType.getFlutterString()
                    events?.success(finalMap)
                }
            }

            override fun onCancel(arguments: Any?) {
                //TODO Add support for nullifying listener on Android SDK side
                //NamiAnalyticsSupport.registerAnalyticsListener(null)
            }

        })
    }

    private fun setEntitlementStreamHandler() {
        entitlementChangeListener.setStreamHandler(object : StreamHandler(), EventChannel.StreamHandler {
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

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "configure" -> {
                configure(context,
                        call.argument<String>("appPlatformIDGoogle"),
                        call.argument<Boolean>("bypassStore"),
                        call.argument<Boolean>("developmentMode"),
                        call.argument<Int>("namiLogLevel"),
                        call.argument<List<String>>("extraDataList"))
                result.success(true)
            }
            "setExternalIdentifier" -> {
                val externalIdentifier = call.argument<String>("externalIdentifier")
                val type = call.argument<Int>("type")
                val namiExternalIdentifierType = type?.let {
                    NamiExternalIdentifierType.values()[it]
                }
                io.flutter.Log.d(LOG_TAG, "externalIdentifier $externalIdentifier")
                io.flutter.Log.d(LOG_TAG, "type $type")
                namiExternalIdentifierType?.let {
                    Nami.setExternalIdentifier(
                            externalIdentifier = externalIdentifier ?: "",
                            type = namiExternalIdentifierType
                    )
                }
            }
            "clearExternalIdentifier" -> {
                Nami.clearExternalIdentifier()
            }
            "getExternalIdentifier" -> {
                result.success(Nami.getExternalIdentifier())
            }
            "canRaisePaywall" -> {
                result.success(NamiPaywallManager.canRaisePaywall())
            }
            "raisePaywall" -> {
                currentActivityWeakReference?.get()?.let { activity ->
                    NamiPaywallManager.raisePaywall(activity)
                }
            }
            "currentCustomerJourneyState" -> {
                val stateMap = NamiCustomerManager.currentCustomerJourneyState()?.let {
                    mapOf("former_subscriber" to it.formerSubscriber,
                            "in_grace_period" to it.inGracePeriod,
                            "in_trial_period" to it.inTrialPeriod,
                            "in_intro_offer_period" to it.inIntroOfferPeriod)
                }
                result.success(stateMap)
            }
            "clearAllEntitlements" -> {
                NamiEntitlementManager.clearAllEntitlements()
            }
            "isEntitlementActive" -> {
                result.success(NamiEntitlementManager.isEntitlementActive(call.arguments as String))
            }
            "activeEntitlements" -> {
                result.success(NamiEntitlementManager.activeEntitlements().map { it.convertToMap() })
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
                    entitlementSetters.add(NamiEntitlementSetter(
                            referenceId = itemMap["referenceId"] as? String ?: "",
                            expires = expireTime?.let { Date(it) },
                            platform = platformType,
                            purchasedSKUid = itemMap["purchasedSKUid"] as? String))
                }
                NamiEntitlementManager.setEntitlements(entitlementSetters)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun configure(context: Context,
                          platformId: String?,
                          bypass: Boolean?,
                          developmentMode: Boolean?,
                          namiLogLevel: Int?,
                          extraDataList: List<String>?) {
        if (platformId == null) {
            return
        }
        io.flutter.Log.d(LOG_TAG, "appPlatformIDGoogle $platformId")
        io.flutter.Log.d(LOG_TAG, "bypassMode $bypass")
        io.flutter.Log.d(LOG_TAG, "developmentMode $developmentMode")
        io.flutter.Log.d(LOG_TAG, "namiLogLevel $namiLogLevel")
        io.flutter.Log.d(LOG_TAG, "extraDataList $extraDataList")
        val configuration = NamiConfiguration.build(context, platformId) {
            this.logLevel = NamiLogLevel.values()[namiLogLevel ?: NamiLogLevel.WARN.ordinal]
            this.bypassStore = bypass ?: false
            this.developmentMode = developmentMode ?: false
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

private fun NamiEntitlement.convertToMap(): HashMap<String, Any?> {
    return hashMapOf("name" to name,
            "description" to desc,
            "namiId" to namiId,
            "referenceId" to referenceId,
            "relatedSKUs" to relatedSKUs.map { it.convertToMap() },
            "purchasedSKUs" to purchasedSKUs.map { it.convertToMap() },
            "activePurchases" to activePurchases.map { it.convertToMap() })
}

private fun NamiPurchase.convertToMap(): HashMap<String, Any?> {
    return hashMapOf("purchaseInitiatedTimestamp" to purchaseInitiatedTimestamp,
            "expires" to (expires?.time ?: 0L),
            "purchaseSource" to purchaseSource.getFlutterString(),
            "fromNami" to fromNami,
            "skuId" to skuId,
            "transactionIdentifier" to transactionIdentifier,
            "localizedDescription" to localizedDescription)
}

private fun NamiPurchaseSource.getFlutterString(): String {
    return when (this) {
        NamiPurchaseSource.APPLICATION -> "application"
        NamiPurchaseSource.NAMI_PAYWALL -> "nami_paywall"
        NamiPurchaseSource.EXTERNAL -> "external"
        NamiPurchaseSource.UNKNOWN -> "unknown"
        else -> ""
    }
}

private fun NamiAnalyticsPurchaseActivityType?.getFlutterString(): String {
    return when (this) {
        NamiAnalyticsPurchaseActivityType.NEW_PURCHASE -> "new_purchase"
        NamiAnalyticsPurchaseActivityType.RESTORE -> "restore"
        NamiAnalyticsPurchaseActivityType.RESUBSCRIBE -> "resubscribe"
        else -> ""
    }
}

private fun NamiSKU.convertToMap(): HashMap<String, Any?> {
    return hashMapOf("description" to this.skuDetails.description,
            "title" to this.skuDetails.title,
            "type" to this.type.getFlutterString(),
            "localizedMultipliedPrice" to "",
            "price" to this.skuDetails.getFormattedPrice().toString(),
            "subscriptionGroupIdentifier" to "",
            "skuId" to this.skuId,
            "localizedPrice" to this.skuDetails.price,
            "numberOfUnits" to 1,
            "priceLanguage" to "",
            "priceCurrency" to this.skuDetails.priceCurrencyCode,
            "priceCountry" to "",
            "periodUnit" to (this.skuDetails.getSubscriptionPeriodEnum()?.getFlutterString() ?: "")
    )
}

private fun NamiSKUType.getFlutterString(): String {
    return when (this) {
        NamiSKUType.ONE_TIME_PURCHASE -> "one_time_purchase"
        NamiSKUType.UNKNOWN -> "unknown"
        NamiSKUType.SUBSCRIPTION -> "subscription"
    }
}

private fun SubscriptionPeriod.getFlutterString(): String {
    return when (this) {
        SubscriptionPeriod.DAY -> "day"
        SubscriptionPeriod.WEEKLY -> "week"
        SubscriptionPeriod.MONTHLY -> "month"
        SubscriptionPeriod.ANNUAL -> "year"
        SubscriptionPeriod.QUARTERLY -> "quarter"
        SubscriptionPeriod.HALF_YEAR -> "half_year"
    }
}

private fun NamiPaywall.convertToMap(): HashMap<String, Any?> {
    return hashMapOf("name" to this.name,
            "allowClosing" to this.allowClosing,
            "backgroundImageUrlPhone" to this.backgroundImageUrlPhone,
            "backgroundImageUrlTablet" to this.backgroundImageUrlTablet,
            "body" to this.body,
            "developerPaywallId" to this.developerPaywallId,
            "privacyPolicy" to this.privacyPolicy,
            "purchaseTerms" to this.purchaseTerms,
            "restoreControl" to this.restoreControl,
            "signInControl" to this.signInControl,
            "title" to this.title,
            "tosLink" to this.tosLink,
            "type" to this.type)
}

private fun NamiAnalyticsActionType.getFlutterString(): String {
    return when (this) {
        NamiAnalyticsActionType.PAYWALL_RAISE -> "paywall_raise"
        NamiAnalyticsActionType.PAYWALL_RAISE_BLOCKED -> "paywall_raise_blocked"
        NamiAnalyticsActionType.PURCHASE_ACTIVITY -> "purchase_activity"
    }
}
