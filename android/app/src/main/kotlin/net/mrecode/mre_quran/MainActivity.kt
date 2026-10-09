package net.mrecode.mre_quran

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val widgetChannel = "net.mrecode.mre_quran/prayer_widget"
    private val adhkarWidgetChannel = "net.mrecode.mre_quran/adhkar_widget"
    private var adhan: AdhanChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "update") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                @Suppress("UNCHECKED_CAST")
                PrayerWidgetRenderer.save(this, call.arguments as? Map<String, Any?>)
                result.success(null)
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
        adhan = AdhanChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        deliverAdhanTap(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        adhan?.dispose()
        adhan = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
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
}
