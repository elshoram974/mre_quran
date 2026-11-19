package net.mrecode.mre_quran

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.annotation.Keep

/**
 * Notes each step of a launch, from the activity's creation to Flutter's
 * first frame on screen, so a launch that stays on the launch screen can be
 * told about afterwards: where it was started from and the last step it
 * reached. Each step is written to logcat (tag MushafiStartup) and kept on
 * the device until the launch shows its first frame. The next launch hands
 * an unfinished one to Dart, which reports it. Nothing personal is kept:
 * step names, milliseconds, the intent's action and extra names, and the
 * Android version. Dart calls [mark] and [takeStalled] directly through JNI
 * (lib/features/startup/data/startup_trace.dart), so they are static and
 * kept from shrinking.
 */
@Keep
object StartupTrace {
    private const val TAG = "MushafiStartup"
    private const val PREFS = "startup_trace"
    private const val CURRENT = "current"
    private const val STALLED = "stalled"

    /** A launch left by the person before this is not counted as stalled. */
    private const val LEFT_QUICKLY_MS = 3000L

    private var begunAt = 0L
    private var open = false

    /** Starts the trace of a launch, keeping the last one if it stalled. */
    fun begin(context: Context, intent: Intent?, restored: Boolean) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val previous = prefs.getString(CURRENT, null)
        val editor = prefs.edit()
        if (previous != null && stalled(previous)) {
            editor.putString(STALLED, previous)
            Log.w(TAG, "previous launch never showed its first frame: $previous")
        }
        begunAt = SystemClock.elapsedRealtime()
        open = true
        val line = "android ${Build.VERSION.SDK_INT} from ${source(intent, restored)}:"
        editor.putString(CURRENT, line).apply()
        Log.i(TAG, line)
    }

    /** Notes [step] of the launch under way; nothing once it is on screen. */
    @JvmStatic
    fun mark(context: Context, step: String) {
        if (!open) return
        val at = SystemClock.elapsedRealtime() - begunAt
        if (step == DISPLAYED || step == DART_FIRST_FRAME) open = false
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val line = "${prefs.getString(CURRENT, "")} $step@$at"
        prefs.edit().putString(CURRENT, line).apply()
        Log.i(TAG, "$step at ${at}ms")
    }

    /** The trace of a launch that stalled, once; null when none did. */
    @JvmStatic
    fun takeStalled(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val stalled = prefs.getString(STALLED, null) ?: return null
        prefs.edit().remove(STALLED).apply()
        return stalled
    }

    /**
     * Whether [trace] never reached the screen, and was not simply left by
     * the person within a moment of tapping.
     */
    private fun stalled(trace: String): Boolean {
        if (trace.contains(" $DISPLAYED@") || trace.contains(" $DART_FIRST_FRAME@")) return false
        val left = Regex(" pause@(\\d+)").find(trace)?.groupValues?.get(1)?.toLongOrNull()
        return left == null || left >= LEFT_QUICKLY_MS
    }

    /** Where the launch came from: the icon, a restore, or an intent's names. */
    private fun source(intent: Intent?, restored: Boolean): String {
        val action = intent?.action?.substringAfterLast('.') ?: "none"
        val icon = intent?.categories?.contains(Intent.CATEGORY_LAUNCHER) == true
        // Reading another app's extras can throw; the names are only a hint.
        val extras = runCatching {
            intent?.extras?.keySet()?.sorted()?.joinToString(",")
        }.getOrNull().orEmpty()
        return buildString {
            append(if (icon) "icon" else action)
            if (extras.isNotEmpty()) append("[$extras]")
            if (restored) append(" restored")
        }
    }

    const val DISPLAYED = "displayed"
    private const val DART_FIRST_FRAME = "dart:firstFrame"
}
