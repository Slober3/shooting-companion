package app.shootingcompanion.shot_timer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class NativeTimerConfigurationTest {
    @Test
    fun `configuration parses selected native output signals`() {
        val configuration =
            NativeTimerConfiguration.fromMap(
                mapOf(
                    "mode" to "acousticLiveFire",
                    "outputSignals" to listOf("sound", "haptic", "flash"),
                ),
            )

        assertEquals(setOf("sound", "haptic", "flash"), configuration.outputSignals)
    }

    @Test
    fun `configuration keeps sound as backwards compatible default`() {
        val configuration =
            NativeTimerConfiguration.fromMap(
                mapOf("mode" to "acousticLiveFire"),
            )

        assertEquals(setOf("sound"), configuration.outputSignals)
    }

    @Test
    fun `configuration rejects unknown output signals`() {
        assertThrows(IllegalArgumentException::class.java) {
            NativeTimerConfiguration.fromMap(
                mapOf(
                    "mode" to "acousticLiveFire",
                    "outputSignals" to listOf("sound", "unknown"),
                ),
            )
        }
    }
}
