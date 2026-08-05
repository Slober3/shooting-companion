package app.shootingcompanion.shot_timer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Test

class AcousticShotTimerEngineTest {
    @Test
    fun `audio read policy treats a negative result as terminal`() {
        assertEquals(AudioReadAction.process, classifyAudioRead(1))
        assertEquals(AudioReadAction.retry, classifyAudioRead(0))
        assertEquals(AudioReadAction.fail, classifyAudioRead(-1))
        assertEquals(AudioReadAction.fail, classifyAudioRead(Int.MIN_VALUE))
    }

    @Test
    fun `startup failure runs cleanup and preserves the original error`() {
        var cleanupCalls = 0
        val original = IllegalStateException("startRecording failed")

        val thrown =
            assertThrows(IllegalStateException::class.java) {
                runAudioStartupWithCleanup(
                    cleanup = { cleanupCalls += 1 },
                ) {
                    throw original
                }
            }

        assertSame(original, thrown)
        assertEquals(1, cleanupCalls)
    }

    @Test
    fun `cleanup failure never masks the startup failure`() {
        val original = IllegalStateException("startRecording failed")

        val thrown =
            assertThrows(IllegalStateException::class.java) {
                runAudioStartupWithCleanup(
                    cleanup = { error("cleanup failed") },
                ) {
                    throw original
                }
            }

        assertSame(original, thrown)
    }
}
