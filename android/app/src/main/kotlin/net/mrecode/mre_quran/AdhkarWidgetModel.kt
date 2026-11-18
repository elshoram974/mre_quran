package net.mrecode.mre_quran

import org.json.JSONObject

/** The suggested adhkar collection sent by Flutter to the native widget. */
internal data class AdhkarWidgetModel(
    val label: String,
    val title: String,
    val done: Int,
    val total: Int,
    val payload: String,
    val rtl: Boolean,
    val progressLabel: String?,
    val useArabicDigits: Boolean,
    val tasbihLabel: String?,
    val tasbihResetLabel: String?,
    val tasbihCountLabel: String?,
) {
    companion object {
        fun parse(json: String?): AdhkarWidgetModel? {
            if (json.isNullOrEmpty()) return null
            return try {
                val root = JSONObject(json)
                AdhkarWidgetModel(
                    label = root.getString("label"),
                    title = root.getString("title"),
                    done = root.getInt("done"),
                    total = root.getInt("total"),
                    payload = root.getString("payload"),
                    rtl = root.optBoolean("rtl", true),
                    progressLabel = root.optString("progressLabel").takeIf { it.isNotEmpty() },
                    useArabicDigits = root.optBoolean("useArabicDigits", true),
                    tasbihLabel = root.optString("tasbihLabel").takeIf { it.isNotEmpty() },
                    tasbihResetLabel = root.optString("tasbihResetLabel").takeIf { it.isNotEmpty() },
                    tasbihCountLabel = root.optString("tasbihCountLabel").takeIf { it.isNotEmpty() },
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}
