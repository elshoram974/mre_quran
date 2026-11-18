package net.mrecode.mre_quran

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val widgetChannel = "net.mrecode.mre_quran/prayer_widget"
    private val adhkarWidgetChannel = "net.mrecode.mre_quran/adhkar_widget"
    private val startupChannel = "net.mrecode.mre_quran/startup"
    private val homeWidgetsChannel = "net.mrecode.mre_quran/home_widgets"
    private var adhan: AdhanChannel? = null

    /** Whether the app's first screen is ready, so the launch screen can go. */
    @Volatile private var ready = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
        // The app says when its first screen is ready (the Quran text read and
        // the Mushaf page drawn); the launch screen stays until then.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, startupChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "ready") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                ready = true
                result.success(null)
            }
        adhan = AdhanChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        deliverAdhanTap(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        adhan?.dispose()
        adhan = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // The launch screen and its turning star stay while the app loads
        // behind them, never longer than LONGEST_SPLASH_MS.
        installSplashScreen().setKeepOnScreenCondition { !ready }
        Handler(Looper.getMainLooper()).postDelayed({ ready = true }, LONGEST_SPLASH_MS)
        super.onCreate(savedInstanceState)
        PrayerWidgetRenderer.updateAll(this)
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

    private companion object {
        /** Longest the launch screen stays, whatever is still loading. */
        const val LONGEST_SPLASH_MS = 4000L
    }
}
