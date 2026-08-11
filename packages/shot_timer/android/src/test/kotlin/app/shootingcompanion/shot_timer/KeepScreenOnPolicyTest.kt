package app.shootingcompanion.shot_timer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeepScreenOnPolicyTest {
    @Test
    fun onlyKeepsScreenOnDuringDelayAndActiveRun() {
        assertTrue(
            KeepScreenOnPolicy.keepScreenOnFor(stateEvent("startDelay")) == true,
        )
        assertTrue(
            KeepScreenOnPolicy.keepScreenOnFor(stateEvent("running")) == true,
        )
        assertFalse(
            KeepScreenOnPolicy.keepScreenOnFor(stateEvent("reviewing")) ?: true,
        )
        assertFalse(
            KeepScreenOnPolicy.keepScreenOnFor(stateEvent("interrupted")) ?: true,
        )
    }

    @Test
    fun clearsForErrorsAndIgnoresNonLifecycleEvents() {
        assertEquals(
            false,
            KeepScreenOnPolicy.keepScreenOnFor(mapOf("type" to "error")),
        )
        assertNull(
            KeepScreenOnPolicy.keepScreenOnFor(mapOf("type" to "audioLevel")),
        )
        assertNull(
            KeepScreenOnPolicy.keepScreenOnFor(mapOf("type" to "shot")),
        )
    }

    private fun stateEvent(state: String): Map<String, Any?> =
        mapOf("type" to "state", "state" to state)
}
