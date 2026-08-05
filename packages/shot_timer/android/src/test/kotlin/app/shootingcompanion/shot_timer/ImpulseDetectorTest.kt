package app.shootingcompanion.shot_timer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ImpulseDetectorTest {
    private val sampleRate = 48_000

    @Test
    fun detectsIsolatedImpulse() {
        val detector = ImpulseDetector(ImpulseDetectorConfiguration())
        val samples = ShortArray(480) { 80 }
        samples[200] = 24_000

        val detections = detector.process(samples, samples.size, 1_000_000_000, sampleRate)

        assertEquals(1, detections.size)
        assertTrue(detections.single().normalizedPeak > 0.7)
        assertEquals(1_004_166_666, detections.single().timestampNanos)
    }

    @Test
    fun ignoresSteadyBackgroundNoise() {
        val detector = ImpulseDetector(ImpulseDetectorConfiguration())
        val samples = ShortArray(960) { index -> if (index % 2 == 0) 500 else -500 }

        val detections = detector.process(samples, samples.size, 0, sampleRate)

        assertTrue(detections.isEmpty())
    }

    @Test
    fun suppressesEchoInsideLockout() {
        val detector =
            ImpulseDetector(
                ImpulseDetectorConfiguration(echoLockoutNanos = 100_000_000),
            )
        val first = ShortArray(480).also { it[100] = 20_000 }
        val echo = ShortArray(480).also { it[100] = 18_000 }
        val later = ShortArray(480).also { it[100] = 18_000 }

        assertEquals(1, detector.process(first, first.size, 0, sampleRate).size)
        assertTrue(detector.process(echo, echo.size, 50_000_000, sampleRate).isEmpty())
        assertEquals(1, detector.process(later, later.size, 150_000_000, sampleRate).size)
    }

    @Test
    fun beepBlankingPreventsStartSignalDetection() {
        val detector = ImpulseDetector(ImpulseDetectorConfiguration())
        detector.setBlankUntil(200_000_000)
        val beep = ShortArray(480).also { it[50] = 30_000 }
        val shot = ShortArray(480).also { it[50] = 30_000 }

        assertTrue(detector.process(beep, beep.size, 100_000_000, sampleRate).isEmpty())
        assertEquals(1, detector.process(shot, shot.size, 300_000_000, sampleRate).size)
    }
}
