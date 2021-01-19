package com.namiml.flutter.sdk

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import com.namiml.Nami
import com.namiml.NamiConfiguration
import com.namiml.NamiExternalIdentifierType
import com.namiml.NamiLogLevel
import com.namiml.paywall.NamiPaywall
import com.namiml.paywall.NamiPaywallManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.lang.ref.WeakReference
import java.util.logging.StreamHandler


private const val LOG_TAG = "NAMI"

/** FlutterNamiSdkPlugin */
class FlutterNamiSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var signInListener: EventChannel
    private lateinit var context: Context
    private var currentActivityWeakReference: WeakReference<Activity>? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nami")
        signInListener = EventChannel(flutterPluginBinding.binaryMessenger, "signInEvent")

        channel.setMethodCallHandler(this)
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
        context = flutterPluginBinding.applicationContext
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
