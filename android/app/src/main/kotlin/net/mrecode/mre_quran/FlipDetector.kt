package net.mrecode.mre_quran

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.SystemClock

/**
 * Calls [onFlip] when the phone is turned face down, like putting a ringing
 * phone screen-down on the table.
 *
 * It only counts a turn *to* face down: a phone that is already face down when
 * the adhan starts keeps playing until it has been picked up and turned over
 * again, so the adhan is not silenced by where the phone happened to lie.
 */
internal class FlipDetector(
    context: Context,
    private val onFlip: () -> Unit,
) : SensorEventListener {
    private val manager = context.getSystemService(SensorManager::class.java)
    private var armed = false
    private var downSince = 0L

    /** Starts listening. Does nothing when the phone has no accelerometer. */
    fun start() {
        val sensor = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
        manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    fun stop() = manager.unregisterListener(this)

    override fun onSensorChanged(event: SensorEvent) {
        // z is the pull of gravity through the screen: about +9.8 face up and
        // about -9.8 face down.
        val z = event.values[2]
        val now = SystemClock.elapsedRealtime()
        when {
            z > FACE_UP -> {
                armed = true
                downSince = 0
            }
            armed && z < FACE_DOWN -> {
                if (downSince == 0L) downSince = now
                // Held down for a moment, not a wobble on the way past.
                else if (now - downSince >= HOLD_MILLIS) {
                    stop()
                    onFlip()
                }
            }
            else -> downSince = 0
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private companion object {
        const val FACE_UP = 3f
        const val FACE_DOWN = -7f
        const val HOLD_MILLIS = 400L
    }
}
