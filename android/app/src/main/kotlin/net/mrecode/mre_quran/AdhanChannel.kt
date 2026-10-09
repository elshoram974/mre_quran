package net.mrecode.mre_quran

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/** The adhan as the app's Dart code sees it: scheduling, a test, and previews. */
internal class AdhanChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val context: Context = activity
    private val channel = MethodChannel(messenger, NAME)
    private val main = Handler(Looper.getMainLooper())
    private var pendingPick: MethodChannel.Result? = null
    private var pendingPayload: String? = null
    private var dartListening = false
    private val preview = AdhanPreview(context) {
        main.post { channel.invokeMethod("previewEnded", null) }
    }

    init {
        channel.setMethodCallHandler { call, result ->
            @Suppress("UNCHECKED_CAST")
            val arguments = call.arguments as? Map<String, Any?>
            when (call.method) {
                "isSupported" -> result.success(true)
                "takeLaunchPayload" -> {
                    dartListening = true
                    result.success(pendingPayload)
                    pendingPayload = null
                }
                "schedule" -> {
                    AdhanScheduler.schedule(
                        context,
                        JSONArray(arguments!!["alarms"] as List<*>),
                        JSONObject(arguments["config"] as Map<*, *>),
                    )
                    result.success(null)
                }
                "cancelAll" -> {
                    AdhanScheduler.cancelAll(context)
                    result.success(null)
                }
                "test" -> {
                    val alarm = JSONObject(arguments!!["alarm"] as Map<*, *>)
                    val config = JSONObject(arguments["config"] as Map<*, *>)
                    // Through the alarm clock when allowed, else straight away.
                    if (!AdhanScheduler.test(context, alarm, config)) AdhanService.start(context, alarm, config)
                    result.success(null)
                }
                "pickAudioFile" -> {
                    if (pendingPick != null) {
                        result.error("busy", "A file is already being picked", null)
                    } else {
                        pendingPick = result
                        activity.startActivityForResult(
                            Intent(Intent.ACTION_OPEN_DOCUMENT)
                                .addCategory(Intent.CATEGORY_OPENABLE)
                                .setType("audio/*"),
                            PICK_REQUEST,
                        )
                    }
                }
                "preview" -> {
                    preview.start(JSONObject(arguments!!))
                    result.success(null)
                }
                "stopPreview" -> {
                    preview.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Takes the answer of the file picker. Returns whether it was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_REQUEST) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        // Copying a recording can take a moment: off the main thread.
        Thread {
            val answer = copyPicked(uri)
            main.post { result.success(answer) }
        }.start()
        return true
    }

    /**
     * Copies the picked file into the app's own folder, so it keeps working if
     * the original moves. Answers with its path and name, an error, or null.
     */
    private fun copyPicked(uri: Uri): Map<String, Any?>? {
        return try {
            var name = "adhan"
            context.contentResolver.query(uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                if (it.moveToFirst()) name = it.getString(0) ?: name
            }
            val extension = name.substringAfterLast('.', "audio").take(5).filter { it.isLetterOrDigit() }.ifEmpty { "audio" }
            val folder = File(context.filesDir, "adhan").apply { mkdirs() }
            folder.listFiles { file -> file.name.startsWith("custom.") }?.forEach { it.delete() }
            val target = File(folder, "custom.$extension")
            var total = 0L
            context.contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        total += read
                        if (total > MAX_CUSTOM_BYTES) {
                            target.delete()
                            return mapOf("error" to "too_large")
                        }
                        output.write(buffer, 0, read)
                    }
                }
            } ?: return null
            mapOf("path" to target.absolutePath, "name" to name)
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Passes on that the notice was tapped, so Dart can open what it points at:
     * at once if Dart is listening, else when it asks at start-up.
     */
    fun deliver(payload: String) {
        if (dartListening) channel.invokeMethod("tapped", payload) else pendingPayload = payload
    }

    fun dispose() {
        preview.stop()
        channel.setMethodCallHandler(null)
    }

    private companion object {
        const val NAME = "net.mrecode.mre_quran/adhan"
        const val PICK_REQUEST = 7311
        // The same figure as customVoiceMaxBytes in Dart.
        const val MAX_CUSTOM_BYTES = 25L * 1000 * 1000
    }
}
