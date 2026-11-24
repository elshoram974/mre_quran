package net.mrecode.mre_quran

import android.content.Intent
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val widgetChannel = "net.mrecode.mre_quran/prayer_widget"
    private val adhkarWidgetChannel = "net.mrecode.mre_quran/adhkar_widget"
    private val homeWidgetsChannel = "net.mrecode.mre_quran/home_widgets"
    private val prayerSoonChannel = "net.mrecode.mre_quran/prayer_soon"
    private var adhan: AdhanChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "net.mrecode.mre_quran/widget_haptics")
            .setMethodCallHandler { call, result ->
                if (call.method == "setEnabled" && call.arguments is Boolean) {
                    TasbihWidgetProvider.setHapticsEnabled(this, call.arguments as Boolean)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        @Suppress("UNCHECKED_CAST")
                        PrayerWidgetRenderer.save(this, call.arguments as? Map<String, Any?>)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, homeWidgetsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canPin" -> result.success(HomeWidgets.canPin(this))
                    "pin" -> result.success(HomeWidgets.pin(this, call.arguments as? String))
                    "appearance" -> result.success(HomeWidgets.appearance(this))
                    "setAppearance" -> result.success(HomeWidgets.setAppearance(this, call.arguments as? String))
                    "prayerScheduleOptions" -> result.success(HomeWidgets.prayerScheduleOptions(this))
                    "setPrayerScheduleOptions" -> result.success(HomeWidgets.setPrayerScheduleOptions(this, call.arguments as? Map<*, *>))
                    "placed" -> result.success(HomeWidgets.placed(this))
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, adhkarWidgetChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "update") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                @Suppress("UNCHECKED_CAST")
                AdhkarWidgetRenderer.save(this, call.arguments as? Map<String, Any?>)
                result.success(null)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, prayerSoonChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val arguments = call.arguments as Map<*, *>
                        PrayerSoonScheduler.schedule(
                            this,
                            JSONArray(arguments["alarms"] as List<*>),
                            JSONObject(arguments["config"] as Map<*, *>),
                        )
                        result.success(null)
                    }
                    "cancelAll" -> {
                        PrayerSoonScheduler.cancelAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        StartupTrace.mark(this, "engine")
        adhan = AdhanChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        deliverAdhanTap(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        adhan?.dispose()
        adhan = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        StartupTrace.begin(this, intent, restored = savedInstanceState != null)
        // Let Flutter draw its first frame. Holding Android's pre-draw until
        // Flutter paints can make the two wait for each other indefinitely.
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun onStart() {
        super.onStart()
        StartupTrace.mark(this, "start")
    }

    override fun onResume() {
        super.onResume()
        StartupTrace.mark(this, "resume")
    }

    override fun onPause() {
        StartupTrace.mark(this, "pause")
        super.onPause()
    }

    override fun onStop() {
        StartupTrace.mark(this, "stop")
        super.onStop()
    }

    override fun onDestroy() {
        StartupTrace.mark(this, "destroy")
        super.onDestroy()
    }

    /** The launch screen goes: Flutter's first frame is on screen. */
    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        StartupTrace.mark(this, StartupTrace.DISPLAYED)
    }

    @Deprecated("Flutter's activity still reports results this way")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (adhan?.onActivityResult(requestCode, resultCode, data) != true) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        deliverAdhanTap(intent)
    }

    /** A tap on the adhan's notice carries what it should open. */
    private fun deliverAdhanTap(intent: Intent?) {
        val payload = intent?.getStringExtra(AdhanService.EXTRA_PAYLOAD)
        if (!payload.isNullOrEmpty()) adhan?.deliver(payload)
    }
}
